import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../book_engine_service.dart';
import '../screens/book_reader_screen.dart';

/// Premium Book Search Delegate with FTS5 integration
/// Features: offline search, RichText snippet parsing, zero AI-slop styling
/// CRITICAL: Parses *wrapped* snippets from FTS5 into Poppins-bold-#d97757 highlights
class BookSearchDelegate extends SearchDelegate<String> {
  final LibraryBook book;
  final BookEngineService _engine = BookEngineService();

  List<BookSearchResult> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';

  BookSearchDelegate({
    required this.book,
  });

  @override
  String get searchFieldLabel => 'Search book content...';

  @override
  TextStyle? get searchFieldStyle => GoogleFonts.lora(
        fontSize: 16,
        color: FaziletTheme.darkPrimary,
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? const Color(0xFF1a1a1a) : const Color(0xFFfaf9f5),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white70 : FaziletTheme.darkPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.lora(
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(
            Icons.clear_rounded,
            color: FaziletTheme.accentPrimary,
          ),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_rounded,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : FaziletTheme.darkPrimary,
      ),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Trigger search as user types
    if (query.length >= 2 && query != _lastQuery) {
      _lastQuery = query;
      _performSearch(query);
    }
    return _buildSearchResults(context);
  }

  void _performSearch(String query) async {
    _isSearching = true;
    try {
      final results = await _engine.searchBook(
        bookFilename: book.filename,
        query: query,
        limit: 50,
      );
      _searchResults = results;
    } catch (e) {
      _searchResults = [];
    } finally {
      _isSearching = false;
    }
  }

  Widget _buildSearchResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (query.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.search_rounded,
        message: 'Start typing to search...',
        subtitle: 'Search across all book fragments',
      );
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: FaziletTheme.accentPrimary,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.search_off_rounded,
        message: 'No results found',
        subtitle: 'Try different keywords',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultCard(
          context: context,
          result: result,
          isDark: isDark,
        );
      },
    );
  }

  /// CRITICAL: Build search result card with RichText snippet parsing
  Widget _buildSearchResultCard({
    required BuildContext context,
    required BookSearchResult result,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to book reader at this fragment
        close(context, '');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookReaderScreen(book: book),
          ),
        );
        // TODO: Scroll to fragmentId: result.fragmentId
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: FaziletTheme.accentPrimary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: FaziletTheme.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Chapter ${result.chapterId}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FaziletTheme.accentPrimary,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // CRITICAL: RichText snippet with * parsed highlighting
            RichText(
              text: TextSpan(
                children: _parseSnippetToTextSpans(
                  snippet: result.snippet,
                  isDark: isDark,
                ),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Relevance score (subtle)
            Text(
              'Relevance: ${(result.relevance * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.lora(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// CRITICAL PARSING LOGIC
  /// Converts FTS5 snippet with *wrapped* matches into TextSpans
  ///
  /// Example input: "...namazın *farzları* şunlardır..."
  /// Output: List<TextSpan> where:
  ///   - Text between * markers: Poppins, bold, #d97757
  ///   - Other text: Lora, regular, dark/light color
  List<TextSpan> _parseSnippetToTextSpans({
    required String snippet,
    required bool isDark,
  }) {
    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    bool isInsideAsterisk = false;

    for (int i = 0; i < snippet.length; i++) {
      final char = snippet[i];

      if (char == '*') {
        // Flush buffer before toggle
        if (buffer.isNotEmpty) {
          spans.add(
            TextSpan(
              text: buffer.toString(),
              style: isInsideAsterisk
                  ? GoogleFonts.poppins(
                      // Highlighted: Poppins bold #d97757
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FaziletTheme.accentPrimary,
                    )
                  : GoogleFonts.lora(
                      // Normal: Lora regular
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white70 : FaziletTheme.darkPrimary,
                    ),
            ),
          );
          buffer.clear();
        }
        isInsideAsterisk = !isInsideAsterisk;
      } else {
        buffer.write(char);
      }
    }

    // Flush remaining buffer
    if (buffer.isNotEmpty) {
      spans.add(
        TextSpan(
          text: buffer.toString(),
          style: isInsideAsterisk
              ? GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FaziletTheme.accentPrimary,
                )
              : GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white70 : FaziletTheme.darkPrimary,
                ),
        ),
      );
    }

    return spans;
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.lora(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
