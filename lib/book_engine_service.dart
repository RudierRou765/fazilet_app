import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'database_provider.dart';

/// Book metadata model (from book_meta table)
class BookMeta {
  final int bookId;
  final String title;
  final String language;
  final String version;
  final int totalFragments;

  const BookMeta({
    required this.bookId,
    required this.title,
    required this.language,
    required this.version,
    required this.totalFragments,
  });

  factory BookMeta.fromMap(Map<String, dynamic> map) {
    return BookMeta(
      bookId: map['BookID'] as int,
      title: map['Title'] as String,
      language: map['Language'] as String,
      version: map['Version'] as String,
      totalFragments: map['TotalFragments'] as int,
    );
  }

  @override
  String toString() => 'BookMeta($bookId: $title [$language] v$version)';
}

/// Book content fragment (from book_content table)
class BookFragment {
  final int fragmentId;
  final int chapterId;
  final int? sectionId;
  final String content;
  final int orderIndex;

  const BookFragment({
    required this.fragmentId,
    required this.chapterId,
    required this.sectionId,
    required this.content,
    required this.orderIndex,
  });

  factory BookFragment.fromMap(Map<String, dynamic> map) {
    return BookFragment(
      fragmentId: map['FragmentID'] as int,
      chapterId: map['ChapterID'] as int,
      sectionId: map['SectionID'] as int?,
      content: map['Content'] as String,
      orderIndex: map['OrderIndex'] as int,
    );
  }

  @override
  String toString() =>
      'Fragment($fragmentId: Chapter $chapterId, Order $orderIndex)';
}

/// Search result with snippet and highlighted matches
class BookSearchResult {
  final int fragmentId;
  final int chapterId;
  final String snippet; // Contains *wrapped* matches
  final double relevance; // Rank from FTS5

  const BookSearchResult({
    required this.fragmentId,
    required this.chapterId,
    required this.snippet,
    required this.relevance,
  });

