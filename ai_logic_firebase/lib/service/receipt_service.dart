// // receipt_service.dart
// // Handles:
// //   • Camera / gallery image picking
// //   • Saving the image to the app's local documents directory
// //   • Sending the image to Gemini (via Firebase AI Logic)
// //   • Parsing the JSON response into a ReceiptModel
// //   • Persisting the result through HiveService

// import 'dart:convert';
// import 'dart:io';
// import 'package:ai_logic_firebase/model/receipt_model.dart';
// import 'package:firebase_ai/firebase_ai.dart';
// import 'package:flutter/foundation.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import 'package:uuid/uuid.dart';
// import 'hive_service.dart';

// // ---------------------------------------------------------------------------
// // Prompt sent to Gemini
// // ---------------------------------------------------------------------------

// const String _receiptPrompt = '''
// You are an expert OCR and receipt-parsing assistant.

// Analyse the provided receipt image and extract ALL visible information.

// Return ONLY a single valid JSON object — no markdown fences, no explanation,
// no comments, no trailing text. Any field that is not visible or cannot be
// determined must be set to null or an empty string (never omit the key).

// Required JSON structure:
// {
//   "shopName":      "<string>",
//   "billNumber":    "<string>",
//   "date":          "<string>",
//   "time":          "<string>",
//   "gstNumber":     "<string>",
//   "subtotal":      <number>,
//   "gstPercentage": <number>,
//   "gstAmount":     <number>,
//   "grandTotal":    <number>,
//   "items": [
//     {
//       "itemName": "<string>",
//       "quantity": <number>,
//       "price":    <number>,
//       "total":    <number>
//     }
//   ]
// }
// ''';

// // ---------------------------------------------------------------------------
// // ReceiptService
// // ---------------------------------------------------------------------------

// class ReceiptService {
//   static final ImagePicker _picker = ImagePicker();
//   static const _uuid = Uuid();

//   // -------------------------------------------------------------------------
//   // Image selection helpers
//   // -------------------------------------------------------------------------

//   /// Opens the device camera and returns the taken photo, or null on cancel.
//   static Future<File?> pickFromCamera() async {
//     final xFile = await _picker.pickImage(
//       source: ImageSource.camera,
//       imageQuality: 85,
//       preferredCameraDevice: CameraDevice.rear,
//     );
//     return xFile == null ? null : File(xFile.path);
//   }

//   /// Opens the gallery and returns the selected photo, or null on cancel.
//   static Future<File?> pickFromGallery() async {
//     final xFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 85,
//     );
//     return xFile == null ? null : File(xFile.path);
//   }

//   // -------------------------------------------------------------------------
//   // Core processing
//   // -------------------------------------------------------------------------

//   /// Copies [imageFile] to the app's documents directory so it persists
//   /// across sessions (gallery / camera temp files can be deleted by the OS).
//   static Future<String> _saveImageLocally(File imageFile) async {
//     final dir = await getApplicationDocumentsDirectory();
//     final receiptsDir = Directory(p.join(dir.path, 'receipt_images'));
//     if (!receiptsDir.existsSync()) {
//       receiptsDir.createSync(recursive: true);
//     }
//     final ext = p.extension(imageFile.path).isNotEmpty
//         ? p.extension(imageFile.path)
//         : '.jpg';
//     final dest = p.join(receiptsDir.path, '${_uuid.v4()}$ext');
//     final saved = await imageFile.copy(dest);
//     return saved.path;
//   }

//   /// Maximum number of automatic retries on quota errors.
//   static const int _maxRetries = 3;

//   /// Checks whether [error] is a quota-exceeded error from Gemini.
//   static bool _isQuotaError(Object error) {
//     final msg = error.toString();
//     return msg.contains('Quota exceeded') || msg.contains('RESOURCE_EXHAUSTED');
//   }

//   /// Full pipeline with automatic retry on quota errors:
//   ///   1. Save image locally.
//   ///   2. Send to Gemini via Firebase AI Logic (with retry).
//   ///   3. Parse JSON response.
//   ///   4. Persist to Hive.
//   ///   5. Return the [ReceiptModel].
//   ///
//   /// Throws on unrecoverable errors (network, parse, etc.).
//   static Future<ReceiptModel> processReceipt(File imageFile) async {
//     // 1 – Persist image locally
//     final localPath = await _saveImageLocally(imageFile);

