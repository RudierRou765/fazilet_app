import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../prayer_times_repository.dart';
import '../theme.dart';

/// Premium prayer times card widget
/// Displays all 5 daily prayers with Fazilet methodology badge
/// Zero AI-slop: Custom painted, sophisticated shadows, brand-compliant
class PrayerTimesCard extends StatelessWidget {
  final PrayerTimes prayerTimes;
  final String nextPrayer;
  final Duration timeUntilNext;

  const PrayerTimesCard({
    super.key,
    required this.prayerTimes,
    required this.nextPrayer,
    required this.timeUntilNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FaziletTheme.accentPrimary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with next prayer prominence
          _buildHeader(context, isDark),
          const SizedBox(height: 20),
          // Prayer times grid
          _buildPrayerGrid(context, isDark),
          const SizedBox(height: 16),
          // Fazilet methodology badge
          _buildFaziletBadge(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final nextTime = prayerTimes.timeForPrayer(nextPrayer);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FaziletTheme.accentPrimary,
            FaziletTheme.accentPrimary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Prayer',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${timeUntilNext.inHours}h ${timeUntilNext.inMinutes.remainder(60)}m',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _capitalize(nextPrayer),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 48,
              color: Colors.white,
              fontWeight: FontWeight.w300,
              height: 1.0,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerGrid(BuildContext context, bool isDark) {
    final prayers = [
      ('fajr', 'Fajr', prayerTimes.fajr, FaziletTheme.accentPrimary),
      ('dhuhr', 'Dhuhr', prayerTimes.dhuhr, FaziletTheme.accentSecondary),
      ('asr', 'Asr', prayerTimes.asr, FaziletTheme.accentTertiary),
      ('maghrib', 'Maghrib', prayerTimes.maghrib, const Color(0xFF141413)),
      ('isha', 'Isha', prayerTimes.isha, const Color(0xFF141413)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: prayers.map((prayer) {
          final isNext = prayer.$1 == nextPrayer.toLowerCase();
          final color = prayer.$4 as Color;
          final time = prayer.$3 as DateTime;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isNext
                  ? color.withOpacity(0.08)
                  : (isDark ? const Color(0xFF1a1a1a) : const Color(0xFFfaf9f5)),
              borderRadius: BorderRadius.circular(12),
              border: isNext
                  ? Border.all(color: color.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isNext ? color : color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      prayer.$2,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            isNext ? FontWeight.w600 : FontWeight.w400,
                        color: isNext
                            ? color
                            : (isDark
                                ? Colors.white70
                                : const Color(0xFF141413)),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight:
                        isNext ? FontWeight.w600 : FontWeight.w400,
                    color: isNext
                        ? color
                        : (isDark ? Colors.white70 : const Color(0xFF141413)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaziletBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: FaziletTheme.accentPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FaziletTheme.accentPrimary.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: FaziletTheme.accentPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            'Fazilet Methodology',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: FaziletTheme.accentPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '• Per-prayer offsets applied',
            style: GoogleFonts.lora(
              fontSize: 12,
              color: FaziletTheme.accentPrimary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
