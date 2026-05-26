import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

class ReceiptLineItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  ReceiptLineItem({
    required this.name,
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
  });

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) {
    return ReceiptLineItem(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
  };
}

class ReceiptScanResult {
  final String merchantName;
  final String merchantAddress;
  final String date;
  final String time;
  final String receiptNumber;
  final double grandTotal;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final String currency;
  final String paymentMethod;
  final String rawNotes;
  final List<ReceiptLineItem> lineItems;

  ReceiptScanResult({
    this.merchantName = '',
    this.merchantAddress = '',
    this.date = '',
    this.time = '',
    this.receiptNumber = '',
    this.grandTotal = 0.0,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.currency = 'INR',
    this.paymentMethod = 'UNKNOWN',
    this.rawNotes = '',
    this.lineItems = const [],
  });

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) {
    return ReceiptScanResult(
      merchantName: json['merchant_name'] as String? ?? '',
      merchantAddress: json['merchant_address'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      receiptNumber: json['receipt_number'] as String? ?? '',
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      paymentMethod: json['payment_method'] as String? ?? 'UNKNOWN',
      rawNotes: json['raw_notes'] as String? ?? '',
      lineItems:
          (json['line_items'] as List<dynamic>?)
              ?.map((e) => ReceiptLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'merchant_name': merchantName,
    'merchant_address': merchantAddress,
    'date': date,
    'time': time,
    'receipt_number': receiptNumber,
    'grand_total': grandTotal,
    'subtotal': subtotal,
    'tax_amount': taxAmount,
    'discount_amount': discountAmount,
    'currency': currency,
    'payment_method': paymentMethod,
    'raw_notes': rawNotes,
    'line_items': lineItems.map((e) => e.toJson()).toList(),
  };
}

class ReceiptScanException implements Exception {
  final String message;
  const ReceiptScanException(this.message);

  @override
  String toString() => 'ReceiptScanException: $message';
}

class ReceiptAiService {
  ReceiptAiService._();
  static final ReceiptAiService instance = ReceiptAiService._();

  Future<ReceiptScanResult> scanReceiptFromFile(File file) async {
    try {
      final Uint8List imageBytes = await file.readAsBytes();
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-lite',
      );

      const prompt = '''
Analyze this receipt image and extract the following information in JSON format. Do NOT include markdown code blocks or any other text outside the JSON.

{
  "merchant_name": "string",
  "merchant_address": "string",
  "date": "YYYY-MM-DD",
  "time": "HH:MM",
  "receipt_number": "string",
  "grand_total": 0.0,
  "subtotal": 0.0,
  "tax_amount": 0.0,
  "discount_amount": 0.0,
  "currency": "INR",
  "payment_method": "CASH/CARD/UPI/UNKNOWN",
  "raw_notes": "string",
  "line_items": [
    {
      "name": "string",
      "quantity": 1,
      "unit_price": 0.0,
      "total_price": 0.0
    }
  ]
}
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);
      log(response.text.toString());
      String text = response.text?.trim() ?? '';

      if (text.isEmpty) {
        throw const ReceiptScanException('Empty response from AI model');
      }

      // Strip markdown code fences if present
      if (text.startsWith('```')) {
        final firstNewline = text.indexOf('\n');
        if (firstNewline != -1) {
          text = text.substring(firstNewline + 1);
        }
        final lastFence = text.lastIndexOf('```');
        if (lastFence != -1) {
          text = text.substring(0, lastFence);
        }
        text = text.trim();
      }

      final Map<String, dynamic> json =
          jsonDecode(text) as Map<String, dynamic>;
      return ReceiptScanResult.fromJson(json);
    } on ReceiptScanException {
      rethrow;
    } catch (e) {
      throw ReceiptScanException('Failed to scan receipt: $e');
    }
  }
}
