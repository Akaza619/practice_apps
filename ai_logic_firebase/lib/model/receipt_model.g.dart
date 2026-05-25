// receipt_model.g.dart
// HAND-WRITTEN Hive TypeAdapters.
// This replaces the build_runner–generated file so the module works
// out-of-the-box without needing to run code generation.
// If you later add @HiveType fields, regenerate with:
//   flutter pub run build_runner build --delete-conflicting-outputs

part of 'receipt_model.dart';

// ---------------------------------------------------------------------------
// ReceiptItemAdapter  (typeId: 11)
// ---------------------------------------------------------------------------

class ReceiptItemAdapter extends TypeAdapter<ReceiptItem> {
  @override
  final int typeId = 11;

  @override
  ReceiptItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptItem(
      itemName: (fields[0] as String?) ?? '',
      quantity: (fields[1] as num?)?.toDouble() ?? 0.0,
      price: (fields[2] as num?)?.toDouble() ?? 0.0,
      total: (fields[3] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.itemName)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ---------------------------------------------------------------------------
// ReceiptModelAdapter  (typeId: 10)
// ---------------------------------------------------------------------------

class ReceiptModelAdapter extends TypeAdapter<ReceiptModel> {
  @override
  final int typeId = 10;

  @override
  ReceiptModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptModel(
      id: (fields[0] as String?) ?? '',
      shopName: (fields[1] as String?) ?? '',
      billNumber: (fields[2] as String?) ?? '',
      date: (fields[3] as String?) ?? '',
      time: (fields[4] as String?) ?? '',
      gstNumber: (fields[5] as String?) ?? '',
      subtotal: (fields[6] as num?)?.toDouble() ?? 0.0,
      gstPercentage: (fields[7] as num?)?.toDouble() ?? 0.0,
      gstAmount: (fields[8] as num?)?.toDouble() ?? 0.0,
      grandTotal: (fields[9] as num?)?.toDouble() ?? 0.0,
      imagePath: (fields[10] as String?) ?? '',
      items: (fields[11] as List?)?.cast<ReceiptItem>() ?? [],
      createdAt: fields[12] != null ? fields[12] as DateTime : DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shopName)
      ..writeByte(2)
      ..write(obj.billNumber)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.time)
      ..writeByte(5)
      ..write(obj.gstNumber)
      ..writeByte(6)
      ..write(obj.subtotal)
      ..writeByte(7)
      ..write(obj.gstPercentage)
      ..writeByte(8)
      ..write(obj.gstAmount)
      ..writeByte(9)
      ..write(obj.grandTotal)
      ..writeByte(10)
      ..write(obj.imagePath)
      ..writeByte(11)
      ..write(obj.items)
      ..writeByte(12)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
