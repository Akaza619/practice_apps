import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/receipt_provider.dart';
import '../widgets/receipt_table_widget.dart';
import '../widgets/scanner_overlay.dart';
import '../utils/constants.dart';
import 'edit_receipt_screen.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final File imageFile;

  const ResultScreen({super.key, required this.imageFile});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  @override
  void initState() {
    super.initState();
    // Start analysis on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannedReceiptProvider.notifier).scanImage(widget.imageFile);
    });
  }

  void _saveReceipt() async {
    await ref
        .read(scannedReceiptProvider.notifier)
        .saveCurrentReceipt(widget.imageFile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt saved successfully!')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(scannedReceiptProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result', style: TextStyle(fontFamily: 'monospace'))),
      body: receiptState.when(
        data: (receipt) {
          if (receipt == null) {
            return const Center(child: Text('Initializing...', style: TextStyle(fontFamily: 'monospace')));
          }
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3), width: 2),
            ),
            margin: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '>>> OCR EXTRACTION COMPLETE <<<',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(color: AppConstants.primaryColor, thickness: 1, height: 32),
                  _buildDataRow('VENDOR', receipt.billName ?? 'UNKNOWN'),
                  const SizedBox(height: 16),
                  const Text('ITEMS:', style: TextStyle(color: AppConstants.primaryColor, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ReceiptTableWidget(receipt: receipt),
                  const SizedBox(height: 16),
                  _buildDataRow('GST PERCENT', '${receipt.gstPercent ?? 0}%'),
                  _buildDataRow('GST AMOUNT', '₹${receipt.gstAmount ?? 0}'),
                  const Divider(color: AppConstants.primaryColor, thickness: 1, height: 32),
                  _buildDataRow('TOTAL AMOUNT', '₹${receipt.totalAmount ?? 0}', isHighlight: true),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          label: const Text('EDIT', style: TextStyle(color: Colors.white70, fontFamily: 'monospace')),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditReceiptScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save, color: Colors.black),
                          label: const Text('SAVE RECORD', style: TextStyle(color: Colors.black, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _saveReceipt,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
        loading: () => ScannerOverlayWidget(imageFile: widget.imageFile),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppConstants.errorColor, size: 60),
                const SizedBox(height: 16),
                Text(
                  'EXTRACTION FAILED\n\n${error.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppConstants.errorColor, fontSize: 16, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppConstants.errorColor)),
                  child: const Text('ABORT', style: TextStyle(color: AppConstants.errorColor, fontFamily: 'monospace')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? AppConstants.primaryColor : Colors.white,
                fontFamily: 'monospace',
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                fontSize: isHighlight ? 18 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
