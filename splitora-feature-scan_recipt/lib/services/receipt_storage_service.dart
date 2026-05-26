import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

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

  static const _boxName = 'receipts';

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
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

    final box = Hive.box<String>(_boxName);
    await box.put(billId, newPath);
    return newPath;
  }

  String? getReceiptPath(String billId) {
    final box = Hive.box<String>(_boxName);
    return box.get(billId);
  }

  bool receiptExists(String billId) {
    final path = getReceiptPath(billId);
    if (path == null) return false;
    return File(path).existsSync();
  }

  Future<void> deleteReceipt(String billId) async {
    final box = Hive.box<String>(_boxName);
    final path = box.get(billId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await box.delete(billId);
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
