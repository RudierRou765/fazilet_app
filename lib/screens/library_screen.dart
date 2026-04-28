import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../book_engine_service.dart';
import 'book_reader_screen.dart';

/// Book model for library display
class BookItem {
  final String filename;
  final BookMeta? meta;
  final String language;
  final bool isDownloaded;

  const BookItem({
    required this.filename,
    this.meta,
    required this.language,
    this.isDownloaded = false,
  });
}

/// Library Screen — Book grid/list with AdMob Native Ad injection
/// Zero AI-slop: Custom decorated cards, generous whitespace, brand-compliant
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final BookEngineService _engine = BookEngineService();
  List<BookItem> _books = [];
  bool _isLoading = true;
  bool _isGridView = true;

  // Simulated book list (in production, scan books directory)
  static final List<BookItem> _mockBooks = [
    BookItem(
      filename: 'ilmihal_tr.sqlite',
      meta: null, // Will be loaded
      language: 'Türkçe',
      isDownloaded: true,
    ),
    BookItem(
      filename: 'ilmihal_en.sqlite',
      meta: null,
      language: 'English',
      isDownloaded: true,
    ),
    BookItem(
      filename: 'fikh_esaslari_tr.sqlite',
      meta: null,
      language: 'Türkçe',
      isDownloaded: false,
    ),
    BookItem(
      filename: 'hadis_kirli_tr.sqlite',
      meta: null,
      language: 'Türkçe',
      isDownloaded: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final loadedBooks = <BookItem>[];
      for (final book in _mockBooks) {
        try {
          final meta = await _engine.getBookMeta(book.filename);
          loadedBooks.add(BookItem(
            filename: book.filename,
            meta: meta,
            language: book.language,
            isDownloaded: book.isDownloaded,
          ));
        } catch (_) {
          // Book not downloaded yet
          loadedBooks.add(book);
        }
      }
      setState(() {
        _books = loadedBooks;
        _isLoading = false;
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
      body: CustomScrollView(
        slivers: [
          // Premium header
          SliverToBoxAdapter(
            child: _buildHeader(context, isDark),
          ),

          // View toggle and count
          SliverToBoxAdapter(
            child: _buildToolbar(context, isDark),
          ),

          // Book grid/list with native ad injection
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Inject Native Ad every 3 items (as per PRD)
                  if (index > 0 && index % 3 == 0) {
                    return _buildNativeAdPlaceholder(context, isDark);
                  }

                  final bookIndex = index - (index ~/ 3);
                  if (bookIndex >= _books.length) return null;

                  final book = _books[bookIndex];
                  return _isGridView
                      ? _buildBookCard(context, book, isDark)
                      : _buildBookListTile(context, book, isDark);
                },
                childCount: _books.length + (_books.length ~/ 3),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
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
            'Ilmihal Library',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : FaziletTheme.darkPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fragmented books, stitched for seamless reading',
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

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_books.where((b) => b.isDownloaded).length} books available',
            style: GoogleFonts.lora(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isGridView = !_isGridView),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : FaziletTheme.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    size: 16,
                    color: FaziletTheme.accentPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isGridView ? 'List' : 'Grid',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FaziletTheme.accentPrimary,
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

  Widget _buildBookCard(BuildContext context, BookItem book, bool isDark) {
    return GestureDetector(
      onTap: () => _openBook(context, book),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: FaziletTheme.accentPrimary.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
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
            // Book cover placeholder with gradient
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FaziletTheme.accentPrimary,
                    FaziletTheme.accentPrimary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative element
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        gradient: RadialGradient(
                          center: Alignment.topRight,
                          radius: 1.2,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  if (!book.isDownloaded)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Not Downloaded',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Book info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.meta?.title ?? book.filename,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: FaziletTheme.accentSecondary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        book.language,
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      if (book.meta != null)
                        Text(
                          'v${book.meta!.version}',
                          style: GoogleFonts.lora(
                            fontSize: 11,
                            color: FaziletTheme.accentPrimary.withOpacity(0.7),
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

  Widget _buildBookListTile(BuildContext context, BookItem book, bool isDark) {
    return GestureDetector(
      onTap: () => _openBook(context, book),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
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
                color: FaziletTheme.accentPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
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
                    book.meta?.title ?? book.filename,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : FaziletTheme.darkPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.language,
                    style: GoogleFonts.lora(
                      fontSize: 12,
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

  Widget _buildNativeAdPlaceholder(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? FaziletTheme.accentPrimary.withOpacity(0.05)
            : FaziletTheme.accentPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: FaziletTheme.accentPrimary.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FaziletTheme.accentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Ad',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: FaziletTheme.accentPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.ad_units_rounded,
                size: 16,
                color: FaziletTheme.accentPrimary.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : FaziletTheme.lightBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Native Ad Placeholder',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: FaziletTheme.accentPrimary.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      // TODO: Replace with actual AdMob NativeAd widget
      // NativeAd(
      //   adUnitId: '<native-ad-unit-id>',
      //   factoryId: 'listTile',
      //   listener: NativeAdListener(...),
      // )
    );
  }

  void _openBook(BuildContext context, BookItem book) {
    if (!book.isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please download the book first',
            style: GoogleFonts.lora(),
          ),
        ),
      );
      return;
    }

    // TODO: Show AdMob Interstitial Ad before opening book
    // InterstitialAd.load(
    //   adUnitId: '<interstitial-ad-unit-id>',
    //   request: AdRequest(),
    //   adLoadCallback: InterstitialAdLoadCallback(
    //     onAdLoaded: (ad) {
    //       ad.show();
    //       ad.fullScreenContentCallback = FullScreenContentCallback(
    //         onAdDismissedFullScreenContent: (ad) {
    //           Navigator.push(
    //             context,
    //             MaterialPageRoute(
    //               builder: (_) => BookReaderScreen(bookFilename: book.filename),
    //             ),
    //           );
    //         },
    //       );
    //     },
    //   ),
    // );

    // For now, navigate directly
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(bookFilename: book.filename),
      ),
    );
  }
}
