// hive_service.dart
// Lightweight Hive wrapper for the Receipt Scanner module.
// Call HiveService.init() once in your app's main() AFTER Hive.initFlutter().

import 'package:ai_logic_firebase/model/receipt_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _receiptBoxName = 'receipts_box';
  static Box<ReceiptModel>? _box;

  // -------------------------------------------------------------------------
  // Initialisation – call once from main() or your app bootstrap
  // -------------------------------------------------------------------------

  /// Registers the Hive adapters and opens the receipts box.
  /// Safe to call multiple times – subsequent calls are no-ops.
  static Future<void> init() async {
    // Register adapters only once
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(ReceiptModelAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ReceiptItemAdapter());
    }

    _box = await Hive.openBox<ReceiptModel>(_receiptBoxName);
  }

  // -------------------------------------------------------------------------
  // Internal accessor – throws a clear message if init() was skipped
  // -------------------------------------------------------------------------

  static Box<ReceiptModel> get _openBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'HiveService is not initialised. '
        'Call await HiveService.init() before using the receipt scanner.',
      );
    }
    return _box!;
  }

  // -------------------------------------------------------------------------
  // CRUD
  // -------------------------------------------------------------------------

  /// Persist a [ReceiptModel]. Uses the model's [id] as the Hive key.
  static Future<void> saveReceipt(ReceiptModel receipt) async {
    await _openBox.put(receipt.id, receipt);
  }

  /// Retrieve all stored receipts, newest first.
  static List<ReceiptModel> getAllReceipts() {
    final all = _openBox.values.toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// Retrieve a single receipt by [id]. Returns null if not found.
  static ReceiptModel? getReceiptById(String id) => _openBox.get(id);

  /// Delete a receipt by [id].
  static Future<void> deleteReceipt(String id) async {
    await _openBox.delete(id);
  }

  /// Wipe all stored receipts.
  static Future<void> clearAll() async {
    await _openBox.clear();
  }
}
