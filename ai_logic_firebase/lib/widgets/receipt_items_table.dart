import 'package:flutter/material.dart';
import 'package:ai_logic_firebase/model/receipt_model.dart';
import 'package:ai_logic_firebase/utils/format_helpers.dart';

class ReceiptItemsTable extends StatelessWidget {
  final List<ReceiptItem> items;

  const ReceiptItemsTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E3E)),
        ),
        child: const Center(
          child: Text(
            'No items found',
            style: TextStyle(color: Color(0xFF8E8E9E), fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E3E), width: 1),
      ),
      child: Column(
        children: [
          _tableHeaderRow(),
          const Divider(color: Color(0xFF2E2E3E), height: 1),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return Column(
              children: [
                _tableDataRow(entry.value),
                if (!isLast)
                  const Divider(
                    color: Color(0xFF2E2E3E),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _tableHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Text(
              'Item',
              style: TextStyle(
                color: Color(0xFF8E8E9E),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          _headerCell('Qty', flex: 2),
          _headerCell('Price', flex: 3),
          _headerCell('Total', flex: 3),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 3}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Color(0xFF8E8E9E),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _tableDataRow(ReceiptItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              item.itemName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _dataCell(formatNum(item.quantity), flex: 2),
          _dataCell(formatCurrency(item.price), flex: 3),
          _dataCell(formatCurrency(item.total), flex: 3, bold: true),
        ],
      ),
    );
  }

  Widget _dataCell(String text, {int flex = 3, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: bold ? Colors.white : const Color(0xFFCCCCDD),
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}
