import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/receipt_model.dart';
import '../services/hive_database_service.dart';

class ReceiptRepository {
  final HiveDatabaseService _hiveService;

  ReceiptRepository(this._hiveService);

  Future<void> saveReceipt(Receipt receipt, File imageFile) async {
    // Generate an ID if not exists
    final id = receipt.id ?? const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // We skip Firebase Storage upload and just use localImagePath
    final receiptToSave = receipt.copyWith(
      id: id,
      localImagePath: imageFile.path,
      timestamp: timestamp,
    );

    await _hiveService.saveReceipt(receiptToSave);
  }

  Future<List<Receipt>> getHistory() async {
    return await _hiveService.getReceipts();
  }
}
