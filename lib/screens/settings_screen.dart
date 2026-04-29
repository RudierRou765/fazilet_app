import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme.dart';
import '../widgets/district_selector_sheet.dart';
import '../prayer_times_repository.dart';

/// Settings Screen — Premium B2C dashboard with Hive integration
/// Zero AI-slop: Custom toggles, sophisticated shadows, brand-compliant
/// Connects to UserPreferences model (Hive) from PRD
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // User preferences
  int? _selectedDistrictId;
  bool _notificationsEnabled = true;
  String _notificationSoundType = 'standard'; // 'standard' or 'athan'
  String _appLanguage = 'tr';
  String _selectedDistrictName = '...';

  final PrayerTimesRepository _repository = PrayerTimesRepository();

  static const Map<String, String> _supportedLanguages = {
    'tr': 'Türkçe',
    'en': 'English',
    'ar': 'العربية',
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final settingsBox = Hive.box('settings');
    setState(() {
      _selectedDistrictId = settingsBox.get('selectedDistrictId');
      _notificationsEnabled =
          settingsBox.get('notificationsEnabled', defaultValue: true);
      _notificationSoundType =
          settingsBox.get('notificationSoundType', defaultValue: 'standard');
      _appLanguage = settingsBox.get('appLanguage', defaultValue: 'tr');
    });
    await _updateDistrictName();
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final settingsBox = Hive.box('settings');
    await settingsBox.put(key, value);

    // Trigger notification reschedule if relevant
    if (key == 'notificationsEnabled' || key == 'notificationSoundType') {
      if (_selectedDistrictId != null) {
        await _repository.scheduleWeeklyNotifications(_selectedDistrictId!);
      }
    }
  }

  Future<void> _updateDistrictName() async {
    if (_selectedDistrictId != null) {
      try {
        final district =
            await _repository.getDistrictById(_selectedDistrictId!);
        setState(() => _selectedDistrictName = district.name);
      } catch (_) {
        // Handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? FaziletTheme.darkPrimary : FaziletTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Premium header
          SliverToBoxAdapter(
            child: _buildHeader(context, isDark),
          ),

          // Settings sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle(context, 'Location', isDark),
                const SizedBox(height: 12),
                _buildDistrictTile(context, isDark),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Notifications', isDark),
                const SizedBox(height: 12),
                _buildNotificationTile(context, isDark),
                if (_notificationsEnabled) ...[
                  const SizedBox(height: 12),
                  _buildSoundTypeTile(context, isDark),
                ],
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Appearance', isDark),
                const SizedBox(height: 12),
                _buildLanguageTile(context, isDark),
                const SizedBox(height: 12),
                _buildThemeTile(context, isDark),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'About', isDark),
                const SizedBox(height: 12),
                _buildAboutTile(context, isDark),
                const SizedBox(height: 12),
                _buildVersionTile(context, isDark),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : FaziletTheme.darkPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your Fazilet experience',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: FaziletTheme.accentPrimary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDistrictTile(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final selectedId = await DistrictSelectorSheet.show(
          context,
          currentDistrictId: _selectedDistrictId,
        );
        if (selectedId != null) {
          setState(() {
            _selectedDistrictId = selectedId;
            _updateDistrictName();
            _savePreference('selectedDistrictId', selectedId);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: FaziletTheme.accentPrimary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FaziletTheme.accentSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: FaziletTheme.accentSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default District',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDistrictName,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FaziletTheme.accentTertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: FaziletTheme.accentTertiary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Alerts',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _notificationsEnabled
                      ? 'Notifications are active'
                      : 'Notifications are muted',
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    color: _notificationsEnabled
                        ? FaziletTheme.accentTertiary
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ],
            ),
          ),
          _buildCustomToggle(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _savePreference('notificationsEnabled', value);
            },
            activeColor: FaziletTheme.accentTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildSoundTypeTile(BuildContext context, bool isDark) {
    final isAthan = _notificationSoundType == 'athan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: FaziletTheme.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: FaziletTheme.accentPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Sound',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAthan ? 'Athan (Full Recitation)' : 'Standard Alert',
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSoundOption(
                  label: 'Standard',
                  isSelected: !isAthan,
                  onTap: () {
                    setState(() => _notificationSoundType = 'standard');
                    _savePreference('notificationSoundType', 'standard');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSoundOption(
                  label: 'Athan',
                  isSelected: isAthan,
                  onTap: () {
                    setState(() => _notificationSoundType = 'athan');
                    _savePreference('notificationSoundType', 'athan');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoundOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? FaziletTheme.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? FaziletTheme.accentPrimary
                : FaziletTheme.accentPrimary.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : FaziletTheme.accentPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showLanguageSelector(context, isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FaziletTheme.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: FaziletTheme.accentPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Language',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _supportedLanguages[_appLanguage] ?? _appLanguage,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Theme is system-controlled for now
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FaziletTheme.accentPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'System',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: FaziletTheme.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to about page
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FaziletTheme.accentSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_rounded,
                color: FaziletTheme.accentSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Fazilet',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Islamic lifestyle & prayer times',
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionTile(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.code_rounded,
              color: Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1.0.0 (Build 1)',
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// CRITICAL: Custom Toggle (Zero AI-Slop, Premium Styling)
  Widget _buildCustomToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 52,
        height: 32,
        decoration: BoxDecoration(
          color: value ? activeColor : (Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Language',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : FaziletTheme.darkPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ..._supportedLanguages.entries.map((entry) {
              final isSelected = entry.key == _appLanguage;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _appLanguage = entry.key;
                    _savePreference('appLanguage', entry.key);
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? FaziletTheme.accentPrimary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: FaziletTheme.accentPrimary
                                .withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        entry.value,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? FaziletTheme.accentPrimary
                              : (isDark
                                  ? Colors.white70
                                  : FaziletTheme.darkPrimary),
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: FaziletTheme.accentPrimary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