//     // 2 – Build Gemini model
//     final model = FirebaseAI.googleAI().generativeModel(
//       model: 'gemini-2.5-flash',
//     );

//     // 3 – Build the multimodal request
//     final imageBytes = await imageFile.readAsBytes();
//     final content = Content.multi([
//       InlineDataPart('image/jpeg', imageBytes),
//       TextPart(_receiptPrompt),
//     ]);

//     // 4 – Send with exponential backoff on quota errors
//     String rawText;
//     int attempt = 0;
//     while (true) {
//       try {
//         final response = await model.generateContent([content]);
//         rawText = response.text?.trim() ?? '';
//         break; // success
//       } catch (e) {
//         attempt++;
//         if (_isQuotaError(e) && attempt <= _maxRetries) {
//           final delay = Duration(seconds: 2 * attempt); // 2s, 4s, 6s
//           debugPrint('[ReceiptService] Quota error (attempt $attempt/$_maxRetries) — '
//               'retrying in ${delay.inSeconds}s…');
//           await Future.delayed(delay);
//           continue;
//         }
//         rethrow;
//       }
//     }

//     if (rawText.isEmpty) {
//       throw Exception('Gemini returned an empty response.');
//     }

//     // 5 – Strip any accidental markdown fences
//     final cleaned = _stripMarkdownFences(rawText);

//     // 6 – Parse JSON
//     final Map<String, dynamic> jsonData;
//     try {
//       jsonData = jsonDecode(cleaned) as Map<String, dynamic>;
//     } catch (e) {
//       throw FormatException(
//         'Could not parse Gemini response as JSON.\n'
//         'Raw response:\n$cleaned\nError: $e',
//       );
//     }

//     // 7 – Build model
//     final receipt = ReceiptModel.fromJson(
//       jsonData,
//       id: _uuid.v4(),
//       imagePath: localPath,
//     );

//     // 8 – Persist
//     await HiveService.saveReceipt(receipt);

//     return receipt;
//   }

//   // -------------------------------------------------------------------------
//   // Helpers
//   // -------------------------------------------------------------------------

//   static String _stripMarkdownFences(String text) {
//     // Remove ```json ... ``` or ``` ... ``` wrappers if present
//     final fenceRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
//     final match = fenceRegex.firstMatch(text);
//     if (match != null) {
//       return match.group(1)?.trim() ?? text;
//     }
//     return text;
//   }
// }

// receipt_service.dart
// Firebase AI Logic — Gemini Developer API backend
//
// Prerequisites (Firebase Console):
//   1. Go to Firebase Console → your project → "AI Logic" (left sidebar)
//   2. Select "Gemini Developer API" → click Enable
//   3. It redirects to Google Cloud Console → click Enable there too
//   4. Come back — you should see "Gemini Developer API — Enabled"
//
// Correct firebase_ai v3 API reference:
//   ✅ FirebaseAI.googleAI()             → Gemini Developer API (free tier)
//   ✅ FirebaseAI.vertexAI()             → Vertex AI (Blaze plan required)
//   ✅ DataPart(mimeType, Uint8List)     → inline image data
//   ✅ TextPart(string)                  → text prompt
//   ✅ Content.multi([DataPart, TextPart]) → multimodal content
//   ❌ InlineDataPart                    → does NOT exist
//   ❌ FirebaseAI.instance               → does NOT exist

import 'dart:convert';
import 'dart:io';

import 'package:ai_logic_firebase/model/receipt_model.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'hive_service.dart';

// ---------------------------------------------------------------------------
// Prompt
// ---------------------------------------------------------------------------

const String _receiptPrompt = '''
You are an expert OCR and receipt-parsing assistant.

Analyse the provided receipt image and extract ALL visible information.

Return ONLY a single valid JSON object — no markdown fences, no explanation,
no comments, no trailing text. Any field not visible must be null or empty string.

Required JSON structure:
{
  "shopName":      "<string>",
  "billNumber":    "<string>",
  "date":          "<string>",
  "time":          "<string>",
  "gstNumber":     "<string>",
  "subtotal":      <number>,
  "gstPercentage": <number>,
  "gstAmount":     <number>,
  "grandTotal":    <number>,
  "items": [
    {
      "itemName": "<string>",
      "quantity": <number>,
      "price":    <number>,
      "total":    <number>
    }
  ]
}
''';

