import 'package:hive/hive.dart';

part 'receipt.g.dart';

@HiveType(typeId: 0)
class Receipt extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String storeName;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  double total;

  @HiveField(4)
  List<LineItem> items;

  @HiveField(5)
  String? category;

  @HiveField(6)
  String? imagePath;

  @HiveField(7)
  String rawText;

  @HiveField(8)
  DateTime scannedAt;

  Receipt({
    required this.id,
    required this.storeName,
    required this.date,
    required this.total,
    required this.items,
    this.category,
    this.imagePath,
    required this.rawText,
    required this.scannedAt,
  });
}

@HiveType(typeId: 1)
class LineItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double price;

  @HiveField(2)
  double quantity;

  LineItem({required this.name, required this.price, this.quantity = 1.0});

  double get total => price * quantity;
}
