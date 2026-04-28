import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../book_engine_service.dart';

/// Book Reader Screen — Distraction-free reading with typography controls
/// Zero AI-slop: Elegant, custom decorated, generous whitespace
/// Uses Lora font for body text as per brand-guidelines
class BookReaderScreen extends StatefulWidget {
  final String bookFilename;

  const BookReaderScreen({
    super.key,
    required this.bookFilename,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final BookEngineService _engine = BookEngineService();
  final ScrollController _scrollController = ScrollController();

  List<BookFragment> _fragments = [];
  BookMeta? _bookMeta;
  bool _isLoading = true;
  bool _showControls = true;

  // Typography controls
  double _fontSize = 16.0;
  static const double _minFontSize = 12.0;
  static const double _maxFontSize = 24.0;
  static const double _fontSizeStep = 2.0;

  // Reading progress
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBook();
    _scrollController.addListener(_updateProgress);

    // TODO: Show AdMob Interstitial Ad on first open
    // _showInterstitialAd();
  }

  Future<void> _loadBook() async {
    try {
      final meta = await _engine.getBookMeta(widget.bookFilename);
      final fragments = await _engine.getBookContent(widget.bookFilename);

      setState(() {
        _bookMeta = meta;
        _fragments = fragments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load book: $e',
              style: GoogleFonts.lora(),
            ),
          ),
        );
      }
    }
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    setState(() {
      _readingProgress = maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
    });
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + _fontSizeStep).clamp(_minFontSize, _maxFontSize);
    });
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - _fontSizeStep).clamp(_minFontSize, _maxFontSize);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _showInterstitialAd() {
    // TODO: Implement AdMob Interstitial Ad
    // InterstitialAd.load(
    //   adUnitId: '<interstitial-ad-unit-id>',
    //   request: AdRequest(),
    //   adLoadCallback: InterstitialAdLoadCallback(
    //     onAdLoaded: (ad) {
    //       ad.show();
    //       ad.fullScreenContentCallback = FullScreenContentCallback(
    //         onAdDismissedFullScreenContent: (ad) {
    //           ad.dispose();
    //         },
    //       );
    //     },
    //     onAdFailedToLoad: (error) {
    //       print('Interstitial ad failed to load: $error');
    //     },
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFfaf9f5),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main content
            _isLoading
                ? _buildLoadingState(isDark)
                : _fragments.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildReaderContent(isDark),

            // Top controls (app bar)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showControls ? 0 : -120,
              left: 0,
              right: 0,
              child: _buildTopBar(context, isDark),
            ),

            // Bottom controls
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildBottomBar(context, isDark),
            ),

            // Progress indicator
            if (_showControls)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                bottom: 80,
                left: 0,
                right: 0,
                height: 3,
                child: LinearProgressIndicator(
                  value: _readingProgress,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FaziletTheme.accentPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1a1a1a).withOpacity(0.95)
            : const Color(0xFFfaf9f5).withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white70 : FaziletTheme.darkPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bookMeta?.title ?? widget.bookFilename,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_bookMeta != null)
                  Text(
                    '${_bookMeta!.language} • v${_bookMeta!.version}',
                    style: GoogleFonts.lora(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // TODO: Open search
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FaziletTheme.accentPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.search_rounded,
                color: FaziletTheme.accentPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        left: 24,
        right: 24,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1a1a1a).withOpacity(0.95)
            : const Color(0xFFfaf9f5).withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Decrease font
          GestureDetector(
            onTap: _decreaseFontSize,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.remove_rounded,
                color: _fontSize <= _minFontSize
                    ? (isDark ? Colors.white24 : Colors.black26)
                    : (isDark ? Colors.white70 : FaziletTheme.darkPrimary),
                size: 20,
              ),
            ),
          ),

          // Font size indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: FaziletTheme.accentPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_fontSize.toInt()}pt',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FaziletTheme.accentPrimary,
              ),
            ),
          ),

          // Increase font
          GestureDetector(
            onTap: _increaseFontSize,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_rounded,
                color: _fontSize >= _maxFontSize
                    ? (isDark ? Colors.white24 : Colors.black26)
                    : (isDark ? Colors.white70 : FaziletTheme.darkPrimary),
                size: 20,
              ),
            ),
          ),

          // Chapter navigation (placeholder)
          GestureDetector(
            onTap: () {
              // TODO: Show chapter navigation
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FaziletTheme.accentSecondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: FaziletTheme.accentSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderContent(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: 180,
        left: 24,
        right: 24,
      ),
      itemCount: _fragments.length,
      itemBuilder: (context, index) {
        final fragment = _fragments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            fragment.content,
            style: GoogleFonts.lora(
              fontSize: _fontSize,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : FaziletTheme.darkPrimary,
              height: 1.8, // Generous line height for readability
              letterSpacing: 0.3,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: FaziletTheme.accentPrimary,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No content found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateProgress);
    _scrollController.dispose();
    super.dispose();
  }
}
