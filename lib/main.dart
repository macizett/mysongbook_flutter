import 'package:flutter/material.dart';
import 'package:mysongbook_flutter/data/GithubFilesManager.dart';
import 'package:mysongbook_flutter/ui/AppTheme.dart';
import 'dart:ui' as ui;
import 'package:mysongbook_flutter/ui/StartScreen.dart';
import 'package:mysongbook_flutter/data/Song.dart';
import 'package:mysongbook_flutter/data/Verse.dart';
import 'package:mysongbook_flutter/data/ViewModel.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(SongAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(VerseAdapter());
  }

  // Initialize boxes
  if (!Hive.isBoxOpen(ViewModel.songsBoxName)) {
    await Hive.openBox<Song>(ViewModel.songsBoxName);
  }
  if (!Hive.isBoxOpen(ViewModel.versesBoxName)) {
    await Hive.openBox<Verse>(ViewModel.versesBoxName);
  }

  // Initialize the database
  await ViewModel.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MySongbook',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: ViewModel.isSongsBoxEmpty()
          ? GithubFilesScreen(languageCode: ui.window.locale.languageCode)
          : const StartScreen(),
    );
  }
}