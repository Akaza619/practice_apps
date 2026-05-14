import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/receipt_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/receipt_table_widget.dart';
import '../utils/constants.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(receiptHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan History', style: TextStyle(fontFamily: 'monospace', letterSpacing: 1.5))),
      body: historyAsync.when(
        data: (receipts) {
          if (receipts.isEmpty) {
            return const Center(child: Text('NO RECORDS FOUND', style: TextStyle(fontFamily: 'monospace', color: Colors.white54, letterSpacing: 2.0)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final receipt = receipts[index];
              return Card(
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: AppConstants.primaryColor.withOpacity(0.2), width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ExpansionTile(
                  iconColor: AppConstants.primaryColor,
                  collapsedIconColor: Colors.white54,
                  title: Text(
                    receipt.billName ?? 'UNKNOWN VENDOR',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                  ),
                  subtitle: Text(
                    'TOTAL: ₹${receipt.totalAmount ?? 0}',
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.white70),
                  ),
                  children: [
                    if (receipt.localImagePath != null && File(receipt.localImagePath!).existsSync())
                      Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppConstants.primaryColor.withOpacity(0.5)),
                        ),
                        child: Image.file(
                          File(receipt.localImagePath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.2),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ReceiptTableWidget(receipt: receipt),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'FETCHING RECORDS...'),
        error: (error, stack) => Center(child: Text('ERROR: $error', style: const TextStyle(fontFamily: 'monospace', color: AppConstants.errorColor))),
      ),
    );
  }
}
