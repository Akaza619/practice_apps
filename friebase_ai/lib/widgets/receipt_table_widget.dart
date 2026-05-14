import 'package:flutter/material.dart';
import '../models/receipt_model.dart';

class ReceiptTableWidget extends StatelessWidget {
  final Receipt receipt;

  const ReceiptTableWidget({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontFamily: 'monospace');
    const headerStyle = TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.white70);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.white10),
        dataRowColor: MaterialStateProperty.all(Colors.transparent),
        dividerThickness: 0.5,
        columns: const [
          DataColumn(label: Text('ITEM NAME', style: headerStyle)),
          DataColumn(label: Text('QTY', style: headerStyle)),
          DataColumn(label: Text('UNIT PR', style: headerStyle)),
          DataColumn(label: Text('FINAL PR', style: headerStyle)),
        ],
        rows: receipt.items.map((item) {
          return DataRow(cells: [
            DataCell(Text(item.itemName ?? '-', style: textStyle)),
            DataCell(Text(item.itemCount?.toString() ?? '-', style: textStyle)),
            DataCell(Text(item.unitPrice != null ? '₹${item.unitPrice}' : '-', style: textStyle)),
            DataCell(Text(item.finalPrice != null ? '₹${item.finalPrice}' : '-', style: textStyle)),
          ]);
        }).toList(),
      ),
    );
  }
}
