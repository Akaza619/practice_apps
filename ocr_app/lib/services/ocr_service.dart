// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// class OcrService {
//   final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

//   /// Extracts all text from an image at [imagePath].
//   Future<String> extractText(String imagePath) async {
//     final inputImage = InputImage.fromFilePath(imagePath);
//     final recognizedText = await _recognizer.processImage(inputImage);
//     return recognizedText.text;
//   }

//   /// Returns text blocks with bounding box info — useful for advanced layouts.
//   Future<List<TextBlock>> extractBlocks(String imagePath) async {
//     final inputImage = InputImage.fromFilePath(imagePath);
//     final recognizedText = await _recognizer.processImage(inputImage);
//     return recognizedText.blocks;
//   }

//   void dispose() {
//     _recognizer.close();
//   }
// }

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// OCR service wrapping Google ML Kit text recognition.
///
/// Key fixes over the original:
/// 1. Spatial line reconstruction  — items and prices on the same receipt line
///    are re-joined using bounding-box Y coordinates so the parser sees
///    "Bread  35.00" instead of "Bread" and "35.00" on separate lines.
/// 2. Image preprocessing          — forces 1600px minimum, 92% quality,
///    strips EXIF rotation so ML Kit always sees the image right-side up.
/// 3. Rotation fallback            — if first pass yields < 20 chars, retries
///    with image rotated 90° (covers sideways-scanned receipts).
/// 4. Text cleanup                 — fixes common OCR misreads (O→0, l→1,
///    Rs.→₹, decorative separator lines removed).
class OcrService {
  final _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extracts cleaned, spatially-aligned text from the image at [imagePath].
  Future<String> extractText(String imagePath) async {
    final preprocessed = await _preprocessImage(imagePath);
    final targetPath = preprocessed ?? imagePath;

    try {
      final inputImage = InputImage.fromFilePath(targetPath);
      final result = await _latinRecognizer.processImage(inputImage);

      // If ML Kit returned almost nothing, try a 90° rotation.
      // This handles receipts captured in landscape on some devices.
      if (_isTooShort(result.text)) {
        final rotated = await _rotateImage(targetPath, 90);
        if (rotated != null) {
          final result2 = await _latinRecognizer.processImage(
            InputImage.fromFilePath(rotated),
          );
          try {
            File(rotated).deleteSync();
          } catch (_) {}
          if (result2.text.length > result.text.length) {
            return _buildAlignedText(result2.blocks);
          }
        }
      }

      return _buildAlignedText(result.blocks);
    } finally {
      if (preprocessed != null && preprocessed != imagePath) {
        try {
          File(preprocessed).deleteSync();
        } catch (_) {}
      }
    }
  }

  /// Returns raw TextBlock list — useful for bounding-box highlighting in UI.
  Future<List<TextBlock>> extractBlocks(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _latinRecognizer.processImage(inputImage);
    return result.blocks;
  }

  // ─── Image preprocessing ───────────────────────────────────────────────────

  /// Resize to ≥1600 px on both axes and remove EXIF rotation.
  /// ML Kit accuracy degrades significantly below ~1200 px.
  Future<String?> _preprocessImage(String source) async {
    try {
      final tmp = await getTemporaryDirectory();
      final out =
          '${tmp.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final r = await FlutterImageCompress.compressAndGetFile(
        source,
        out,
        quality: 92,
        minWidth: 1600,
        minHeight: 1600,
        keepExif: false, // strips rotation tag → image is always upright
      );
      return r?.path;
    } catch (_) {
      return null;
    }
  }

  /// Return a new temp file with the image rotated [degrees] clockwise.
  Future<String?> _rotateImage(String source, int degrees) async {
    try {
      final tmp = await getTemporaryDirectory();
      final out =
          '${tmp.path}/ocr_rot_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final r = await FlutterImageCompress.compressAndGetFile(
        source,
        out,
        quality: 92,
        rotate: degrees,
      );
      return r?.path;
    } catch (_) {
      return null;
    }
  }

  // ─── Spatial line reconstruction (CORE FIX) ────────────────────────────────

  /// ML Kit splits a receipt into blocks (text regions).
  /// A "ITEM NAME ... ₹35.00" row is often TWO blocks: left-aligned name and
  /// right-aligned price. Default .text concatenation puts them on separate
  /// lines, breaking every parser regex.
  ///
  /// This method groups TextLines by their vertical centre (±12 px tolerance),
  /// then within each group sorts left-to-right and joins with two spaces,
  /// reproducing the spatial layout of the original receipt.
  String _buildAlignedText(List<TextBlock> blocks) {
    final ocrLines = <_OcrLine>[];

    for (final block in blocks) {
      for (final line in block.lines) {
        final rect = line.boundingBox;
        final y = rect.top + rect.height / 2.0;
        final x = rect.left.toDouble();
        ocrLines.add(_OcrLine(y: y, x: x, text: line.text));
      }
    }

    if (ocrLines.isEmpty) return '';

    // Sort vertically
    ocrLines.sort((a, b) => a.y.compareTo(b.y));

    // Group into physical rows: lines within 12 px of each other = same row
    const threshold = 12.0;
    final rows = <List<_OcrLine>>[];
    var current = [ocrLines.first];

    for (int i = 1; i < ocrLines.length; i++) {
      if ((ocrLines[i].y - current.last.y).abs() <= threshold) {
        current.add(ocrLines[i]);
      } else {
        rows.add(current);
        current = [ocrLines[i]];
      }
    }
    rows.add(current);

    // Within each row, sort left→right and join with double space
    final resultLines = rows.map((row) {
      row.sort((a, b) => a.x.compareTo(b.x));
      return row.map((l) => l.text).join('  ');
    });

    return _cleanText(resultLines.join('\n'));
  }

  // ─── Text cleanup ─────────────────────────────────────────────────────────

  bool _isTooShort(String t) => t.trim().length < 20;

  /// Fix common OCR character errors in Indian receipt context.
  String _cleanText(String raw) {
    var t = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Normalise rupee symbol variants (OCR often reads ₹ as Rs., RE, INR)
    t = t.replaceAll(RegExp(r'\bRs\.?\s*', caseSensitive: false), '₹');
    t = t.replaceAll(RegExp(r'\bINR\s*', caseSensitive: false), '₹');
    t = t.replaceAll(RegExp(r'\bRE\.?\s*', caseSensitive: false), '₹');

    // Fix digit misreads inside price-like sequences
    // Capital-O between digits: "1O.5O" → "10.50"
    t = t.replaceAllMapped(RegExp(r'(\d)[Oo](\d)'), (m) => '${m[1]}0${m[2]}');
    // Lowercase-l at start of a number: "l2.00" → "12.00"
    t = t.replaceAllMapped(RegExp(r'\bl(\d)'), (m) => '1${m[1]}');
    // S between digits (rare but happens): "1S5" → "155"
    t = t.replaceAllMapped(RegExp(r'(\d)S(\d)'), (m) => '${m[1]}5${m[2]}');

    // Remove purely decorative separator lines (-----, =====, .....)
    final cleaned = t.split('\n').where((line) {
      final s = line.trim();
      if (s.isEmpty) return true;
      final special = s.replaceAll(RegExp(r'[a-zA-Z0-9₹]'), '');
      return (special.length / s.length) < 0.85;
    });

    return cleaned.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  void dispose() {
    _latinRecognizer.close();
  }
}

class _OcrLine {
  final double y, x;
  final String text;
  _OcrLine({required this.y, required this.x, required this.text});
}
