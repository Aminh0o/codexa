import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../../domain/models/book_models.dart';

class ReadingProgressRepository {
  static const _uuid = Uuid();

  /// Save reading progress (auto-saved, debounced)
  static Future<void> saveProgress({
    required String documentId,
    required String bookId,
    required int currentPage,
    required int totalPages,
  }) async {
    // Store as 0.0-1.0 for LinearProgressIndicator compatibility
    final percent = totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
    // Check for existing progress to reuse its ID (proper UPDATE, not DELETE+INSERT)
    final existing = await DatabaseHelper.getReadingProgress(documentId);
    final id = existing != null ? existing['id'] as String : _uuid.v4();
    await DatabaseHelper.upsertReadingProgress({
      'id': id,
      'documentId': documentId,
      'bookId': bookId,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'progressPercent': percent,
      'lastOpenedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get progress for a document
  static Future<ReadingProgress?> getProgress(String documentId) async {
    final data = await DatabaseHelper.getReadingProgress(documentId);
    return data != null ? ReadingProgress.fromMap(data) : null;
  }

  /// Get continue reading (most recent)
  static Future<Map<String, dynamic>?> getContinueReading() async {
    return await DatabaseHelper.getLastReadingProgress();
  }

  /// Add bookmark (prevents duplicates)
  static Future<void> addBookmark({
    required String documentId,
    required int page,
    String? label,
  }) async {
    // Check if bookmark already exists for this page
    final existing = await DatabaseHelper.isPageBookmarked(documentId, page);
    if (existing) return;
    await DatabaseHelper.insertBookmark({
      'id': _uuid.v4(),
      'documentId': documentId,
      'page': page,
      'label': label,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Remove bookmark
  static Future<void> removeBookmark(String bookmarkId) async {
    await DatabaseHelper.deleteBookmark(bookmarkId);
  }

  /// Get bookmarks for document
  static Future<List<Bookmark>> getBookmarks(String documentId) async {
    final data = await DatabaseHelper.getBookmarksForDocument(documentId);
    return data.map((m) => Bookmark.fromMap(m)).toList();
  }

  /// Check if a page is bookmarked
  static Future<bool> isBookmarked(String documentId, int page) async {
    return await DatabaseHelper.isPageBookmarked(documentId, page);
  }
}
