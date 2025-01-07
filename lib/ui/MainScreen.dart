import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ViewPager equivalent
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 16,
                  left: 48,
                  right: 48,
                ),
                child: PageView(
                  // Add your pages here
                ),
              ),
            ),

            // Verse Layout
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 1,
                    color: const Color(0xFF66B7E5),
                  ),
                ),
                const SizedBox(height: 8),

                // Verse Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    child: Text(
                      '', // Your verse text
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'SansSerif',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {}, // Add your click handler
                  ),
                ),
                const SizedBox(height: 6),

                // Verse Place
                Text(
                  '', // Your verse place
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),

                // Bottom Line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 1,
                    color: const Color(0xFF66B7E5),
                  ),
                ),
                const SizedBox(height: 12),

                // App Name
                Text(
                  'MSB', // Replace with your app name
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Final Line
                Container(
                  height: 1,
                  color: const Color(0x1E001F2A),
                ),
              ],
            ),

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(color: Color(0xFF888686)),
                  ),
                  icon: const Icon(Icons.settings, size: 30),
                  label: const Text('Ustawienia'),
                  onPressed: () {},
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(color: Color(0xFF888686)),
                  ),
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