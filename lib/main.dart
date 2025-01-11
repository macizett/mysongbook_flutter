import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:mysongbook_flutter/data/GithubFilesManager.dart';
import 'dart:ui' as ui;

import 'package:mysongbook_flutter/ui/MainScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MySongbook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF014262)),
        useMaterial3: true,
      ),
      // Remove the const keyword here since we're using a runtime value
      home: GithubFilesScreen(languageCode: ui.window.locale.languageCode),

      //GithubFilesScreen(languageCode: ui.window.locale.languageCode)
    );
  }
}
