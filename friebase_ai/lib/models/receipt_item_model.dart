class ReceiptItem {
  final String? itemName;
  final num? itemCount;
  final num? unitPrice;
  final num? finalPrice;

  ReceiptItem({
    this.itemName,
    this.itemCount,
    this.unitPrice,
    this.finalPrice,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      itemName: json['item_name'] as String?,
      itemCount: json['item_count'] as num?,
      unitPrice: json['unit_price'] as num?,
      finalPrice: json['final_price'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'item_count': itemCount,
      'unit_price': unitPrice,
      'final_price': finalPrice,
    };
  }

  ReceiptItem copyWith({
    String? itemName,
    num? itemCount,
    num? unitPrice,
    num? finalPrice,
  }) {
    return ReceiptItem(
      itemName: itemName ?? this.itemName,
      itemCount: itemCount ?? this.itemCount,
      unitPrice: unitPrice ?? this.unitPrice,
      finalPrice: finalPrice ?? this.finalPrice,
    );
  }
}
