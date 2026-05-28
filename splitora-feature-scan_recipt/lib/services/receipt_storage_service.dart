import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptImageData {
  final String filePath;
  final String merchantName;
  final double totalAmount;
  final String date;
  final double? perPersonAmount;

  ReceiptImageData({
    required this.filePath,
    required this.merchantName,
    required this.totalAmount,
    required this.date,
    this.perPersonAmount,
  });

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'merchantName': merchantName,
    'totalAmount': totalAmount,
    'date': date,
    'perPersonAmount': perPersonAmount,
  };

  factory ReceiptImageData.fromJson(Map<String, dynamic> json) =>
      ReceiptImageData(
        filePath: json['filePath'] as String? ?? '',
        merchantName: json['merchantName'] as String? ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        date: json['date'] as String? ?? '',
        perPersonAmount: (json['perPersonAmount'] as num?)?.toDouble(),
      );
}

class ReceiptStorageService {
  static final ReceiptStorageService instance = ReceiptStorageService._();
  ReceiptStorageService._();

  static const _storageKey = 'receipt_paths';
  Map<String, String> _cache = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      _cache = Map<String, String>.from(jsonDecode(stored) as Map);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_cache));
  }

  Future<String> saveReceiptImage(String billId, File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptDir = Directory('${appDir.path}/receipt_images');
    if (!await receiptDir.exists()) {
      await receiptDir.create(recursive: true);
    }
    final extension = imageFile.path.split('.').last;
    final newPath = '${receiptDir.path}/$billId.$extension';
    await imageFile.copy(newPath);

    _cache[billId] = newPath;
    await _persist();
    return newPath;
  }

  String? getReceiptPath(String billId) {
    return _cache[billId];
  }

  bool receiptExists(String billId) {
    final path = getReceiptPath(billId);
    if (path == null) return false;
    return File(path).existsSync();
  }

  Future<void> deleteReceipt(String billId) async {
    final path = _cache[billId];
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _cache.remove(billId);
      await _persist();
    }
  }

  Future<File?> getReceiptFile(String billId) async {
    final path = getReceiptPath(billId);
    if (path == null) return null;
    final file = File(path);
    if (await file.exists()) return file;
    return null;
  }
}
