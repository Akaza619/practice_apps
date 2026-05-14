import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/receipt_model.dart';

class HiveDatabaseService {
  static const String _boxName = 'receiptsBox';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
  }

  Future<void> saveReceipt(Receipt receipt) async {
    final box = Hive.box<String>(_boxName);
    if (receipt.id != null) {
      await box.put(receipt.id, jsonEncode(receipt.toJson()));
    }
  }

  Future<List<Receipt>> getReceipts() async {
    final box = Hive.box<String>(_boxName);
    
    final receipts = box.values.map((jsonString) {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return Receipt.fromJson(map);
    }).toList();

    // Sort by timestamp descending
    receipts.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
    
    return receipts;
  }
}
