import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../prayer_times_repository.dart';
import '../../database_provider.dart';
import '../widgets/prayer_times_card.dart';

/// Home Dashboard Screen
/// Premium B2C interface with algorithmic-art placeholder, prayer times, and navigation grid
/// Zero AI-slop: Custom decorated, generous negative space, distinctive layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrayerTimesRepository _repository = PrayerTimesRepository();
  PrayerTimes? _prayerTimes;
  String _nextPrayer = 'fajr';
  Duration _timeUntilNext = Duration.zero;
  bool _isLoading = true;
  int? _selectedDistrictId;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      // TODO: Load selected district from Hive storage
      const districtId = 1; // Default to Adalar for demo

      final result = await _repository.getNextPrayer(districtId: districtId);

      District? district;
      if (result['district'] != null) {
        district = result['district'] as District;
      } else {
        district = await _repository.getDistrictById(districtId);
      }

      final allTimes = result['allTimes'] as Map<String, DateTime>?;
      if (allTimes != null && district != null) {
        setState(() {
          _prayerTimes = PrayerTimes(
            fajr: allTimes['fajr']!,
            dhuhr: allTimes['dhuhr']!,
            asr: allTimes['asr']!,
            maghrib: allTimes['maghrib']!,
            isha: allTimes['isha']!,
            district: district!,
          );
          _nextPrayer = result['prayer'] ?? 'fajr';
          _timeUntilNext = result['durationUntil'] ?? Duration.zero;
          _selectedDistrictId = districtId;
          _isLoading = false;
        });
      } else {
        setState(() {
          _prayerTimes = null;
          _isLoading = false;
        });
      }

      // Update countdown timer every minute
      Future.delayed(const Duration(minutes: 1), () {
        if (mounted) _loadPrayerTimes();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? FaziletTheme.darkPrimary : FaziletTheme.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Stunning header with algorithmic-art placeholder
            SliverToBoxAdapter(
              child: _buildHeader(context, isDark),
            ),

            // Prayer times card
            SliverToBoxAdapter(
              child: _isLoading || _prayerTimes == null
                  ? _buildLoadingState()
                  : PrayerTimesCard(
                      prayerTimes: _prayerTimes!,
                      nextPrayer: _nextPrayer,
                      timeUntilNext: _timeUntilNext,
                    ),
            ),

            // Navigation grid label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Explore',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : FaziletTheme.darkPrimary,
                  ),
                ),
              ),
            ),

            // Card-based navigation grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildListDelegate([
                  _buildNavigationCard(
                    context: context,
                    icon: Icons.menu_book_rounded,
                    title: 'Ilmihal\nLibrary',
                    subtitle: 'Islamic texts',
                    color: FaziletTheme.accentPrimary,
                    onTap: () {},
                  ),
                  _buildNavigationCard(
                    context: context,
                    icon: Icons.explore_rounded,
                    title: 'Qibla\nFinder',
                    subtitle: 'Find direction',
                    color: FaziletTheme.accentSecondary,
                    onTap: () {},
                  ),
                  _buildNavigationCard(
                    context: context,
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    color: FaziletTheme.accentTertiary,
                    onTap: () {},
                  ),
                  _buildNavigationCard(
                    context: context,
                    icon: Icons.location_on_rounded,
                    title: 'District\nSelector',
                    subtitle: _prayerTimes?.district?.name ?? 'Select district',
                    color: const Color(0xFF141413),
                    onTap: () => _showDistrictSelector(context),
                  ),
                ]),
              ),
            ),

            // AdMob banner placeholder
            SliverToBoxAdapter(
              child: _buildAdMobPlaceholder(context),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 220,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FaziletTheme.accentPrimary,
            FaziletTheme.accentPrimary.withOpacity(0.85),
            FaziletTheme.accentSecondary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: FaziletTheme.accentPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Algorithmic-art dynamic background placeholder
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Header content
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fazilet',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showDistrictSelector(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _prayerTimes?.district?.name ?? 'Select',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Islamic Prayer Times',
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Next Prayer',
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _capitalize(_nextPrayer),
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_timeUntilNext.inHours}h ${_timeUntilNext.inMinutes.remainder(60)}m',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.lora(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdMobPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      height: 60,
      decoration: BoxDecoration(
        color: isDark
            ? FaziletTheme.accentPrimary.withOpacity(0.05)
            : FaziletTheme.accentPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FaziletTheme.accentPrimary.withOpacity(0.15),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ad_units_rounded,
              size: 18,
              color: FaziletTheme.accentPrimary.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'AdMob Banner Placeholder',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: FaziletTheme.accentPrimary.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      // TODO: Replace with actual AdMob BannerAd widget
      // AdUnit ID: ca-app-pub-8400495729523629~9795620267
      // Use: BannerAd(adUnitId: '...', size: AdSize.banner, ...)
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: FaziletTheme.accentPrimary,
        ),
      ),
    );
  }

  void _showDistrictSelector(BuildContext context) {
    // TODO: Implement bottom sheet
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
