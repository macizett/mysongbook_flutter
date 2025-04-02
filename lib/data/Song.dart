import 'package:hive/hive.dart';

part 'Song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final String textNormalized;

  @HiveField(3)
  final int number;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final int songbook;

  @HiveField(6)
  final int strophes;

  @HiveField(7)
  bool isFavorite;

  Song({
    required this.id,
    required this.text,
    required this.textNormalized,
    required this.number,
    required this.title,
    required this.songbook,
    required this.strophes,
    this.isFavorite = false,
  });
}