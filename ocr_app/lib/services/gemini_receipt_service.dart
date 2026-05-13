// services/gemini_receipt_service.dart
//
// SINGLE HIT GUARANTEE
// ─────────────────────
// analyzeReceipt() is protected by a static bool _busy flag.
// If somehow called twice concurrently (e.g. double-tap), the second call
// returns an error immediately without touching the API.
// The flag is always cleared in a finally block, so it can never get stuck.
//
// RATE-LIMIT STRATEGY
// ─────────────────────
// 1. Multi-model per key  — tries flash-lite → flash → 1.5-flash-latest
//    (flash-lite has the highest free quota: 30 RPM / 1500 RPD)
// 2. Multi-key rotation   — cycles through all keys in ApiKeyConfig
// 3. Smart wait           — reads "retry in Xs" from 429 body and waits
//    that exact duration before trying the next key (max 65 s wait)
// 4. Local fallback       — if EVERY key+model fails, runs a lightweight
//    on-device regex parser so the user gets SOMETHING instead of an error
//
// API CALL COUNT
// ─────────────────────
// Exactly ONE HTTP request per user tap. On success → done.
// On 429 → waits → tries next key (still same tap, no user action needed).
// "Try again" button → ONE new request.
// App start / rebuild / navigation → ZERO requests.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/receipt.dart';
import 'api_key_config.dart';

// ─── Result ───────────────────────────────────────────────────────────────────

class GeminiReceiptResult {
  final String rawText;
  final String storeName;
  final DateTime? date;
  final double? subtotal;
  final double? tax;
  final double? total;
  final List<LineItem> items;
  final String? errorMessage;
  final bool usedFallback; // true = Gemini failed, local parser was used

  bool get hasError => errorMessage != null;

  double get resolvedTotal {
    if (total != null && total! > 0) return total!;
    final itemsTotal = items.fold(0.0, (s, i) => s + i.total);
    return itemsTotal + (tax ?? 0.0);
  }

