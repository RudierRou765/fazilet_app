import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Fazilet Database Provider
/// Manages offline-first SQLite connections for:
/// 1. District database (973 Turkey districts with prayer offsets)
/// 2. Book databases (per-book .sqlite files for fragmented book reading)
///
/// Zero AI-Slop Policy: Production-ready, strongly-typed, error-safe.
class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider._internal();
  factory DatabaseProvider() => _instance;
  DatabaseProvider._internal();

  // Database names from CMS
  static const String districtDbName = 'districts.sqlite';

  // Cached database instances
  Database? _districtDatabase;
  final Map<String, Database> _bookDatabases = {};

  /// Initialize the district database from local storage
  /// If not found in local storage, copies it from app assets
  Future<Database> getDistrictDatabase() async {
    if (_districtDatabase != null && _districtDatabase!.isOpen) {
      return _districtDatabase!;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbDir = join(directory.path, 'databases');
      final districtPath = join(dbDir, districtDbName);

      // Ensure directory exists
      final dbFolder = Directory(dbDir);
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
      }

      // Check if file exists in documents directory
      final districtFile = File(districtPath);
      if (!await districtFile.exists()) {
        // Atomic copy from assets
        await _copyDistrictFromAssets(districtPath);
      }

      _districtDatabase = await openDatabase(
        districtPath,
        readOnly: true, // Pre-populated, read-only for districts
        singleInstance: true,
      );

      // Verify schema integrity
      await _verifyDistrictSchema(_districtDatabase!);

      return _districtDatabase!;
    } catch (e, stackTrace) {
      throw DatabaseInitializationException(
        'Failed to initialize district database: $e',
        stackTrace,
      );
    }
  }

  /// Copy districts.sqlite from assets/data/ to documents directory
  Future<void> _copyDistrictFromAssets(String targetPath) async {
    try {
      final ByteData data = await rootBundle.load(join('assets', 'data', districtDbName));
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw DatabaseInitializationException('Failed to copy district asset: $e', null);
    }
  }

  /// Open a book database by its local filename
  /// Each book has its own .sqlite file (e.g., 'ilmihal_tr.sqlite')
  Future<Database> getBookDatabase(String bookFilename) async {
    if (_bookDatabases.containsKey(bookFilename)) {
      final db = _bookDatabases[bookFilename]!;
      if (db.isOpen) return db;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      // Ensure the books directory exists
      final booksDir = Directory(join(directory.path, 'databases', 'books'));
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final bookPath = join(booksDir.path, bookFilename);

      final bookFile = File(bookPath);
      if (!await bookFile.exists()) {
        throw BookDatabaseNotFoundException(
          'Book database not found: $bookFilename at $bookPath',
        );
      }

      final db = await openDatabase(
        bookPath,
        readOnly: false, // Books need FTS queries and potential index updates
        singleInstance: true,
      );

      // Verify strict fragmented book schema
      await _verifyBookSchema(db, bookFilename);

      _bookDatabases[bookFilename] = db;
      return db;
    } catch (e, stackTrace) {
      throw DatabaseInitializationException(
        'Failed to open book database $bookFilename: $e',
        stackTrace,
      );
    }
  }

  /// Verify district database has the required schema
  Future<void> _verifyDistrictSchema(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='districts'",
      );
      if (tables.isEmpty) {
        throw InvalidSchemaException(
          'Districts table not found in district database',
        );
      }

      // Verify required columns exist
      final columns = await db.rawQuery('PRAGMA table_info(districts)');
      final requiredColumns = [
        'DistrictID',
        'CountryID',
        'CityID',
        'Name',
        'Latitude',
        'Longitude',
        'TimeZone',
        'FajrOffset',
        'DhuhrOffset',
        'AsrOffset',
        'MaghribOffset',
        'IshaOffset',
      ];

      final columnNames =
          columns.map((c) => c['name'] as String).toList();

      for (final required in requiredColumns) {
        if (!columnNames.contains(required)) {
          throw InvalidSchemaException(
            'Missing required column: $required in districts table',
          );
        }
      }
    } catch (e) {
      if (e is InvalidSchemaException) rethrow;
      throw InvalidSchemaException('Schema verification failed: $e');
    }
  }

  /// Verify book database has the required fragmented architecture
  Future<void> _verifyBookSchema(Database db, String filename) async {
    try {
      // 1. Check for core tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('book_meta', 'book_content')",
      );
      
      if (tables.length < 2) {
        throw InvalidSchemaException(
          'Book_meta or book_content table missing in $filename',
        );
      }

      // 2. Check for FTS5 Virtual Table (book_search)
      final ftsTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='book_search' AND sql LIKE '%FTS5%'",
      );
      
      if (ftsTables.isEmpty) {
        throw InvalidSchemaException(
          'FTS5 Search Index (book_search) not found in $filename',
        );
      }

      // 3. Verify content columns
      final columns = await db.rawQuery('PRAGMA table_info(book_content)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      final requiredColumns = ['FragmentID', 'ChapterID', 'SectionID', 'Content', 'OrderIndex'];
      for (final col in requiredColumns) {
        if (!columnNames.contains(col)) {
          throw InvalidSchemaException('Missing required column: $col in book_content');
        }
      }
    } catch (e) {
      if (e is InvalidSchemaException) rethrow;
      throw InvalidSchemaException('Book schema verification failed for $filename: $e');
    }
  }

  /// Close all database connections (for app lifecycle management)
  Future<void> closeAll() async {
    if (_districtDatabase != null && _districtDatabase!.isOpen) {
      await _districtDatabase!.close();
      _districtDatabase = null;
    }

    for (final entry in _bookDatabases.entries.toList()) {
      if (entry.value.isOpen) {
        await entry.value.close();
      }
    }
    _bookDatabases.clear();
  }

  /// Get the count of loaded book databases (for debugging)
  int get loadedBookCount => _bookDatabases.length;
}

/// Custom exceptions for database operations
class DistrictDatabaseNotFoundException implements Exception {
  final String message;
  DistrictDatabaseNotFoundException(this.message);
  @override
  String toString() => 'DistrictDatabaseNotFoundException: $message';
}

class BookDatabaseNotFoundException implements Exception {
  final String message;
  BookDatabaseNotFoundException(this.message);
  @override
  String toString() => 'BookDatabaseNotFoundException: $message';
}

class DatabaseInitializationException implements Exception {
  final String message;
  final StackTrace? stackTrace;
  DatabaseInitializationException(this.message, this.stackTrace);
  @override
  String toString() => 'DatabaseInitializationException: $message';
}

class InvalidSchemaException implements Exception {
  final String message;
  InvalidSchemaException(this.message);
  @override
  String toString() => 'InvalidSchemaException: $message';
}
