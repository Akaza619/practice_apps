import '../models/receipt.dart';

class ParsedReceiptData {
  final String storeName;
  final DateTime? date;
  final double? total;
  final double? subtotal;
  final double? tax;
  final List<LineItem> items;

  ParsedReceiptData({
    required this.storeName,
    this.date,
    this.total,
    this.subtotal,
    this.tax,
    required this.items,
  });
}

/// Parses raw OCR text (after spatial alignment) into a structured receipt.
///
/// Key fixes:
/// 1. Item regex now uses \s+ instead of \s{2,} — the spatial joiner uses
///    two spaces but OCR sometimes collapses them; single-space gaps are fine.
/// 2. Price pattern accepts both "35.00" and "35" (no decimal) and both
///    "₹35" and plain "35" — many Indian receipts omit the decimal.
/// 3. Total extraction now prefers the LAST occurrence of a "Total" line
///    (grand total is usually last), not the largest value.
/// 4. Tax extraction sums CGST + SGST separately and handles "18% GST" style.
/// 5. Store name extraction now skips lines that are all-caps abbreviations
///    (GSTIN, PAN) and phone numbers.
class ReceiptParserService {
  ParsedReceiptData parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return ParsedReceiptData(
      storeName: _extractStoreName(lines),
      date: _extractDate(rawText),
      total: _extractTotal(rawText),
      subtotal: _extractSubtotal(rawText),
      tax: _extractTax(rawText),
      items: _extractLineItems(lines),
    );
  }

  // ─── Store name ────────────────────────────────────────────────────────────

  String _extractStoreName(List<String> lines) {
    final skip = RegExp(
      r'(\d{10}|\+91|ph:|tel:|gst|gstin|pan:|invoice|receipt|bill|tax|'
      r'date:|time:|address|thank|welcome|visit|www\.|\.com|@)',
      caseSensitive: false,
    );
    // Also skip lines that are purely uppercase abbreviations (< 4 chars)
    for (final line in lines.take(6)) {
      if (line.length < 4) continue;
      if (skip.hasMatch(line)) continue;
      // Skip all-digit lines
      if (RegExp(r'^\d+$').hasMatch(line)) continue;
      return line;
    }
    return 'Unknown store';
  }

  // ─── Date ─────────────────────────────────────────────────────────────────

  DateTime? _extractDate(String text) {
    // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    final dmy = RegExp(r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})\b');
    // YYYY-MM-DD (ISO)
    final ymd = RegExp(r'\b(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})\b');
    // "19 Apr 2026" / "Apr 19, 2026"
    final monthNames = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final wordy = RegExp(
      r'\b(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[,\s]+(\d{4})\b',
      caseSensitive: false,
    );

    // Try ISO
    var m = ymd.firstMatch(text);
    if (m != null) {
      try {
        return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
      } catch (_) {}
    }
    // Try D/M/Y
    m = dmy.firstMatch(text);
    if (m != null) {
      try {
        return DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
      } catch (_) {}
    }
    // Try wordy
    m = wordy.firstMatch(text);
    if (m != null) {
      final mon = monthNames[m[2]!.toLowerCase().substring(0, 3)];
      if (mon != null) {
        try {
          return DateTime(int.parse(m[3]!), mon, int.parse(m[1]!));
        } catch (_) {}
      }
    }
    return null;
  }

  // ─── Total ────────────────────────────────────────────────────────────────

  /// FIX: Use the LAST matching total line, not the largest value.
  /// "Subtotal" appears before "Grand Total" — original code picked whichever
  /// had the bigger number, which is usually correct but breaks if a line item
  /// happens to be larger than the subtotal line.
  double? _extractTotal(String text) {
    // Priority 1: explicit "grand total" / "net total" / "amount due"
    final priority = RegExp(
      r'(?:grand\s*total|net\s*total|amount\s*(?:due|payable|paid)|'
      r'total\s*amount|bill\s*amount)[^\d₹]*[₹]?\s*(\d[\d,]*\.?\d{0,2})',
      caseSensitive: false,
    );
    double? found;
    for (final m in priority.allMatches(text)) {
      final v = _parseAmount(m[1]!);
      if (v != null && v > 0) found = v; // keep LAST match
    }
    if (found != null) return found;

    // Priority 2: plain "total" line — take the LAST occurrence
    final plain = RegExp(
      r'(?:^|\n)\s*total\s*[:\-]?\s*[₹]?\s*(\d[\d,]*\.?\d{0,2})',
      caseSensitive: false,
    );
    for (final m in plain.allMatches(text)) {
      final v = _parseAmount(m[1]!);
      if (v != null && v > 0) found = v;
    }
    if (found != null) return found;

    // Priority 3: largest standalone ₹ amount (last resort)
    final anyPrice = RegExp(r'₹\s*(\d[\d,]*\.?\d{0,2})', caseSensitive: false);
    double? largest;
    for (final m in anyPrice.allMatches(text)) {
      final v = _parseAmount(m[1]!);
      if (v != null && (largest == null || v > largest)) largest = v;
    }
    return largest;
  }

  // ─── Subtotal ─────────────────────────────────────────────────────────────

  double? _extractSubtotal(String text) {
    final re = RegExp(
      r'(?:subtotal|sub[-\s]?total)[^\d₹]*[₹]?\s*(\d[\d,]*\.?\d{0,2})',
      caseSensitive: false,
    );
    return _parseAmount(re.firstMatch(text)?[1] ?? '');
  }

  // ─── Tax ──────────────────────────────────────────────────────────────────

  double? _extractTax(String text) {
    // Matches "CGST 9% 45.00", "GST: 24.50", "Tax 18.00"
    final re = RegExp(
      r'(?:gst|cgst|sgst|igst|vat|tax|service\s*charge|cess)'
      r'(?:\s*[@]?\s*\d+(?:\.\d+)?\s*%)?'
      r'[^\d₹]*[₹]?\s*(\d[\d,]*\.?\d{0,2})',
      caseSensitive: false,
    );
    double? total;
    for (final m in re.allMatches(text)) {
      final v = _parseAmount(m[1]!);
      if (v != null && v > 0) total = (total ?? 0) + v;
    }
    return total;
  }

  // ─── Line items ───────────────────────────────────────────────────────────

  List<LineItem> _extractLineItems(List<String> lines) {
    final items = <LineItem>[];

    // Skip lines that are obviously headers, totals, or metadata
    final skipLine = RegExp(
      r'^(s\.?no\.?|sr\.?|#|item|description|particulars|product|'
      r'qty|quantity|price|rate|amount|mrp|'
      r'subtotal|sub\s*total|total|tax|gst|cgst|sgst|igst|vat|'
      r'discount|offer|savings|'
      r'date|time|invoice|receipt|bill|order|table|cashier|'
      r'store|address|phone|gstin|pan|thank|welcome|visit|www\.|'
      r'-{3,}|={3,}|\.{3,})',
      caseSensitive: false,
    );

    // ── Pattern A: "Name   qty   unit_price   line_total"
    // e.g. "Bread        2    17.50    35.00"
    final patternA = RegExp(
      r'^(.+?)\s+(\d+(?:\.\d+)?)\s+[₹]?(\d[\d,]*\.?\d{0,2})\s+[₹]?(\d[\d,]*\.?\d{0,2})\s*$',
    );

    // ── Pattern B: "Name   qty   price"  (no separate line total)
    // e.g. "Masala Tea  2  40.00"
    final patternB = RegExp(r'^(.+?)\s+(\d{1,3})\s+[₹]?(\d[\d,]*\.\d{2})\s*$');

    // ── Pattern C: "Name   price"  (single space or tab OK)
    // e.g. "Bread   35.00"  or  "Bread  ₹35"
    final patternC = RegExp(r'^(.+?)\s+[₹]?(\d[\d,]*\.?\d{0,2})\s*$');

    // ── Pattern D: "2 x 40.00" or "2X40" style mid-line
    final qtyX = RegExp(
      r'(\d+(?:\.\d+)?)\s*[xX×]\s*[₹]?\s*(\d[\d,]*\.?\d{0,2})',
    );

    for (final line in lines) {
      if (skipLine.hasMatch(line)) continue;
      // Must contain at least one digit to be a price line
      if (!line.contains(RegExp(r'\d'))) continue;
      // Skip very short lines (noise)
      if (line.length < 5) continue;

      // Pattern A — four columns
      var m = patternA.firstMatch(line);
      if (m != null) {
        final lineTotal = _parseAmount(m[4]!);
        final qty = double.tryParse(m[2]!) ?? 1.0;
        final unitPrice = _parseAmount(m[3]!);
        if (lineTotal != null && lineTotal > 0 && lineTotal < 1_000_000) {
          items.add(
            LineItem(
              name: _cleanName(m[1]!),
              price: unitPrice ?? lineTotal / qty,
              quantity: qty,
            ),
          );
          continue;
        }
      }

      // Inline qty×price (e.g. "2 x 40.00")
      final qm = qtyX.firstMatch(line);
      if (qm != null) {
        final qty = double.tryParse(qm[1]!) ?? 1.0;
        final unitPrice = _parseAmount(qm[2]!);
        if (unitPrice != null && unitPrice > 0) {
          // Item name is everything before the qty×price match
          final name = _cleanName(line.substring(0, qm.start));
          if (name.length >= 2) {
            items.add(LineItem(name: name, price: unitPrice, quantity: qty));
            continue;
          }
        }
      }

      // Pattern B — name qty price
      m = patternB.firstMatch(line);
      if (m != null) {
        final qty = double.tryParse(m[2]!) ?? 1.0;
        final price = _parseAmount(m[3]!);
        if (price != null && price > 0 && price < 1_000_000) {
          items.add(
            LineItem(name: _cleanName(m[1]!), price: price, quantity: qty),
          );
          continue;
        }
      }

      // Pattern C — name price (most common for simple receipts)
      m = patternC.firstMatch(line);
      if (m != null) {
        final name = _cleanName(m[1]!);
        final price = _parseAmount(m[2]!);
        // Sanity: name must have letters, price must be plausible
        if (name.length >= 2 &&
            name.contains(RegExp(r'[a-zA-Z]')) &&
            price != null &&
            price > 0 &&
            price < 1_000_000) {
          items.add(LineItem(name: name, price: price));
        }
      }
    }

    return items;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _cleanName(String raw) {
    var s = raw.trim();
    // Remove leading index numbers like "1." "01 " "A1."
    s = s.replaceAll(RegExp(r'^[\d]+[.\s)]+'), '').trim();
    // Remove trailing punctuation/symbols
    s = s.replaceAll(RegExp(r'[\-_.:|]+$'), '').trim();
    // Collapse multiple spaces
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ');
    // Title-case if all-caps (common on thermal receipts)
    if (s == s.toUpperCase() && s.length > 2) {
      s = s
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
          .join(' ');
    }
    return s;
  }

  double? _parseAmount(String raw) {
    if (raw.isEmpty) return null;
    // Remove currency symbols, spaces
    var s = raw.replaceAll(RegExp(r'[₹\$€£\s]'), '');
    // Remove thousands comma (1,234.56 → 1234.56)
    // But treat comma as decimal if pattern is "1234,56" (European style)
    if (RegExp(r',\d{3}($|\.)').hasMatch(s)) {
      s = s.replaceAll(',', '');
    } else {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  // ─── Category suggestion ──────────────────────────────────────────────────

  String suggestCategory(String storeName) {
    final s = storeName.toLowerCase();
    if (RegExp(
      r'restaurant|cafe|dhaba|food|pizza|burger|hotel|'
      r'swiggy|zomato|kitchen|biryani|diner',
    ).hasMatch(s)) {
      return 'Food & dining';
    }
    if (RegExp(
      r'pharmacy|medical|chemist|health|hospital|clinic|'
      r'apollo|medplus|netmeds',
    ).hasMatch(s)) {
      return 'Healthcare';
    }
    if (RegExp(
      r'supermart|grocery|fresh|bazaar|vegetables|fruits|'
      r'kirana|mart|dmart|bigbasket|reliance\s*fresh',
    ).hasMatch(s)) {
      return 'Groceries';
    }
    if (RegExp(r'petrol|fuel|gas|cng|hp|iocl|bpcl|essar|shell').hasMatch(s)) {
      return 'Fuel';
    }
    if (RegExp(
      r'fashion|clothing|wear|garment|apparel|lifestyle|'
      r'westside|zudio|h&m|myntra',
    ).hasMatch(s)) {
      return 'Fashion';
    }
    if (RegExp(
      r'digital|electronics|mobile|laptop|apple|samsung|'
      r'computer|croma|vijay\s*sales|reliance\s*digital',
    ).hasMatch(s)) {
      return 'Electronics';
    }
    if (RegExp(r'uber|ola|rapido|metro|bus|auto|cab|taxi').hasMatch(s)) {
      return 'Transport';
    }
    return 'General';
  }
}
