import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? FaziletTheme.darkPrimary : FaziletTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Prayer Times',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Detailed Prayer Times coming soon...',
          style: GoogleFonts.lora(
            fontSize: 18,
            color: isDark ? Colors.white70 : FaziletTheme.darkPrimary,
          ),
        ),
      ),
    );
  }
}
