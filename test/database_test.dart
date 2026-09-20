import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:codexa/data/database/database_helper.dart';

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

  group('DatabaseHelper', () {
    test('insertBook and getBook', () async {
      final book = {
        'id': 'test-book-1',
        'driveFolderId': 'folder-1',
        'sourceName': 'Test Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 0,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      };

      await DatabaseHelper.insertBook(book);
      final result = await DatabaseHelper.getBook('test-book-1');

      expect(result, isNotNull);
      expect(result!['sourceName'], 'Test Book');
    });

    test('getAllBooks returns books sorted by addedAt DESC', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-1',
        'driveFolderId': 'f1',
        'sourceName': 'First',
        'addedAt': '2026-01-01T00:00:00.000',
        'syncStatus': 0,
        'totalDocuments': 0,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertBook({
        'id': 'book-2',
        'driveFolderId': 'f2',
        'sourceName': 'Second',
        'addedAt': '2026-06-01T00:00:00.000',
        'syncStatus': 0,
        'totalDocuments': 0,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });

      final books = await DatabaseHelper.getAllBooks();
      expect(books.length, 2);
      expect(books.first['id'], 'book-2');
    });

    test('deleteBook removes book', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-del',
        'driveFolderId': 'f1',
        'sourceName': 'Delete Me',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 0,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });

      await DatabaseHelper.deleteBook('book-del');
      final result = await DatabaseHelper.getBook('book-del');
      expect(result, isNull);
    });

    test('insertDocument and getDocumentsForBook', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-doc',
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
        'id': 'doc-1',
        'bookId': 'book-doc',
        'driveFileId': 'drive-1',
        'sourceName': 'Chapter 1',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 0,
        'availabilityStatus': 0,
      });

      final docs = await DatabaseHelper.getDocumentsForBook('book-doc');
      expect(docs.length, 1);
      expect(docs.first['sourceName'], 'Chapter 1');
    });

    test('upsertReadingProgress creates and updates', () async {
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

      // Create progress
      await DatabaseHelper.upsertReadingProgress({
        'id': 'rp-1',
        'documentId': 'doc-rp',
        'bookId': 'book-rp',
        'currentPage': 5,
        'totalPages': 100,
        'progressPercent': 0.05,
        'lastOpenedAt': DateTime.now().toIso8601String(),
      });

      var progress = await DatabaseHelper.getReadingProgress('doc-rp');
      expect(progress, isNotNull);
      expect(progress!['currentPage'], 5);

      // Update progress
      await DatabaseHelper.upsertReadingProgress({
        'id': 'rp-1',
        'documentId': 'doc-rp',
        'bookId': 'book-rp',
        'currentPage': 10,
        'totalPages': 100,
        'progressPercent': 0.10,
        'lastOpenedAt': DateTime.now().toIso8601String(),
      });

      progress = await DatabaseHelper.getReadingProgress('doc-rp');
      expect(progress!['currentPage'], 10);
    });

    test('insertBookmark with UNIQUE constraint', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-bm',
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
        'id': 'doc-bm',
        'bookId': 'book-bm',
        'driveFileId': 'drive-bm',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      // Insert first bookmark
      await DatabaseHelper.insertBookmark({
        'id': 'bm-1',
        'documentId': 'doc-bm',
        'page': 1,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Insert duplicate — should be ignored
      await DatabaseHelper.insertBookmark({
        'id': 'bm-2',
        'documentId': 'doc-bm',
        'page': 1,
        'createdAt': DateTime.now().toIso8601String(),
      });

      final bookmarks = await DatabaseHelper.getBookmarksForDocument('doc-bm');
      expect(bookmarks.length, 1);
    });

    test('isPageBookmarked', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-isbm',
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
        'id': 'doc-isbm',
        'bookId': 'book-isbm',
        'driveFileId': 'drive-isbm',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2,
        'availabilityStatus': 2,
      });

      await DatabaseHelper.insertBookmark({
        'id': 'bm-isbm',
        'documentId': 'doc-isbm',
        'page': 5,
        'createdAt': DateTime.now().toIso8601String(),
      });

      expect(await DatabaseHelper.isPageBookmarked('doc-isbm', 5), true);
      expect(await DatabaseHelper.isPageBookmarked('doc-isbm', 6), false);
    });

    test('searchAll returns matching books and documents', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-search',
        'driveFolderId': 'f1',
        'sourceName': 'Flutter Development',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-search',
        'bookId': 'book-search',
        'driveFileId': 'drive-search',
        'sourceName': 'Advanced Patterns',
        'mimeType': 'application/pdf',
        'fileSize': 2048,
        'downloadStatus': 0,
        'availabilityStatus': 0,
      });

      final results = await DatabaseHelper.searchAll('Flutter');
      expect(results.length, greaterThanOrEqualTo(1));
      expect(results.first['sourceName'], 'Flutter Development');
    });

    test('getRecentlyAdded returns limited results', () async {
      for (var i = 0; i < 5; i++) {
        await DatabaseHelper.insertBook({
          'id': 'book-recent-$i',
          'driveFolderId': 'f1',
          'sourceName': 'Book $i',
          'addedAt': DateTime(2026, 1, i + 1).toIso8601String(),
          'syncStatus': 0,
          'totalDocuments': 0,
          'downloadedDocuments': 0,
          'totalBytes': 0,
          'downloadedBytes': 0,
        });
      }

      final recent = await DatabaseHelper.getRecentBooks(3);
      expect(recent.length, 3);
    });

    test('searchAll returns max 50 results', () async {
      // Insert 60 books with matching names
      for (var i = 0; i < 60; i++) {
        await DatabaseHelper.insertBook({
          'id': 'book-limit-$i',
          'driveFolderId': 'f1',
          'sourceName': 'Searchable Book $i',
          'addedAt': DateTime.now().toIso8601String(),
          'syncStatus': 0,
          'totalDocuments': 0,
          'downloadedDocuments': 0,
          'totalBytes': 0,
          'downloadedBytes': 0,
        });
      }

      final results = await DatabaseHelper.searchAll('Searchable');
      expect(results.length, lessThanOrEqualTo(50));
    });

    test('resetStaleDownloads resets downloading to notDownloaded', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-stale',
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
        'id': 'doc-stale',
        'bookId': 'book-stale',
        'driveFileId': 'drive-stale',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 2, // downloading
        'availabilityStatus': 0,
      });

      await DatabaseHelper.resetStaleDownloads();

      final doc = await DatabaseHelper.getDocument('doc-stale');
      expect(doc, isNotNull);
      expect(doc!['downloadStatus'], 0); // notDownloaded
    });

    test('resetStaleDownloads resets queued downloads too', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-queued',
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
        'id': 'doc-queued',
        'bookId': 'book-queued',
        'driveFileId': 'drive-queued',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 1, // queued
        'availabilityStatus': 0,
      });

      await DatabaseHelper.resetStaleDownloads();

      final doc = await DatabaseHelper.getDocument('doc-queued');
      expect(doc, isNotNull);
      expect(doc!['downloadStatus'], 0); // notDownloaded
    });

    test('deleteBook cascades to book_sections', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-cascade',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 0,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertSection({
        'id': 'section-1',
        'bookId': 'book-cascade',
        'driveFolderId': 'folder-cascade',
        'sourceName': 'Chapter 1',
        'sortOrder': 0,
      });

      var sections = await DatabaseHelper.getSectionsForBook('book-cascade');
      expect(sections.length, 1);

      await DatabaseHelper.deleteBook('book-cascade');

      sections = await DatabaseHelper.getSectionsForBook('book-cascade');
      expect(sections.length, 0);
    });

    test('removeBookmark works correctly', () async {
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

      await DatabaseHelper.insertBookmark({
        'id': 'bm-rmbm',
        'documentId': 'doc-rmbm',
        'page': 3,
        'label': 'Test',
        'createdAt': DateTime.now().toIso8601String(),
      });

      expect(await DatabaseHelper.isPageBookmarked('doc-rmbm', 3), true);

      await DatabaseHelper.deleteBookmark('bm-rmbm');

      expect(await DatabaseHelper.isPageBookmarked('doc-rmbm', 3), false);
    });
  });
}
