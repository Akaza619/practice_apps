import 'receipt_item_model.dart';

class Receipt {
  final String? id;
  final String? billName;
  final List<ReceiptItem> items;
  final num? gstPercent;
  final num? gstAmount;
  final num? totalAmount;
  final String? imageUrl;
  final String? localImagePath;
  final int? timestamp;

  Receipt({
    this.id,
    this.billName,
    this.items = const [],
    this.gstPercent,
    this.gstAmount,
    this.totalAmount,
    this.imageUrl,
    this.localImagePath,
    this.timestamp,
  });

  factory Receipt.fromJson(Map<String, dynamic> json, {String? id, String? imageUrl, String? localImagePath, int? timestamp}) {
    var itemsList = json['items'] as List?;
    List<ReceiptItem> parsedItems = itemsList != null
        ? itemsList.map((i) => ReceiptItem.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    return Receipt(
      id: id ?? json['id'] as String?,
      billName: json['bill_name'] as String?,
      items: parsedItems,
      gstPercent: json['gst_percent'] as num?,
      gstAmount: json['gst_amount'] as num?,
      totalAmount: json['total_amount'] as num?,
      imageUrl: imageUrl ?? json['image_url'] as String?,
      localImagePath: localImagePath ?? json['local_image_path'] as String?,
      timestamp: timestamp ?? json['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'bill_name': billName,
      'items': items.map((i) => i.toJson()).toList(),
      'gst_percent': gstPercent,
      'gst_amount': gstAmount,
      'total_amount': totalAmount,
      if (imageUrl != null) 'image_url': imageUrl,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }

  Receipt copyWith({
    String? id,
    String? billName,
    List<ReceiptItem>? items,
    num? gstPercent,
    num? gstAmount,
    num? totalAmount,
    String? imageUrl,
    String? localImagePath,
    int? timestamp,
  }) {
    return Receipt(
      id: id ?? this.id,
      billName: billName ?? this.billName,
      items: items ?? this.items,
      gstPercent: gstPercent ?? this.gstPercent,
      gstAmount: gstAmount ?? this.gstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