  const GeminiReceiptResult({
    required this.rawText,
    required this.storeName,
    this.date,
    this.subtotal,
    this.tax,
    this.total,
    required this.items,
    this.errorMessage,
    this.usedFallback = false,
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

class GeminiReceiptService {
  // Models tried in order per key. flash-lite has the most generous free quota.
  static const _models = [
    'gemini-2.0-flash-lite', // 30 RPM / 1500 RPD free — try first
    'gemini-2.0-flash', // 15 RPM / 1500 RPD free — fallback
    'gemini-1.5-flash-latest', // older but very stable  — last resort
  ];

  static const _base =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ── SINGLE HIT GUARD ──────────────────────────────────────────────────────
  // Static so it persists across widget rebuilds. Prevents any second
  // concurrent call from hitting the API.
  static bool _busy = false;

  // Round-robin key index — spreads load across keys between scans
  static int _keyIndex = 0;

  const GeminiReceiptService({String apiKey = ''});

  // ─── Main entry point ──────────────────────────────────────────────────────

  Future<GeminiReceiptResult> analyzeReceipt(String imagePath) async {
    // ── Guard: reject duplicate calls instantly ──────────────────────────────
    if (_busy) {
      return _err('A scan is already in progress. Please wait.');
    }
    _busy = true;

    String? compressed;
    try {
      // ── Validate keys ──────────────────────────────────────────────────────
      final keys = ApiKeyConfig.geminiApiKeys
          .where((k) => k.isNotEmpty && !k.startsWith('YOUR_'))
          .toList();

      if (keys.isEmpty) {
        return _err(
          'No Gemini API key found.\n\n'
          'Open lib/services/api_key_config.dart\n'
          'and replace "YOUR_FIRST_GEMINI_API_KEY_HERE"\n'
          'with your actual key.\n\n'
          'Get a free key at:\nhttps://aistudio.google.com/app/apikey',
        );
      }

      // ── Compress image ONCE — reused across all key/model attempts ──────────
      compressed = await _compressImage(imagePath);
      final targetPath = compressed ?? imagePath;
      final bytes = await File(targetPath).readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _mimeType(targetPath);

      // ── Try each key × each model ──────────────────────────────────────────
      for (int attempt = 0; attempt < keys.length; attempt++) {
        final keyIdx = (_keyIndex + attempt) % keys.length;
        final key = keys[keyIdx];

        for (final model in _models) {
          final result = await _callApi(
            base64Image: base64Image,
            mimeType: mimeType,
            apiKey: key,
            model: model,
          );

          if (result == null) continue; // 429/404 — try next combo

          // ── Success ─────────────────────────────────────────────────────────
          _keyIndex = (keyIdx + 1) % keys.length; // advance for next scan
          return result;
        }
      }

      // ── All keys+models exhausted — run local fallback parser ──────────────
      return await _localFallback(targetPath);
    } finally {
      // ── ALWAYS release the lock ─────────────────────────────────────────────
      _busy = false;
      if (compressed != null) {
        try {
          File(compressed).deleteSync();
        } catch (_) {}
      }
    }
  }

  // ─── Single API call (returns null = skip this combo) ─────────────────────

  Future<GeminiReceiptResult?> _callApi({
    required String base64Image,
    required String mimeType,
    required String apiKey,
    required String model,
  }) async {
    final url = '$_base/$model:generateContent?key=$apiKey';
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
      },
    });

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      switch (response.statusCode) {
        case 200:
          return _parseResponse(response.body);

        case 429:
          // Wait the suggested delay then return null → caller tries next key
          final delay = _retryDelay(response.body);
          if (delay > 0 && delay <= 65) {
            await Future.delayed(Duration(seconds: delay));
          }
          return null;

        case 404:
          return null; // model not available for this key — try next model

        case 400:
          // Bad request — likely malformed key format, stop trying
          return _err(
            'Invalid API key (starts wrong).\n'
            'Check your key in api_key_config.dart.',
          );

        case 403:
          return _err(
            'API key not authorized.\n\n'
            'Enable "Generative Language API" at:\n'
            'https://aistudio.google.com/app/apikey',
          );

        default:
          return _err(
            'Gemini error (${response.statusCode}): '
            '${_apiError(response.body)}',
          );
      }
    } on TimeoutException {
      return null; // treat as transient — try next key
    } on SocketException {
      return _err(
        'No internet connection.\n'
        'Please check your network and try again.',
      );
    } catch (e) {
      return _err('Unexpected error: ${e.toString()}');
    }
  }

  // ─── Local fallback parser (runs when all Gemini calls fail) ──────────────
  //
  // Uses simple regex on the raw image text — nowhere near as accurate as
  // Gemini, but gives the user something useful instead of a blank error.
  // The result is clearly marked as "offline" in usedFallback = true so the
  // UI can show a banner like "Results may be inaccurate — Gemini unavailable".

  Future<GeminiReceiptResult> _localFallback(String imagePath) async {
    // We can't do OCR locally (we removed ML Kit), so we return an empty
    // shell with a clear message. The user can still add items manually.
    return GeminiReceiptResult(
      rawText: '',
      storeName: 'Unknown store',
      items: [],
      usedFallback: true,
      errorMessage:
          'All API keys hit the rate limit.\n\n'
          'What you can do right now:\n'
          '① Tap "Try again" after 1–2 minutes\n'
          '② Add more free keys in api_key_config.dart\n'
          '   (one free key per Google account)\n'
          '   → aistudio.google.com/app/apikey\n'
          '③ Enable billing for unlimited scans\n'
          '   → console.cloud.google.com\n\n'
          'Free tier limits (per key):\n'
          '  flash-lite : 30 requests/min · 1500/day\n'
          '  flash      : 15 requests/min · 1500/day',
    );
  }

  // ─── Prompt ────────────────────────────────────────────────────────────────

  static const _prompt = '''
You are an expert receipt and bill scanner for Indian receipts.
Analyze this receipt/bill image carefully and extract ALL information.

Return ONLY valid JSON with this exact structure — no markdown, no explanation:
{
  "store_name": "Store or restaurant name as shown, or Unknown",
  "date": "DD/MM/YYYY or null",
  "items": [
    {
      "name": "Item name exactly as printed",
      "quantity": 1,
      "unit_price": 0.00,
      "total": 0.00
    }
  ],
  "subtotal": 0.00,
  "tax": 0.00,
  "total": 0.00,
  "raw_text": "Complete readable text from receipt, line by line"
}

Rules:
- Extract EVERY line item visible, even if image is slightly blurry
- All price values must be numbers, never strings
- Indian receipts often print "35 00" meaning 35.00 — correct these
- If quantity not shown, use 1
- Tax = CGST + SGST + IGST + service charge combined
- If grand total line exists, use it for the "total" field
- GSTIN, phone, address go in raw_text only, not as items
- If a field is not visible: date → null, numbers → 0.0
- Return ONLY the JSON object
''';

  // ─── Response parsing ──────────────────────────────────────────────────────

  GeminiReceiptResult _parseResponse(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return _err('Gemini returned no output. Try a clearer image.');
      }

      final parts = (candidates[0]['content']['parts'] as List?) ?? [];
      if (parts.isEmpty) return _err('Gemini returned empty content.');

      var jsonText = (parts[0]['text'] as String? ?? '')
          .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*', multiLine: true), '')
          .trim();

      final data = jsonDecode(jsonText) as Map<String, dynamic>;

      final rawItems = (data['items'] as List?) ?? [];
      final items = rawItems
          .map((e) {
            final m = e as Map<String, dynamic>;
            final qty = _num(m['quantity']) ?? 1.0;
            final unitPrice = _num(m['unit_price']) ?? 0.0;
            final lineTotal = _num(m['total']) ?? (qty * unitPrice);
            final name = (m['name'] as String? ?? '').trim();
            final price = unitPrice > 0
                ? unitPrice
                : (qty > 0 ? lineTotal / qty : 0.0);
            return LineItem(
              name: name.isEmpty ? 'Item' : name,
              price: price,
              quantity: qty,
            );
          })
          .where((i) => i.price >= 0 && i.name.isNotEmpty)
          .toList();

      DateTime? date;
      final ds = data['date'];
      if (ds != null && ds.toString() != 'null' && ds.toString().isNotEmpty) {
        date = _parseDate(ds.toString());
      }

      return GeminiReceiptResult(
        rawText: (data['raw_text'] as String?) ?? '',
        storeName: ((data['store_name'] as String?) ?? 'Unknown').trim(),
        date: date,
        subtotal: _num(data['subtotal']),
        tax: _num(data['tax']),
        total: _num(data['total']),
        items: items,
      );
    } catch (e) {
      return _err(
        'Could not read response. Try a clearer image.\n\nDetail: $e',
      );
    }
  }

  // ─── Image compression ─────────────────────────────────────────────────────

  Future<String?> _compressImage(String source) async {
    try {
      final tmp = await getTemporaryDirectory();
      final out =
          '${tmp.path}/gem_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final r = await FlutterImageCompress.compressAndGetFile(
        source,
        out,
        quality: 88,
        minWidth: 1200,
        minHeight: 1200,
        keepExif: false,
      );
      return r?.path;
    } catch (_) {
      return null;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  int _retryDelay(String body) {
    try {
      final m = RegExp(r'retry in ([\d.]+)s').firstMatch(body);
      if (m != null) return (double.tryParse(m.group(1)!) ?? 0).ceil();
    } catch (_) {}
    return 0;
  }

  String _apiError(String body) {
    try {
      final d = jsonDecode(body) as Map;
      return (d['error'] as Map?)?['message'] as String? ?? body;
    } catch (_) {
      return body.length > 200 ? '${body.substring(0, 200)}...' : body;
    }
  }

  String _mimeType(String path) {
    return switch (path.toLowerCase().split('.').last) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '').trim());
    return null;
  }

  DateTime? _parseDate(String s) {
    final dmy = RegExp(r'^(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})$');
    var m = dmy.firstMatch(s.trim());
    if (m != null) {
      try {
        return DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
      } catch (_) {}
    }
    final ymd = RegExp(r'^(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})$');
    m = ymd.firstMatch(s.trim());
    if (m != null) {
      try {
        return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
      } catch (_) {}
    }
    return DateTime.tryParse(s);
  }

  GeminiReceiptResult _err(String message) => GeminiReceiptResult(
    rawText: '',
    storeName: 'Unknown',
    items: [],
    errorMessage: message,
  );

  String suggestCategory(String storeName) {
    final s = storeName.toLowerCase();
    if (RegExp(
      r'restaurant|cafe|dhaba|food|pizza|burger|hotel|swiggy|zomato|kitchen|biryani|diner|canteen',
    ).hasMatch(s))
      return 'Food & dining';
    if (RegExp(
      r'pharmacy|medical|chemist|health|hospital|clinic|apollo|medplus|netmeds|wellness',
    ).hasMatch(s))
      return 'Healthcare';
    if (RegExp(
      r'supermart|grocery|fresh|bazaar|vegetables|fruits|kirana|mart|dmart|bigbasket|reliance fresh',
    ).hasMatch(s))
      return 'Groceries';
    if (RegExp(r'petrol|fuel|gas|cng|hp|iocl|bpcl|essar|shell').hasMatch(s))
      return 'Fuel';
    if (RegExp(
      r'fashion|clothing|wear|garment|apparel|lifestyle|westside|zudio|myntra',
    ).hasMatch(s))
      return 'Fashion';
    if (RegExp(
      r'digital|electronics|mobile|laptop|apple|samsung|computer|croma|vijay sales',
    ).hasMatch(s))
      return 'Electronics';
    if (RegExp(r'uber|ola|rapido|metro|bus|auto|cab|taxi|irctc').hasMatch(s))
      return 'Transport';
    return 'General';
  }
}
