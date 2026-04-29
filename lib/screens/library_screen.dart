import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../book_engine_service.dart';
import '../services/download_service.dart';
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
  final LibraryManager _libraryManager = LibraryManager();
  final DownloadService _downloadService = DownloadService();

  List<LibraryBook> _books = [];
  List<LibraryBook> _filteredBooks = [];
  bool _isGridView = true;

  // Filtering state
  String? _selectedLanguage;
  Madhhab? _selectedMadhhab;
  final Map<String, double> _downloadProgress = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadBooks() {
    setState(() {
      _books = _libraryManager.allBooks;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredBooks = _books.where((book) {
        final matchesLanguage =
            _selectedLanguage == null || book.language == _selectedLanguage;
        final matchesMadhhab =
            _selectedMadhhab == null || book.madhhab == _selectedMadhhab;
        return matchesLanguage && matchesMadhhab;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? FaziletTheme.darkPrimary : FaziletTheme.lightBackground,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Premium header
          SliverToBoxAdapter(
            child: _buildHeader(context, isDark),
          ),

          // View toggle and count
          SliverToBoxAdapter(
            child: _buildFilterChips(context, isDark),
          ),

          SliverToBoxAdapter(
            child: _buildToolbar(context, isDark),
          ),

          // Book grid/list with native ad injection
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Inject Native Ad every 5 items (less aggressive than 3)
                  if (index > 0 && index % 5 == 0) {
                    return _buildNativeAdPlaceholder(context, isDark);
                  }

                  final bookIndex = index - (index ~/ 5);
                  if (bookIndex >= _filteredBooks.length) return null;

                  final book = _filteredBooks[bookIndex];
                  return _isGridView
                      ? _buildBookCard(context, book, isDark)
                      : _buildBookListTile(context, book, isDark);
                },
                childCount:
                    _filteredBooks.length + (_filteredBooks.length ~/ 5),
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
            'Fazilet Library',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : FaziletTheme.darkPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '34 Ilmihals and instructional guides',
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

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    final languages = _books.map((b) => b.language).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Languages'),
                selected: _selectedLanguage == null,
                onSelected: (_) => setState(() {
                  _selectedLanguage = null;
                  _applyFilters();
                }),
              ),
              const SizedBox(width: 8),
              ...languages.map((lang) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(lang),
                      selected: _selectedLanguage == lang,
                      onSelected: (_) => setState(() {
                        _selectedLanguage = lang;
                        _applyFilters();
                      }),
                    ),
                  )),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Madhhabs'),
                selected: _selectedMadhhab == null,
                onSelected: (_) => setState(() {
                  _selectedMadhhab = null;
                  _applyFilters();
                }),
              ),
              const SizedBox(width: 8),
              ...Madhhab.values.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(m.name.toUpperCase()),
                      selected: _selectedMadhhab == m,
                      onSelected: (_) => setState(() {
                        _selectedMadhhab = m;
                        _applyFilters();
                      }),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredBooks.length} items in catalog',
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
                    ? Colors.white.withValues(alpha: 0.05)
                    : FaziletTheme.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
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

  Widget _buildBookCard(BuildContext context, LibraryBook book, bool isDark) {
    final progress = _downloadProgress[book.filename];

    return FutureBuilder<bool>(
      future: _downloadService.isBookDownloaded(book.filename),
      builder: (context, snapshot) {
        final isDownloaded = book.isEssential || (snapshot.data ?? false);

        return GestureDetector(
          onTap: () =>
              isDownloaded ? _openBook(context, book) : _startDownload(book),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: FaziletTheme.accentPrimary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            FaziletTheme.accentPrimary,
                            FaziletTheme.accentPrimary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    if (progress != null && progress < 1.0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(
                        isDownloaded
                            ? Icons.check_circle_rounded
                            : Icons.download_for_offline_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : FaziletTheme.darkPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildMetadataTag(
                              book.language, FaziletTheme.accentSecondary),
                          const SizedBox(width: 8),
                          _buildMetadataTag(book.madhhab.name.toUpperCase(),
                              FaziletTheme.accentTertiary),
                          const SizedBox(width: 8),
                          _buildMetadataTag(book.getDisplaySize(),
                              Colors.grey.withValues(alpha: 0.8)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadataTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.lora(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  final Set<String> _inProgressDownloads = {};

  void _startDownload(LibraryBook book) async {
    if (_inProgressDownloads.contains(book.filename)) return;

    setState(() {
      _inProgressDownloads.add(book.filename);
    });

    await _downloadService.downloadBook(
      filename: book.filename,
      expectedChecksum: book.checksum,
      customUrl: book.customDownloadUrl,
      onProgress: (p) => setState(() => _downloadProgress[book.filename] = p),
      onComplete: (_) {
        setState(() {
          _downloadProgress[book.filename] = 1.0;
          _inProgressDownloads.remove(book.filename);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${book.title} downloaded successfully.')),
        );
      },
      onError: (err) {
        setState(() {
          _downloadProgress.remove(book.filename);
          _inProgressDownloads.remove(book.filename);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      },
    );
  }

  Widget _buildBookListTile(
      BuildContext context, LibraryBook book, bool isDark) {
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
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
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
                    book.title,
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
        color: FaziletTheme.accentPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: FaziletTheme.accentPrimary.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Text(
          'Sponsored Content',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: FaziletTheme.accentPrimary.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _openBook(BuildContext context, LibraryBook book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(book: book),
      ),
    );
  }
}
