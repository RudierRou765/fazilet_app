import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fazilet_app/theme.dart';
import 'package:fazilet_app/main.dart';
import 'package:fazilet_app/prayer_times_repository.dart';
import 'package:fazilet_app/database_provider.dart';

/// Premium district selector bottom sheet
/// Features: search, hierarchical display, offline SQLite integration
/// Zero AI-slop: Custom painted, sophisticated shadows, brand-compliant
class DistrictSelectorSheet extends StatefulWidget {
  final int? currentDistrictId;

  const DistrictSelectorSheet({
    super.key,
    this.currentDistrictId,
  });

  @override
  State<DistrictSelectorSheet> createState() => _DistrictSelectorSheetState();

  /// Show the bottom sheet
  static Future<int?> show(
    BuildContext context, {
    int? currentDistrictId,
  }) async {
    return await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DistrictSelectorSheet(
        currentDistrictId: currentDistrictId,
      ),
    );
  }
}

class _DistrictSelectorSheetState extends State<DistrictSelectorSheet> {
  final PrayerTimesRepository _repository = PrayerTimesRepository();
  final TextEditingController _searchController = TextEditingController();

  List<District> _districts = [];
  List<District> _filteredDistricts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  Map<String, Map<String, List<District>>> _groupedDistricts = {};

  @override
  void initState() {
    super.initState();
    _loadDistricts();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterDistricts();
      });
    });
  }

  Future<void> _loadDistricts() async {
    try {
      final districts = await _repository.getAllDistricts();
      setState(() {
        _districts = districts;
        _filterDistricts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterDistricts() {
    if (_searchQuery.isEmpty) {
      _filteredDistricts = _districts;
    } else {
      _filteredDistricts = _districts
          .where((d) =>
              d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    _groupDistricts();
  }

  void _groupDistricts() {
    _groupedDistricts.clear();
    for (final district in _filteredDistricts) {
      final country = district.city ?? 'Unknown';
      final city = district.name;

      _groupedDistricts.putIfAbsent(country, () => {});
      _groupedDistricts[country]!.putIfAbsent(city, () => []).add(district);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandleBar(),
          _buildHeader(context, isDark),
          _buildSearchBar(context, isDark),
          Flexible(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredDistricts.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : _buildDistrictList(context, isDark),
          ),
          SizedBox(height: mediaQuery.padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select District',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : FaziletTheme.primaryColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FaziletTheme.accentPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredDistricts.length}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FaziletTheme.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : FaziletTheme.lightBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.lora(
          fontSize: 15,
          color: isDark ? Colors.white : FaziletTheme.primaryColor,
        ),
        decoration: InputDecoration(
          hintText: 'Search districts...',
          hintStyle: GoogleFonts.lora(
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: FaziletTheme.accentPrimary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictList(BuildContext context, bool isDark) {
    if (_searchQuery.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredDistricts.length,
        itemBuilder: (context, index) {
          final district = _filteredDistricts[index];
          final isSelected = district.districtId == widget.currentDistrictId;

          return _buildDistrictTile(
            context: context,
            district: district,
            isSelected: isSelected,
            isDark: isDark,
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _groupedDistricts.length,
      itemBuilder: (context, index) {
        final countryEntry = _groupedDistricts.entries.elementAt(index);
        return _buildCountrySection(
          context: context,
          countryName: 'Turkey (${countryEntry.key})',
          cities: countryEntry.value,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildCountrySection({
    required BuildContext context,
    required String countryName,
    required Map<String, List<District>> cities,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: FaziletTheme.accentPrimary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                countryName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FaziletTheme.accentPrimary,
                ),
              ),
            ],
          ),
        ),
        ...cities.entries.map((cityEntry) {
          final cityName = cityEntry.key;
          final districts = cityEntry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 8, bottom: 4),
                child: Text(
                  cityName,
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
              ...districts.map((district) {
                final isSelected =
                    district.districtId == widget.currentDistrictId;
                return _buildDistrictTile(
                  context: context,
                  district: district,
                  isSelected: isSelected,
                  isDark: isDark,
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDistrictTile({
    required BuildContext context,
    required District district,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(district.districtId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? FaziletTheme.accentPrimary.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: FaziletTheme.accentPrimary.withOpacity(0.3),
                  width: 1.5,
                )
              : Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? FaziletTheme.accentPrimary
                    : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : FaziletTheme.lightBackground),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: isSelected
                    ? Colors.white
                    : FaziletTheme.accentPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    district.name, // FIXED: was district.cityName
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? FaziletTheme.accentPrimary
                          : (isDark ? Colors.white : FaziletTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${district.name} • ${district.latitude.toStringAsFixed(3)}, ${district.longitude.toStringAsFixed(3)}', // FIXED: was district.cityName
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: FaziletTheme.accentPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: FaziletTheme.accentPrimary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No districts found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
