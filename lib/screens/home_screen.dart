import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:fazilet_app/theme.dart';
import 'package:fazilet_app/models/district.dart';
import 'package:fazilet_app/models/prayer_time.dart';
import 'package:fazilet_app/screens/prayer_times_screen.dart';
import 'package:fazilet_app/screens/qibla_screen.dart';
import 'package:fazilet_app/screens/settings_screen.dart';
import 'package:fazilet_app/widgets/prayer_times_card.dart';
import 'package:fazilet_app/widgets/islamic_pattern_painter.dart';
import 'package:fazilet_app/widgets/loading_widget.dart';
import 'package:fazilet_app/screens/library_screen.dart';
import 'package:fazilet_app/prayer_times_repository.dart' as repo;

import 'package:fazilet_app/widgets/daily_wisdom_card.dart';
import 'package:fazilet_app/daily_content_service.dart';
import 'package:fazilet_app/widgets/district_selector_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<District> _districtsBox;
  District? _selectedDistrict;
  PrayerTime? _nextPrayer;
  repo.PrayerTimes? _prayerTimes;
  
  // Daily Wisdom Content
  final DailyContentService _wisdomService = DailyContentService();
  List<DailyContent> _dailyContent = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadDailyWisdom();
  }

  Future<void> _loadDailyWisdom() async {
    final content = await _wisdomService.getTodayContent();
    if (mounted) {
      setState(() => _dailyContent = content);
    }
  }

  final repo.PrayerTimesRepository _repo = repo.PrayerTimesRepository();

  Future<void> _initializeData() async {
    _districtsBox = Hive.box<District>('districts');
    await _loadSelectedDistrict();
  }

  Future<void> _loadSelectedDistrict() async {
    final settingsBox = Hive.box('settings');
    final districtId = settingsBox.get('selectedDistrictId');

    if (districtId != null) {
      _selectedDistrict = _districtsBox.get(districtId);
    }

    if (_selectedDistrict == null && _districtsBox.isNotEmpty) {
      _selectedDistrict = _districtsBox.values.first;
      await settingsBox.put('selectedDistrictId', _selectedDistrict!.id);
    }

    if (_selectedDistrict != null) {
      await _calculatePrayerTimes();
    }
  }

  Future<void> _calculatePrayerTimes() async {
    if (_selectedDistrict == null) return;

    try {
      final times = await _repo.calculatePrayerTimes(
        districtId: _selectedDistrict!.id,
      );
      
      final next = await _repo.getNextPrayer(
        districtId: _selectedDistrict!.id,
      );

      // Auto-schedule notifications on data refresh
      await _repo.scheduleWeeklyNotifications(_selectedDistrict!.id);

      if (mounted) {
        setState(() {
          _prayerTimes = times;
          _nextPrayer = PrayerTime(
            name: next['prayer'] as String,
            time: DateFormat('HH:mm').format(next['time'] as DateTime),
            date: DateFormat('yyyy-MM-dd').format(next['time'] as DateTime),
          );
        });
      }
    } catch (e) {
      debugPrint('Error calculating prayer times: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Null-check for district to prevent null-safety crashes
    if (_selectedDistrict == null) {
      return const Scaffold(
        body: LoadingWidget(
          message: 'Konum bilgisi yükleniyor...',
        ),
      );
    }

    final district = _selectedDistrict!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, district),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildDateHeader(),
                  ),
                  const SizedBox(height: 16),
                  if (_prayerTimes != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: PrayerTimesCard(
                        prayerTimes: _prayerTimes!,
                        nextPrayer: _nextPrayer?.name ?? 'fajr',
                        timeUntilNext: const Duration(hours: 2), // Placeholder
                      ),
                    ),
                  
                  // Premium Daily Wisdom Cards
                  if (_dailyContent.isNotEmpty)
                    ..._dailyContent.map((c) => DailyWisdomCard(content: c)),
                  
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildQuickActionsHeader(),
                  ),
                ],
              ),
            ),
          ),
          _buildQuickActionsGrid(),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, District district) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          district.city,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FaziletTheme.primaryColor,
                    FaziletTheme.primaryColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // FIXED: Positioned.fill with child: parameter
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.location_on, color: Colors.white),
          onPressed: () async {
            final result = await DistrictSelectorSheet.show(context);
            if (result != null) {
              await Hive.box('settings').put('selectedDistrictId', result);
              await _loadSelectedDistrict();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bugün',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsHeader() {
    return Text(
      'Hızlı Erişim',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'icon': Icons.access_time,
        'label': 'Namaz Vakitleri',
        'route': '/prayer-times',
      },
      {
        'icon': Icons.explore,
        'label': 'Kıble',
        'route': '/qibla',
      },
      {
        'icon': Icons.menu_book,
        'label': 'Kütüphane',
        'route': '/library',
      },
      {
        'icon': Icons.mosque,
        'label': 'Hadis',
        'route': '/hadith',
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Takvim',
        'route': '/calendar',
      },
      {
        'icon': Icons.location_on,
        'label': 'Konum',
        'route': '/location',
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        // FIXED: SliverGrid with proper gridDelegate parameter
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final action = actions[index];
            return _buildActionCard(
              context,
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              route: action['route'] as String,
            );
          },
          childCount: actions.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.9,
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          if (route == '/prayer-times') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PrayerTimesScreen(),
              ),
            );
          } else if (route == '/qibla') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const QiblaScreen(),
              ),
            );
          } else if (route == '/library') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LibraryScreen(),
              ),
            );
          } else {
            Navigator.of(context).pushNamed(route);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: FaziletTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
