import 'package:flutter/material.dart';
import 'package:ai_logic_firebase/model/receipt_model.dart';

class ReceiptHeaderCard extends StatelessWidget {
  final ReceiptModel receipt;

  const ReceiptHeaderCard({super.key, required this.receipt});

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
          _shopHeader(),
          _headerRow(Icons.calendar_today_rounded, 'Date', receipt.date),
          _divider(),
          _headerRow(Icons.access_time_rounded, 'Time', receipt.time),
          if (receipt.gstNumber != 'N/A') ...[
            _divider(),
            _headerRow(Icons.numbers_rounded, 'GST No.', receipt.gstNumber),
          ],
        ],
      ),
    );
  }

  Widget _shopHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Color(0xFF6C63FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.shopName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (receipt.billNumber != 'N/A')
                  Text(
                    'Bill #${receipt.billNumber}',
                    style: const TextStyle(
                      color: Color(0xFF8E8E9E),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8E8E9E), fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
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
