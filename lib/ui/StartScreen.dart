import 'package:flutter/material.dart';
import 'package:mysongbook_flutter/data/ViewModel.dart';
import 'package:mysongbook_flutter/data/Verse.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late Verse? currentVerse;

  @override
  void initState() {
    super.initState();
    currentVerse = ViewModel.getVerse();
  }

  void _refreshVerse() {
    setState(() {
      currentVerse = ViewModel.getVerse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 16,
                  left: 48,
                  right: 48,
                ),
                child: PageView(
                  children: const [
                  ], // Add your pages here
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 1,
                    color: const Color(0xFF66B7E5),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    onTap: _refreshVerse,
                    child: Text(
                      currentVerse?.text ?? 'Loading...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'SansSerif',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentVerse?.place ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 1,
                    color: const Color(0xFF66B7E5),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'MYSONGBOOK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: const Color(0x1E001F2A),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.settings, size: 30),
                  label: const Text('Ustawienia'),
                  onPressed: () {},
                ),
                TextButton.icon(
                  icon: const Icon(Icons.report, size: 30),
                  label: const Text('Zgłoś'),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}