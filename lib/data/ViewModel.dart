import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'Song.dart';
import 'Verse.dart';

class ViewModel {
  static const String songsBoxName = 'songs';
  static const String versesBoxName = 'verses';

  static Future<void> initialize() async {
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Open boxes
    await Hive.openBox<Song>(songsBoxName);
    await Hive.openBox<Verse>(versesBoxName);
  }

  // Database check methods
  static bool isDatabaseEmpty() {
    final songsBox = _getSongsBox();
    final versesBox = _getVersesBox();

    return songsBox.isEmpty && versesBox.isEmpty;
  }

  static bool isSongsBoxEmpty() {
    final songsBox = _getSongsBox();
    return songsBox.isEmpty;
  }

  static bool isVersesBoxEmpty() {
    final versesBox = _getVersesBox();
    return versesBox.isEmpty;
  }

  static Map<int, int> getSongbookCounts() {
    final songsBox = _getSongsBox();
    final Map<int, int> counts = {};

    for (var song in songsBox.values) {
      counts[song.songbook] = (counts[song.songbook] ?? 0) + 1;
    }

    return counts;
  }

  // Songs operations
  static Box<Song> _getSongsBox() => Hive.box<Song>(songsBoxName);
  static Box<Verse> _getVersesBox() => Hive.box<Verse>(versesBoxName);

  // Song operations
  static Future<void> insertSong(Song song) async {
    final box = _getSongsBox();
    await box.add(song);
  }

  static Future<void> insertAllSongs(List<Song> songs) async {
    final box = _getSongsBox();
    await box.addAll(songs);
  }

  static Future<void> updateFavoriteSong(Song song) async {
    await song.save();
  }

  static List<Song> getFavoriteSongs(int songbook) {
    final box = _getSongsBox();
    return box.values
        .where((song) => song.isFavorite && song.songbook == songbook)
        .toList();
  }

  static List<Song> getAllSongsBySongbook(int songbook) {
    final box = _getSongsBox();
    return box.values
        .where((song) => song.songbook == songbook)
        .toList();
  }

  static Song? getSongByNumber(int number, int songbook) {
    final box = _getSongsBox();
    try {
      return box.values.firstWhere(
            (song) => song.number == number && song.songbook == songbook,
      );
    } catch (e) {
      return null;
    }
  }

  static List<Song> searchForPhrase(String searchPhrase, int songbook) {
    final box = _getSongsBox();
    return box.values
        .where((song) =>
    song.songbook == songbook &&
        song.text.toLowerCase().contains(searchPhrase.toLowerCase()))
        .toList();
  }

  static List<Song> searchForPhraseWithoutMarks(String searchPhrase, int songbook) {
    final box = _getSongsBox();
    return box.values
        .where((song) =>
    song.songbook == songbook &&
        song.textNormalized.toLowerCase().contains(searchPhrase.toLowerCase()))
        .toList();
  }

  // Verse operations
  static Future<void> insertAllVerses(List<Verse> verses) async {
    final box = _getVersesBox();
    await box.addAll(verses);
  }

  static Verse? getVerse() {
    final box = _getVersesBox();
    final random = Random();
    int randomNumber = random.nextInt(38)+1;
    try {
      return box.values.firstWhere(
            (verse) => verse.id == randomNumber,
      );
    } catch (e) {
      return null;
    }
  }

  // Cleanup
  static Future<void> closeDatabase() async {
    await Hive.close();
  }
}