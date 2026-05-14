import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt_model.dart';
import '../services/firebase_ai_service.dart';
import '../services/image_picker_service.dart';
import '../services/hive_database_service.dart';
import '../repositories/receipt_repository.dart';
import '../utils/constants.dart';

final imagePickerProvider = Provider((ref) => ImagePickerService());
final firebaseAiProvider = Provider((ref) => FirebaseAiService(AppConstants.geminiApiKey));
final hiveDatabaseProvider = Provider((ref) => HiveDatabaseService());

final receiptRepositoryProvider = Provider((ref) => ReceiptRepository(
      ref.read(hiveDatabaseProvider),
    ));

// State notifier for scanned receipt
class ScannedReceiptNotifier extends AsyncNotifier<Receipt?> {
  @override
  FutureOr<Receipt?> build() {
    return null;
  }

  Future<void> scanImage(File image) async {
    state = const AsyncLoading();
    try {
      final aiService = ref.read(firebaseAiProvider);
      final jsonResponse = await aiService.analyzeReceipt(image);

      if (jsonResponse == null) {
        state = AsyncError('Failed to parse response', StackTrace.current);
        return;
      }

      if (jsonResponse.containsKey('error')) {
        state = AsyncError(jsonResponse['error'], StackTrace.current);
        return;
      }

      final receipt = Receipt.fromJson(
        jsonResponse,
        localImagePath: image.path,
      );
      state = AsyncData(receipt);
    } catch (e, stack) {
      state = AsyncError(e.toString(), stack);
    }
  }

  void updateReceipt(Receipt updatedReceipt) {
    state = AsyncData(updatedReceipt);
  }

  Future<void> saveCurrentReceipt(File image) async {
    final currentReceipt = state.value;
    if (currentReceipt == null) return;

    state = const AsyncLoading();
    try {
      final repo = ref.read(receiptRepositoryProvider);
      await repo.saveReceipt(currentReceipt, image);
      state = const AsyncData(null); // Clear after save
    } catch (e, stack) {
      state = AsyncError(e.toString(), stack);
    }
  }

  void clear() {
    state = const AsyncData(null);
  }
}

final scannedReceiptProvider =
    AsyncNotifierProvider<ScannedReceiptNotifier, Receipt?>(() {
      return ScannedReceiptNotifier();
    });

// Provider for history
final receiptHistoryProvider = FutureProvider<List<Receipt>>((ref) async {
  final repo = ref.read(receiptRepositoryProvider);
  return await repo.getHistory();
});