// ---------------------------------------------------------------------------
// ReceiptService
// ---------------------------------------------------------------------------

class ReceiptService {
  static final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();
  static GenerativeModel? _model;

  // ── Model initialisation ──────────────────────────────────────────────────
  //
  // FirebaseAI.googleAI() → uses Gemini Developer API (free tier)
  //   • Free quota: 15 requests/minute, 1500 requests/day
  //   • Requires: "Gemini Developer API" enabled in Firebase Console → AI Logic
  //
  // To switch to Vertex AI (paid, Blaze plan), replace with:
  //   FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.0-flash')
  //
  static GenerativeModel _getModel() {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite',
    );
    return _model!;
  }

  // ── Image pickers ─────────────────────────────────────────────────────────

  static Future<File?> pickFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    return xFile == null ? null : File(xFile.path);
  }

  static Future<File?> pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return xFile == null ? null : File(xFile.path);
  }

  // ── Save image locally ────────────────────────────────────────────────────

  static Future<String> _saveImageLocally(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(dir.path, 'receipt_images'));
    if (!receiptsDir.existsSync()) {
      receiptsDir.createSync(recursive: true);
    }
    final ext = p.extension(imageFile.path).isNotEmpty
        ? p.extension(imageFile.path)
        : '.jpg';
    final dest = p.join(receiptsDir.path, '${_uuid.v4()}$ext');
    return (await imageFile.copy(dest)).path;
  }

  // ── MIME type helper ──────────────────────────────────────────────────────

  static String _mimeType(File file) {
    final ext = p.extension(file.path).toLowerCase();
    const map = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.heic': 'image/heic',
    };
    return map[ext] ?? 'image/jpeg';
  }

  // ── Main pipeline ─────────────────────────────────────────────────────────

  static Future<ReceiptModel> processReceipt(File imageFile) async {
    // 1. Persist image to local storage
    final localPath = await _saveImageLocally(imageFile);

    // 2. Read image bytes
    final imageBytes = await imageFile.readAsBytes();
    final mime = _mimeType(imageFile);

    // 3. Build multimodal Content
    //    DataPart  → carries the raw image bytes with MIME type
    //    TextPart  → carries the text instruction/prompt
    //    Content.multi([...]) → combines both into one multimodal message
    final content = Content.multi([
      InlineDataPart(mime, imageBytes),
      TextPart(_receiptPrompt),
    ]);

    // 4. Call Gemini via Firebase AI Logic
    GenerateContentResponse response;
    try {
      response = await _getModel().generateContent([content]);
    } catch (e) {
      // Provide a clear, actionable error message
      final msg = e.toString();
      if (msg.contains('RESOURCE_EXHAUSTED')) {
        throw Exception(
          'Gemini API quota exceeded.\n\n'
          'Fix: Go to Firebase Console → AI Logic → '
          'make sure "Gemini Developer API" is Enabled.\n\n'
          'If already enabled, wait a minute and retry '
          '(free tier: 15 requests/minute).',
        );
      }
      if (msg.contains('API_KEY') || msg.contains('PERMISSION_DENIED')) {
        throw Exception(
          'Firebase AI Logic not properly configured.\n\n'
          'Fix:\n'
          '1. Firebase Console → AI Logic → Enable Gemini Developer API\n'
          '2. Make sure google-services.json is up to date\n'
          '3. Run: flutter clean && flutter run',
        );
      }
      rethrow;
    }

    final rawText = response.text?.trim() ?? '';
    if (rawText.isEmpty) {
      throw Exception(
        'Gemini returned an empty response.\n'
        'Please try again with a clearer receipt image.',
      );
    }

    // 5. Strip any accidental markdown fences
    final cleaned = _stripMarkdownFences(rawText);

    // 6. Parse JSON
    final Map<String, dynamic> jsonData;
    try {
      jsonData = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException(
        'Could not parse Gemini response as JSON.\n'
        'Raw response:\n$cleaned\n\nParse error: $e',
      );
    }

    // 7. Build ReceiptModel + persist to Hive
    final receipt = ReceiptModel.fromJson(
      jsonData,
      id: _uuid.v4(),
      imagePath: localPath,
    );
    await HiveService.saveReceipt(receipt);

    return receipt;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _stripMarkdownFences(String text) {
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = fence.firstMatch(text);
    if (match != null) return match.group(1)?.trim() ?? text;
    return text;
  }
}
