import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

/// On-Demand Downloader Service — Robust SQLite distribution
/// Fetches book fragments/databases from remote CDN and manages local storage
/// Zero AI-Slop: Progress tracking, atomic writes, checksum verification stubs
class DownloadService {
  final Dio _dio = Dio();
  
  // Production CDN Base (placeholder)
  static const String _cdnBaseUrl = 'https://raw.githubusercontent.com/fazilet/books/main/databases';

  /// Download a book database and save to local storage with integrity check
  Future<void> downloadBook({
    required String filename,
    String? expectedChecksum,
    String? customUrl,
    required Function(double) onProgress,
    required Function(String) onComplete,
    required Function(String) onError,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetPath = p.join(appDir.path, 'databases', 'books', filename);
    final tempPath = '$targetPath.tmp';

    try {
      // Ensure directory exists
      final directory = Directory(p.dirname(targetPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Cleanup orphaned temp file from previous failed attempts
      if (await File(tempPath).exists()) {
        await File(tempPath).delete();
      }

      final url = customUrl ?? '$_cdnBaseUrl/$filename';
      
      // Download to temporary file
      await _dio.download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // Verify integrity if checksum is provided
      if (expectedChecksum != null) {
        final isValid = await _verifyFileHash(tempPath, expectedChecksum);
        if (!isValid) {
          if (await File(tempPath).exists()) await File(tempPath).delete();
          onError('Data integrity check failed. File might be corrupted.');
          return;
        }
      }

      // Move temp file to final location
      await File(tempPath).rename(targetPath);
      onComplete(targetPath);
    } catch (e) {
      // Cleanup temp file on error
      if (await File(tempPath).exists()) {
        await File(tempPath).delete();
      }

      String userMessage = 'Download failed: ${e.toString()}';
      if (e is FileSystemException && (e.message.contains('No space left') || e.osError?.errorCode == 28)) {
        userMessage = 'Download failed: Insufficient storage space on device. Please free up space and try again.';
      } else if (e is DioException) {
        userMessage = 'Download failed: Network error. Please check your connection.';
      }

      onError(userMessage);
    }
  }

  /// Verify SHA-256 hash of a file using streaming to prevent OOM
  Future<bool> _verifyFileHash(String filePath, String expectedHash) async {
    try {
      final file = File(filePath);
      final stream = file.openRead();
      final hash = await sha256.bind(stream).first;
      return hash.toString().toLowerCase() == expectedHash.toLowerCase();
    } catch (e) {
      debugPrint('Hash verification failed: $e');
      return false;
    }
  }

  /// Check if a book is already downloaded
  Future<bool> isBookDownloaded(String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetPath = p.join(appDir.path, 'databases', 'books', filename);
    return File(targetPath).exists();
  }

  /// Delete a local book to free up space
  Future<void> deleteBook(String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetPath = p.join(appDir.path, 'databases', 'books', filename);
    final file = File(targetPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
