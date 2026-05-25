import 'package:flutter/material.dart';
import 'package:ai_logic_firebase/model/receipt_model.dart';
import 'package:ai_logic_firebase/utils/format_helpers.dart';

class ReceiptSummaryCard extends StatelessWidget {
  final ReceiptModel receipt;

  const ReceiptSummaryCard({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E3E), width: 1),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', formatCurrency(receipt.subtotal)),
          _divider(),
          _summaryRow(
            'GST${receipt.gstPercentage > 0 ? " (${formatNum(receipt.gstPercentage)}%)" : ""}',
            formatCurrency(receipt.gstAmount),
          ),
          const Divider(color: Color(0xFF2E2E3E), height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  formatCurrency(receipt.grandTotal),
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8E8E9E), fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFCCCCDD),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    color: Color(0xFF2E2E3E),
    height: 1,
    indent: 20,
    endIndent: 20,
  );
}
