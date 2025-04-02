import 'package:hive/hive.dart';

part 'Verse.g.dart';

@HiveType(typeId: 1)
class Verse extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String place;

  @HiveField(2)
  final String text;

  Verse({
    required this.id,
    required this.place,
    required this.text,
  });
}