// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as int,
      text: fields[1] as String,
      textNormalized: fields[2] as String,
      number: fields[3] as int,
      title: fields[4] as String,
      songbook: fields[5] as int,
      strophes: fields[6] as int,
      isFavorite: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.textNormalized)
      ..writeByte(3)
      ..write(obj.number)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.songbook)
      ..writeByte(6)
      ..write(obj.strophes)
      ..writeByte(7)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
