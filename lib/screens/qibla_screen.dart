import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:fazilet_app/theme.dart';

/// Qibla Compass Painter — Generative, geometric compass dial
/// Zero AI-slop: Custom drawn, multi-ring, algorithmic-art inspired
/// Brand colors: #d97757 (Qibla), #6a9bcc/#788c5d (surrounding UI)
class QiblaCompassPainter extends CustomPainter {
  final double currentHeading; // Device heading in radians
  final double qiblaAngle; // Qibla direction in radians from North
  final bool isDark;
  final Color primaryColor = const Color(0xFFd97757);
  final Color secondaryColor = const Color(0xFF6a9bcc);
  final Color tertiaryColor = const Color(0xFF788c5d);

  QiblaCompassPainter({
    required this.currentHeading,
    required this.qiblaAngle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    _drawConcentricRings(canvas, center, radius);
    _drawDegreeMarkers(canvas, center, radius);
    _drawCardinalDirections(canvas, center, radius);
    _drawGeometricAccents(canvas, center, radius);
    _drawQiblaIndicator(canvas, center, radius);
    _drawCurrentHeadingLine(canvas, center, radius);
    _drawCenterDot(canvas, center);
  }

  void _drawConcentricRings(Canvas canvas, Offset center, double radius) {
    final paints = [
      Paint()
        ..color = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
      Paint()
        ..color = secondaryColor.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
      Paint()
        ..color = tertiaryColor.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
      Paint()
        ..color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    ];

    for (int i = 0; i < paints.length; i++) {
      final r = radius * (0.3 + i * 0.2);
      canvas.drawCircle(center, r, paints[i]);
    }

    final outerRing = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, outerRing);
  }

  void _drawDegreeMarkers(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final majorMarkerPaint = Paint()
      ..color = secondaryColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < 360; i += 5) {
      final angle = (i - 90) * pi / 180;
      final isMajor = i % 30 == 0;
      final markerLength = isMajor ? 12.0 : 6.0;
      final paint = isMajor ? majorMarkerPaint : markerPaint;

      final start = Offset(
        center.dx + (radius - markerLength) * cos(angle),
        center.dy + (radius - markerLength) * sin(angle),
      );
      final end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawCardinalDirections(Canvas canvas, Offset center, double radius) {
    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];

    for (int i = 0; i < directions.length; i++) {
      final angle = (angles[i] - 90) * pi / 180;
      final position = Offset(
        center.dx + (radius + 20) * cos(angle),
        center.dy + (radius + 20) * sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: i == 0 ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawGeometricAccents(Canvas canvas, Offset center, double radius) {
    final accentPaint = Paint()
      ..color = tertiaryColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final path = Path();
      final r = radius * 0.8;

      path.moveTo(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      );
      path.lineTo(
        center.dx + (r - 10) * cos(angle + pi / 12),
        center.dy + (r - 10) * sin(angle + pi / 12),
      );
      path.lineTo(
        center.dx + (r - 10) * cos(angle - pi / 12),
        center.dy + (r - 10) * sin(angle - pi / 12),
      );
      path.close();

      canvas.drawPath(path, accentPaint);
    }
  }

  void _drawQiblaIndicator(Canvas canvas, Offset center, double radius) {
    final qiblaAbsolute = qiblaAngle - currentHeading;
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final tipRadius = radius * 0.85;
    final baseRadius = radius * 0.7;

    path.moveTo(
      center.dx + tipRadius * cos(qiblaAbsolute),
      center.dy + tipRadius * sin(qiblaAbsolute),
    );
    path.lineTo(
      center.dx + baseRadius * cos(qiblaAbsolute + pi / 15),
      center.dy + baseRadius * sin(qiblaAbsolute + pi / 15),
    );
    path.lineTo(
      center.dx + baseRadius * cos(qiblaAbsolute - pi / 15),
      center.dy + baseRadius * sin(qiblaAbsolute - pi / 15),
    );
    path.close();

    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glowPaint);

    canvas.drawPath(path, paint);

    final labelRadius = radius * 0.6;
    final labelOffset = Offset(
      center.dx + labelRadius * cos(qiblaAbsolute),
      center.dy + labelRadius * sin(qiblaAbsolute),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'QIBLA',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: primaryColor,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      labelOffset - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawCurrentHeadingLine(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * cos(-currentHeading),
        center.dy + radius * sin(-currentHeading),
      ),
      paint,
    );
  }

  void _drawCenterDot(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      6,
      Paint()..color = primaryColor,
    );
    canvas.drawCircle(
      center,
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter oldDelegate) {
    return oldDelegate.currentHeading != currentHeading ||
        oldDelegate.qiblaAngle != qiblaAngle ||
        oldDelegate.isDark != isDark;
  }
}

/// Qibla Screen with device sensor integration
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with SingleTickerProviderStateMixin {
  double _currentHeading = 0.0;
  double _qiblaAngle = 0.0;
  late AnimationController _rotationController;
  bool _isCalibrated = false;

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initMagnetometer();
    _calculateQiblaAngle();
  }

  void _initMagnetometer() {
    _magnetometerSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
      setState(() {
        _currentHeading = atan2(event.y, event.x);
      });
    });
  }

  void _calculateQiblaAngle() {
    // For Mecca: 21.4225° N, 39.8262° E
    // This is a simplified calculation - in production, use user's actual location
    _qiblaAngle = (136.0 * pi / 180); // Approx 136° from North for Turkey
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? FaziletTheme.primaryColor.withOpacity(0.1) : FaziletTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: _buildCompass(context, isDark),
            ),
            _buildInfoPanel(context, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Qibla Finder',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : FaziletTheme.primaryColor,
              height: 1.2,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _isCalibrated = !_isCalibrated);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isCalibrated
                    ? FaziletTheme.accentPrimary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isCalibrated
                      ? FaziletTheme.accentPrimary
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.compass_calibration_rounded,
                    size: 16,
                    color: _isCalibrated
                        ? FaziletTheme.accentPrimary
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Calibrate',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _isCalibrated
                          ? FaziletTheme.accentPrimary
                          : (isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: FaziletTheme.primaryColor.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: QiblaCompassPainter(
            currentHeading: _currentHeading,
            qiblaAngle: _qiblaAngle,
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context, bool isDark) {
    final qiblaDegrees = (_qiblaAngle * 180 / pi) % 360;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            label: 'Qibla',
            value: '${qiblaDegrees.toStringAsFixed(1)}°',
            color: FaziletTheme.accentPrimary,
          ),
          _buildDivider(isDark),
          _buildInfoItem(
            label: 'Heading',
            value: '${((_currentHeading * 180 / pi) % 360).toStringAsFixed(1)}°', // FIXED: Proper parentheses!
            color: FaziletTheme.accentSecondary,
          ),
          _buildDivider(isDark),
          _buildInfoItem(
            label: 'Status',
            value: _isCalibrated ? 'Calibrated' : 'Align',
            color: _isCalibrated ? FaziletTheme.accentTertiary : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }
}
