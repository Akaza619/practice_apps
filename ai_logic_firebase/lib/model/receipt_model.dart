// receipt_model.dart
// Part of the OCR Receipt Scanner module.
// Run the build_runner after adding this file:
//   flutter pub run build_runner build --delete-conflicting-outputs
//
// Hive TypeAdapter IDs used:
//   ReceiptModel      → typeId: 10
//   ReceiptItem       → typeId: 11

import 'package:hive/hive.dart';

part 'receipt_model.g.dart';

// ---------------------------------------------------------------------------
// ReceiptItem
// ---------------------------------------------------------------------------

@HiveType(typeId: 11)
class ReceiptItem extends HiveObject {
  @HiveField(0)
  final String itemName;

  @HiveField(1)
  final double quantity;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final double total;

  ReceiptItem({
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      itemName: (json['itemName'] ?? json['item_name'] ?? 'Unknown Item')
          .toString(),
      quantity: _toDouble(json['quantity']),
      price: _toDouble(json['price']),
      total: _toDouble(json['total']),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemName': itemName,
    'quantity': quantity,
    'price': price,
    'total': total,
  };

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

// ---------------------------------------------------------------------------
// ReceiptModel
// ---------------------------------------------------------------------------

@HiveType(typeId: 10)
class ReceiptModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String shopName;

  @HiveField(2)
  String billNumber;

  @HiveField(3)
  String date;

  @HiveField(4)
  String time;

  @HiveField(5)
  String gstNumber;

  @HiveField(6)
  double subtotal;

  @HiveField(7)
  double gstPercentage;

  @HiveField(8)
  double gstAmount;

  @HiveField(9)
  double grandTotal;

  @HiveField(10)
  String imagePath;

  @HiveField(11)
  List<ReceiptItem> items;

  @HiveField(12)
  DateTime createdAt;

  ReceiptModel({
    required this.id,
    required this.shopName,
    required this.billNumber,
    required this.date,
    required this.time,
    required this.gstNumber,
    required this.subtotal,
    required this.gstPercentage,
    required this.gstAmount,
    required this.grandTotal,
    required this.imagePath,
    required this.items,
    required this.createdAt,
  });

  factory ReceiptModel.fromJson(
    Map<String, dynamic> json, {
    required String id,
    required String imagePath,
  }) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReceiptModel(
      id: id,
      shopName: _str(json['shopName'] ?? json['shop_name']),
      billNumber: _str(json['billNumber'] ?? json['bill_number']),
      date: _str(json['date']),
      time: _str(json['time']),
      gstNumber: _str(json['gstNumber'] ?? json['gst_number']),
      subtotal: _toDouble(json['subtotal']),
      gstPercentage: _toDouble(json['gstPercentage'] ?? json['gst_percentage']),
      gstAmount: _toDouble(json['gstAmount'] ?? json['gst_amount']),
      grandTotal: _toDouble(json['grandTotal'] ?? json['grand_total']),
      imagePath: imagePath,
      items: parsedItems,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shopName': shopName,
    'billNumber': billNumber,
    'date': date,
    'time': time,
    'gstNumber': gstNumber,
    'subtotal': subtotal,
    'gstPercentage': gstPercentage,
    'gstAmount': gstAmount,
    'grandTotal': grandTotal,
    'imagePath': imagePath,
    'items': items.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  static String _str(dynamic val) =>
      val == null || val.toString().trim().isEmpty
      ? 'N/A'
      : val.toString().trim();

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
