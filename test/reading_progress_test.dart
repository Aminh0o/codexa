import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:codexa/data/database/database_helper.dart';
import 'package:codexa/data/repositories/reading_progress_repository.dart';

void main() {
  sqfliteFfiInit();

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.reset();
    DatabaseHelper.setTestDatabasePath(inMemoryDatabasePath);
    final db = await DatabaseHelper.database;
    await db.delete('books');
    await db.delete('book_sections');
    await db.delete('book_documents');
    await db.delete('reading_progress');
    await db.delete('bookmarks');
  });

  group('ReadingProgressRepository', () {
    test('saveProgress creates progress with correct percent', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-rp',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 1,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-rp',
        'bookId': 'book-rp',
        'driveFileId': 'drive-rp',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      await ReadingProgressRepository.saveProgress(
        documentId: 'doc-rp',
        bookId: 'book-rp',
        currentPage: 25,
        totalPages: 100,
      );

      final progress = await ReadingProgressRepository.getProgress('doc-rp');
      expect(progress, isNotNull);
      expect(progress!.currentPage, 25);
      expect(progress.totalPages, 100);
      expect(progress.progressPercent, 0.25);
    });

    test('saveProgress clamps percent to 1.0', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-clamp',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 1,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-clamp',
        'bookId': 'book-clamp',
        'driveFileId': 'drive-clamp',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      await ReadingProgressRepository.saveProgress(
        documentId: 'doc-clamp',
        bookId: 'book-clamp',
        currentPage: 150,
        totalPages: 100,
      );

      final progress = await ReadingProgressRepository.getProgress('doc-clamp');
      expect(progress, isNotNull);
      expect(progress!.progressPercent, 1.0);
    });

    test('saveProgress handles zero totalPages', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-zero',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 1,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-zero',
        'bookId': 'book-zero',
        'driveFileId': 'drive-zero',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      await ReadingProgressRepository.saveProgress(
        documentId: 'doc-zero',
        bookId: 'book-zero',
        currentPage: 0,
        totalPages: 0,
      );

      final progress = await ReadingProgressRepository.getProgress('doc-zero');
      expect(progress, isNotNull);
      expect(progress!.progressPercent, 0.0);
    });

    test('saveProgress updates existing progress', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-update',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 1,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-update',
        'bookId': 'book-update',
        'driveFileId': 'drive-update',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      // First save
      await ReadingProgressRepository.saveProgress(
        documentId: 'doc-update',
        bookId: 'book-update',
        currentPage: 10,
        totalPages: 100,
      );

      // Second save — should update, not create duplicate
      await ReadingProgressRepository.saveProgress(
        documentId: 'doc-update',
        bookId: 'book-update',
        currentPage: 20,
        totalPages: 100,
      );

      final progress = await ReadingProgressRepository.getProgress('doc-update');
      expect(progress, isNotNull);
      expect(progress!.currentPage, 20);
    });

    test('addBookmark prevents duplicates', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-dup',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-dup',
        'bookId': 'book-dup',
        'driveFileId': 'drive-dup',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      await ReadingProgressRepository.addBookmark(
        documentId: 'doc-dup',
        page: 5,
        label: 'First',
      );

      // Duplicate should be silently ignored
      await ReadingProgressRepository.addBookmark(
        documentId: 'doc-dup',
        page: 5,
        label: 'Duplicate',
      );

      final bookmarks = await ReadingProgressRepository.getBookmarks('doc-dup');
      expect(bookmarks.length, 1);
      expect(bookmarks.first.label, 'First');
    });

    test('addBookmark allows different pages', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-diff',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-diff',
        'bookId': 'book-diff',
        'driveFileId': 'drive-diff',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      await ReadingProgressRepository.addBookmark(documentId: 'doc-diff', page: 5);
      await ReadingProgressRepository.addBookmark(documentId: 'doc-diff', page: 10);
      await ReadingProgressRepository.addBookmark(documentId: 'doc-diff', page: 15);

      final bookmarks = await ReadingProgressRepository.getBookmarks('doc-diff');
      expect(bookmarks.length, 3);
    });

    test('removeBookmark works', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-rmbm',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-rmbm',
        'bookId': 'book-rmbm',
        'driveFileId': 'drive-rmbm',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      await ReadingProgressRepository.addBookmark(documentId: 'doc-rmbm', page: 5);
      expect(await ReadingProgressRepository.isBookmarked('doc-rmbm', 5), true);

      final bookmarks = await ReadingProgressRepository.getBookmarks('doc-rmbm');
      await ReadingProgressRepository.removeBookmark(bookmarks.first.id);

      expect(await ReadingProgressRepository.isBookmarked('doc-rmbm', 5), false);
    });

    test('isBookmarked returns false for non-existent page', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-nobm',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-nobm',
        'bookId': 'book-nobm',
        'driveFileId': 'drive-nobm',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      expect(await ReadingProgressRepository.isBookmarked('doc-nobm', 99), false);
    });

    test('getContinueReading returns most recent', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-cont',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 2,
        'downloadedDocuments': 2,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-cont-1',
        'bookId': 'book-cont',
        'driveFileId': 'drive-cont-1',
        'sourceName': 'Doc 1',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-cont-2',
        'bookId': 'book-cont',
        'driveFileId': 'drive-cont-2',
        'sourceName': 'Doc 2',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      // Save with delay to ensure different timestamps
      await ReadingProgressRepository.saveProgress(
        documentId: 'doc-cont-1',
        bookId: 'book-cont',
        currentPage: 5,
        totalPages: 100,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      await ReadingProgressRepository.saveProgress(
        documentId: 'doc-cont-2',
        bookId: 'book-cont',
        currentPage: 10,
        totalPages: 100,
      );

      final continueReading = await ReadingProgressRepository.getContinueReading();
      expect(continueReading, isNotNull);
      expect(continueReading!['documentId'], 'doc-cont-2');
    });
  });
}
