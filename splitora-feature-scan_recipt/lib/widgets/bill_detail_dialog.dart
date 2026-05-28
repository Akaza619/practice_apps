import 'package:flutter/material.dart';
import 'package:splitora_app/screens/bill_detail_screen.dart';

/// Navigates to a full-screen bill detail view.
/// Call this helper from any bill tile's onTap.
void showBillDetail(BuildContext context, Map<String, dynamic> data) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BillDetailScreen(data: data),
    ),
  );
}
