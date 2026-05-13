// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceiptAdapter extends TypeAdapter<Receipt> {
  @override
  final int typeId = 0;

  @override
  Receipt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Receipt(
      id: fields[0] as String,
      storeName: fields[1] as String,
      date: fields[2] as DateTime,
      total: fields[3] as double,
      items: (fields[4] as List).cast<LineItem>(),
      category: fields[5] as String?,
      imagePath: fields[6] as String?,
      rawText: fields[7] as String,
      scannedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Receipt obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storeName)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.total)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.rawText)
      ..writeByte(8)
      ..write(obj.scannedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LineItemAdapter extends TypeAdapter<LineItem> {
  @override
  final int typeId = 1;

  @override
  LineItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LineItem(
      name: fields[0] as String,
      price: fields[1] as double,
      quantity: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LineItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
