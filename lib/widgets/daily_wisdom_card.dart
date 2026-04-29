import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../daily_content_service.dart';

/// Premium Glassmorphic Daily Wisdom Card
/// Designed for the HomeScreen to showcase Takvim Arkası and daily verses
/// Zero AI-Slop: BackdropFilter effects, Lora body text, elegant Fazilet palette
class DailyWisdomCard extends StatelessWidget {
  final DailyContent content;

  const DailyWisdomCard({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Glassmorphic background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : FaziletTheme.accentPrimary.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : FaziletTheme.accentPrimary.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Content padding
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Title and Type Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: FaziletTheme.accentSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (content.hijriDate != null)
                            Text(
                              content.hijriDate!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: FaziletTheme.accentPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForType(content.type),
                          size: 18,
                          color: FaziletTheme.accentPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Main content text
                  Text(
                    content.content,
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      height: 1.6,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer: Source and "Read More"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '— ${content.source}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to full wisdom screen
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: FaziletTheme.accentPrimary.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Read More',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FaziletTheme.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(DailyContentType type) {
    switch (type) {
      case DailyContentType.ayah:
        return Icons.auto_stories_rounded;
      case DailyContentType.hadith:
        return Icons.format_quote_rounded;
      case DailyContentType.wisdom:
        return Icons.lightbulb_outline_rounded;
    }
  }
}