  /// Extract highlighted words from snippet (between * markers)
  List<String> get highlightedWords {
    final regex = RegExp(r'\*(.*?)\*');
    return regex
        .allMatches(snippet)
        .map((m) => m.group(1) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  String toString() =>
      'SearchResult(Fragment $fragmentId: $snippet...)';
}

/// Book Engine Service
/// Handles fragmented book stitching and FTS5 full-text search
/// Zero AI-Slop: Production-ready, strongly-typed, comprehensive error handling
class BookEngineService {
  final DatabaseProvider _dbProvider;

  BookEngineService({DatabaseProvider? dbProvider})
      : _dbProvider = dbProvider ?? DatabaseProvider();

  /// Get book metadata
  Future<BookMeta> getBookMeta(String bookFilename) async {
    try {
      final db = await _dbProvider.getBookDatabase(bookFilename);

      final results = await db.query(
        'book_meta',
        limit: 1,
      );

      if (results.isEmpty) {
        throw BookNotFoundException(
          'Book metadata not found in $bookFilename',
        );
      }

      return BookMeta.fromMap(results.first);
    } catch (e, stackTrace) {
      if (e is BookNotFoundException) rethrow;
      throw BookEngineException(
        'Failed to get book metadata: $e',
        stackTrace,
      );
    }
  }

  /// Stitch the entire book by reading fragments in OrderIndex order
  /// This is the core logic to render a fragmented book as a single readable text
  Future<List<BookFragment>> getBookContent(String bookFilename) async {
    try {
      final db = await _dbProvider.getBookDatabase(bookFilename);

      final results = await db.query(
        'book_content',
        orderBy: 'OrderIndex ASC',
      );

      if (results.isEmpty) {
        throw BookNotFoundException(
          'No content found in book: $bookFilename',
        );
      }

      return results.map((map) => BookFragment.fromMap(map)).toList();
    } catch (e, stackTrace) {
      if (e is BookNotFoundException) rethrow;
      throw BookEngineException(
        'Failed to read book content: $e',
        stackTrace,
      );
    }
  }

  /// Get a specific chapter's content, stitched in order
  Future<List<BookFragment>> getChapterContent({
    required String bookFilename,
    required int chapterId,
  }) async {
    try {
      final db = await _dbProvider.getBookDatabase(bookFilename);

      final results = await db.query(
        'book_content',
        where: 'ChapterID = ?',
        whereArgs: [chapterId],
        orderBy: 'OrderIndex ASC',
      );

      return results.map((map) => BookFragment.fromMap(map)).toList();
    } catch (e, stackTrace) {
      throw BookEngineException(
        'Failed to get chapter $chapterId: $e',
        stackTrace,
      );
    }
  }

  /// Perform full-text search using FTS5 with snippet generation
  /// Returns snippets with matched words wrapped in asterisks (*)
  /// Example result: "...namazın *farzları* şunlardır..."
  Future<List<BookSearchResult>> searchBook({
    required String bookFilename,
    required String query,
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final db = await _dbProvider.getBookDatabase(bookFilename);

      // Check if FTS5 virtual table exists
      final ftsExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='book_search'",
      );

      if (ftsExists.isEmpty) {
        // FTS table doesn't exist, try to create it
        await _createFtsTable(db);
      }

      // Use FTS5 snippet() function to get text with *wrapped* matches
      // snippet() syntax: snippet(table, startMatch, endMatch, ellipsis, maxTokens)
      final results = await db.rawQuery('''
        SELECT
          book_content.FragmentID,
          book_content.ChapterID,
          snippet(book_search, 0, '*', '*', '...', 16) AS snippet,
          rank
        FROM book_search
        JOIN book_content ON book_content.rowid = book_search.rowid
        WHERE book_search MATCH ?
        ORDER BY rank
        LIMIT ?
      ''', [query, limit]);

      return results.map((map) {
        return BookSearchResult(
          fragmentId: map['FragmentID'] as int,
          chapterId: map['ChapterID'] as int,
          snippet: map['snippet'] as String,
          relevance: (map['rank'] as num).toDouble(),
        );
      }).toList();
    } catch (e, stackTrace) {
      // If FTS fails, fall back to LIKE search (no highlighting)
      return _fallbackSearch(db: await _dbProvider.getBookDatabase(bookFilename), query: query, limit: limit);
    }
  }

  /// Create FTS5 virtual table if it doesn't exist
  Future<void> _createFtsTable(Database db) async {
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS book_search
        USING fts5(
          Content,
          content=book_content,
          content_rowid=rowid
        )
      ''');

      // Populate the FTS table
      await db.execute('''
        INSERT INTO book_search(rowid, Content)
        SELECT rowid, Content FROM book_content
      ''');
    } catch (e) {
      // FTS5 might not be available, that's okay
      // Search will fall back to LIKE queries
    }
  }

  /// Fallback search when FTS5 is not available
  /// Returns results without snippet highlighting
  Future<List<BookSearchResult>> _fallbackSearch({
    required Database db,
    required String query,
    required int limit,
  }) async {
    try {
      final results = await db.query(
        'book_content',
        where: 'Content LIKE ?',
        whereArgs: ['%$query%'],
        limit: limit,
      );

      return results.map((map) {
        final content = map['Content'] as String;
        final queryLower = query.toLowerCase();
        final contentLower = content.toLowerCase();
        final index = contentLower.indexOf(queryLower);

        // Create a simple snippet (no * wrapping* in fallback)
        String snippet;
        if (index >= 0) {
          final start = (index - 20).clamp(0, content.length);
          final end = (index + query.length + 20).clamp(0, content.length);
          snippet = '${start > 0 ? '...' : ''}${content.substring(start, end)}${end < content.length ? '...' : ''}';
        } else {
          snippet = content.length > 50 ? '${content.substring(0, 50)}...' : content;
        }

        return BookSearchResult(
          fragmentId: map['FragmentID'] as int,
          chapterId: map['ChapterID'] as int,
          snippet: snippet,
          relevance: 1.0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get the full text content as a single string (for display)
  Future<String> getBookAsPlainText(String bookFilename) async {
    try {
      final fragments = await getBookContent(bookFilename);

      // Stitch all fragments in order
      final buffer = StringBuffer();
      for (final fragment in fragments) {
        buffer.write(fragment.content);
        if (!fragment.content.endsWith('\n')) {
          buffer.write('\n\n');
        }
      }

      return buffer.toString();
    } catch (e, stackTrace) {
      throw BookEngineException(
        'Failed to stitch book as plain text: $e',
        stackTrace,
      );
    }
  }

  /// Get navigation structure (unique chapters/sections)
  Future<Map<int, List<int?>>> getBookStructure(String bookFilename) async {
    try {
      final db = await _dbProvider.getBookDatabase(bookFilename);

      final results = await db.rawQuery('''
        SELECT ChapterID, SectionID
        FROM book_content
        GROUP BY ChapterID, SectionID
        ORDER BY OrderIndex ASC
      ''');

      final structure = <int, List<int?>>{};
      for (final row in results) {
        final chapterId = row['ChapterID'] as int;
        final sectionId = row['SectionID'] as int?;

        structure.putIfAbsent(chapterId, () => []).add(sectionId);
      }

      return structure;
    } catch (e, stackTrace) {
      throw BookEngineException(
        'Failed to get book structure: $e',
        stackTrace,
      );
    }
  }

  /// Search and get surrounding context (for better reading experience)
  Future<Map<String, dynamic>> searchWithContext({
    required String bookFilename,
    required String query,
    int contextSize = 200, // characters of context around match
  }) async {
    try {
      final searchResults = await searchBook(
        bookFilename: bookFilename,
        query: query,
        limit: 20,
      );

      final fragments = await getBookContent(bookFilename);
      final fragmentMap = {for (var f in fragments) f.fragmentId: f};

      final resultsWithContext = <Map<String, dynamic>>[];

      for (final result in searchResults) {
        final fragment = fragmentMap[result.fragmentId];
        if (fragment == null) continue;

        resultsWithContext.add({
          'fragmentId': result.fragmentId,
          'chapterId': result.chapterId,
          'snippet': result.snippet,
          'highlightedWords': result.highlightedWords,
          'fullContent': fragment.content,
          'orderIndex': fragment.orderIndex,
        });
      }

      return {
        'query': query,
        'totalResults': resultsWithContext.length,
        'results': resultsWithContext,
      };
    } catch (e, stackTrace) {
      throw BookEngineException(
        'Failed to search with context: $e',
        stackTrace,
      );
    }
  }
}

/// Custom exceptions
class BookNotFoundException implements Exception {
  final String message;
  BookNotFoundException(this.message);
  @override
  String toString() => 'BookNotFoundException: $message';
}

class BookEngineException implements Exception {
  final String message;
  final StackTrace? stackTrace;
  BookEngineException(this.message, this.stackTrace);
  @override
  String toString() => 'BookEngineException: $message';
}
