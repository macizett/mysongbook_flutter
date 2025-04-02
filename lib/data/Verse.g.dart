// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Verse.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VerseAdapter extends TypeAdapter<Verse> {
  @override
  final int typeId = 1;

  @override
  Verse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Verse(
      id: fields[0] as int,
      place: fields[1] as String,
      text: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Verse obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.place)
      ..writeByte(2)
      ..write(obj.text);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
