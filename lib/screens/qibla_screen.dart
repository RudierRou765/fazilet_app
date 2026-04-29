import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:fazilet_app/theme.dart';
import 'package:fazilet_app/models/district.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<MagnetometerEvent>? _subscription;
  double? _currentHeading; // Magnetic heading from North (radians)
  double _qiblaAngle = 0.0; // Qibla bearing from North (radians)
  District? _district;

  @override
  void initState() {
    super.initState();
    _loadLocationAndCalculateQibla();
    _startCompass();
  }

  Future<void> _loadLocationAndCalculateQibla() async {
    final settingsBox = Hive.box('settings');
    final districtId = settingsBox.get('selectedDistrictId');
    final districtsBox = Hive.box<District>('districts');

    if (districtId != null) {
      _district = districtsBox.get(districtId);
    }

    if (_district == null && districtsBox.isNotEmpty) {
      _district = districtsBox.values.first;
    }

    if (_district != null) {
      setState(() {
        _qiblaAngle = _calculateQiblaAngle(
          _district!.latitude,
          _district!.longitude,
        );
      });
    }
  }

  /// High-precision spherical trigonometry for Qibla bearing
  double _calculateQiblaAngle(double lat, double lng) {
    const kaabaLat = 21.422487 * pi / 180.0;
    const kaabaLng = 39.826206 * pi / 180.0;
    final userLat = lat * pi / 180.0;
    final userLng = lng * pi / 180.0;

    final deltaLng = kaabaLng - userLng;
    final y = sin(deltaLng);
    final x = cos(userLat) * tan(kaabaLat) - sin(userLat) * cos(deltaLng);
    
    return atan2(y, x);
  }

  void _startCompass() {
    _subscription = magnetometerEventStream().listen((event) {
      if (mounted) {
        setState(() {
          // Normalize heading calculation from magnetometer data
          _currentHeading = atan2(event.y, event.x);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  double get _qiblaOffsetDegrees {
    if (_currentHeading == null) return 0.0;
    // Difference between user heading and Qibla bearing
    var offset = (_qiblaAngle - _currentHeading!) * 180 / pi;
    offset = (offset + 180) % 360 - 180;
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    final isAligned = _qiblaOffsetDegrees.abs() < 2.0;

    return Scaffold(
      backgroundColor: FaziletTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Kıble Yönü',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: FaziletTheme.darkPrimary,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              _district?.name ?? 'Konum Seçilmedi',
              style: GoogleFonts.lora(
                fontSize: 16,
                color: FaziletTheme.accentPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            // Premium Compass UI
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow when aligned
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isAligned ? [
                      BoxShadow(
                        color: FaziletTheme.accentPrimary.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ] : [],
                  ),
                ),
                // Compass Rose
                Transform.rotate(
                  angle: -(_currentHeading ?? 0),
                  child: CustomPaint(
                    size: const Size(260, 260),
                    painter: QiblaCompassPainter(
                      qiblaAngle: _qiblaAngle,
                      isAligned: isAligned,
                    ),
                  ),
                ),
                // Kaaba Icon at the center
                Icon(
                  Icons.mosque_rounded,
                  size: 40,
                  color: isAligned ? FaziletTheme.accentPrimary : Colors.grey[400],
                ),
              ],
            ),
            const Spacer(),
            // Alignment Indicator
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isAligned ? 'Kıbleye Yöneldiniz' : 'Telefonu Çevirin',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isAligned ? FaziletTheme.accentPrimary : FaziletTheme.darkPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kıble Açısı: ${(_qiblaAngle * 180 / pi % 360).toStringAsFixed(1)}°',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: (1 - (_qiblaOffsetDegrees.abs() / 180)).clamp(0, 1),
                    backgroundColor: Colors.grey[100],
                    color: isAligned ? FaziletTheme.accentPrimary : Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Premium Qibla Painter (Zero AI-Slop)
class QiblaCompassPainter extends CustomPainter {
  final double qiblaAngle;
  final bool isAligned;

  QiblaCompassPainter({required this.qiblaAngle, required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background ring
    final ringPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);

    // Draw cardinal points
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const cardinals = {'K': 0, 'D': 90, 'G': 180, 'B': 270};
    for (var entry in cardinals.entries) {
      final angle = entry.value * pi / 180;
      final offset = Offset(
        center.dx + (radius - 25) * sin(angle),
        center.dy - (radius - 25) * cos(angle),
      );

      textPainter.text = TextSpan(
        text: entry.key,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: entry.key == 'K' ? Colors.red : Colors.grey[400],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, offset - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Draw Qibla Pointer
    final qiblaPaint = Paint()
      ..color = isAligned ? FaziletTheme.accentPrimary : Colors.orange
      ..style = PaintingStyle.fill;

    final qiblaPath = Path();
    final qiblaTip = Offset(
      center.dx + (radius - 10) * sin(qiblaAngle),
      center.dy - (radius - 10) * cos(qiblaAngle),
    );
    
    // Draw an arrow pointing to Qibla
    qiblaPath.moveTo(qiblaTip.dx, qiblaTip.dy);
    qiblaPath.lineTo(
      center.dx + (radius - 40) * sin(qiblaAngle - 0.2),
      center.dy - (radius - 40) * cos(qiblaAngle - 0.2),
    );
    qiblaPath.lineTo(
      center.dx + (radius - 30) * sin(qiblaAngle),
      center.dy - (radius - 30) * cos(qiblaAngle),
    );
    qiblaPath.lineTo(
      center.dx + (radius - 40) * sin(qiblaAngle + 0.2),
      center.dy - (radius - 40) * cos(qiblaAngle + 0.2),
    );
    qiblaPath.close();
    
    canvas.drawPath(qiblaPath, qiblaPaint);
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter oldDelegate) => 
    oldDelegate.qiblaAngle != qiblaAngle || oldDelegate.isAligned != isAligned;
}
