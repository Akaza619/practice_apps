import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/receipt.dart';

class StorageService {
  static const _boxName = 'receipts';
  late Box<Receipt> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ReceiptAdapter());
    Hive.registerAdapter(LineItemAdapter());
    _box = await Hive.openBox<Receipt>(_boxName);
  }

  Future<void> saveReceipt(Receipt receipt) async {
    await _box.put(receipt.id, receipt);
  }

  Future<void> deleteReceipt(String id) async {
    await _box.delete(id);
  }

  Future<void> updateReceipt(Receipt receipt) async {
    await receipt.save();
  }

  List<Receipt> getAllReceipts() {
    final receipts = _box.values.toList();
    receipts.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return receipts;
  }

  Receipt? getReceipt(String id) => _box.get(id);

  ValueListenable<Box<Receipt>> get listenable => _box.listenable();

  Map<String, double> getCategoryTotals() {
    final map = <String, double>{};
    for (final r in _box.values) {
      final cat = r.category ?? 'General';
      map[cat] = (map[cat] ?? 0) + r.total;
    }
    return map;
  }

  Map<String, double> getMonthlyTotals() {
    final map = <String, double>{};
    for (final r in _box.values) {
      final key = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + r.total;
    }
    return map;
  }

  double get totalSpent => _box.values.fold(0, (sum, r) => sum + r.total);

  int get receiptCount => _box.length;
}
