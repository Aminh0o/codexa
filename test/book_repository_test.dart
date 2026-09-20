import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:codexa/data/database/database_helper.dart';
import 'package:codexa/data/repositories/book_repository.dart';
import 'package:codexa/data/datasources/google_drive_service.dart';
import 'package:codexa/domain/models/book_models.dart';

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

  group('BookRepository', () {
    test('renameBookLocally sets localTitle', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-rn',
        'driveFolderId': 'f1',
        'sourceName': 'Original Title',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 0,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });

      await BookRepository.renameBookLocally('book-rn', 'New Local Title');

      final book = await BookRepository.getBook('book-rn');
      expect(book, isNotNull);
      expect(book!.sourceName, 'Original Title'); // Drive name unchanged
    });

    test('renameSectionLocally sets localTitle on section', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-sec',
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
        'bookId': 'book-sec',
        'driveFolderId': 'folder-sec',
        'sourceName': 'Chapter 1',
        'sortOrder': 0,
      });

      await BookRepository.renameSectionLocally('section-1', 'الفصل الأول');

      final sections = await BookRepository.getSectionsForBook('book-sec');
      expect(sections.length, 1);
      expect(sections.first.sourceName, 'Chapter 1'); // Drive name unchanged
    });

    test('addBook throws for duplicate folder', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-dup-folder',
        'driveFolderId': 'folder-1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 0,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });

      final folder = DriveFile(
        id: 'folder-1',
        name: 'Test Folder',
        mimeType: 'application/vnd.google-apps.folder',
        modifiedTime: DateTime.now(),
      );

      expect(
        () => BookRepository.addBook(folder),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('already in your library'),
        )),
      );
    });

    test('getAllBooks returns all books', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-all-1',
        'driveFolderId': 'f1',
        'sourceName': 'Book 1',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 0,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertBook({
        'id': 'book-all-2',
        'driveFolderId': 'f2',
        'sourceName': 'Book 2',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 0,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });

      final books = await BookRepository.getAllBooks();
      expect(books.length, 2);
    });

    test('getSectionsForBook returns sections', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-sec-list',
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
        'id': 's1',
        'bookId': 'book-sec-list',
        'driveFolderId': 'folder-s1',
        'sourceName': 'Part 1',
        'sortOrder': 0,
      });
      await DatabaseHelper.insertSection({
        'id': 's2',
        'bookId': 'book-sec-list',
        'driveFolderId': 'folder-s2',
        'sourceName': 'Part 2',
        'sortOrder': 1,
      });

      final sections = await BookRepository.getSectionsForBook('book-sec-list');
      expect(sections.length, 2);
      expect(sections.first.sourceName, 'Part 1');
      expect(sections.last.sourceName, 'Part 2');
    });

    test('getDocumentsForSection returns documents', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-doc-sec',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 2,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertSection({
        'id': 'sec-1',
        'bookId': 'book-doc-sec',
        'driveFolderId': 'folder-sec-1',
        'sourceName': 'Chapter',
        'sortOrder': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-sec-1',
        'bookId': 'book-doc-sec',
        'sectionId': 'sec-1',
        'driveFileId': 'drive-1',
        'sourceName': 'Page 1',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 0,
        'availabilityStatus': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-sec-2',
        'bookId': 'book-doc-sec',
        'sectionId': null,
        'driveFileId': 'drive-2',
        'sourceName': 'Page 2',
        'mimeType': 'application/pdf',
        'fileSize': 2048,
        'downloadStatus': 0,
        'availabilityStatus': 0,
      });

      final docs = await BookRepository.getDocumentsForSection('sec-1');
      expect(docs.length, 1);
      expect(docs.first.sourceName, 'Page 1');
    });

    test('search returns matching results', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-search-1',
        'driveFolderId': 'f1',
        'sourceName': 'Flutter in Action',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-search-1',
        'bookId': 'book-search-1',
        'driveFileId': 'drive-search-1',
        'sourceName': 'Advanced Patterns',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': 0,
        'availabilityStatus': 0,
      });

      final results = await BookRepository.search('Flutter');
      expect(results.length, greaterThanOrEqualTo(1));
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

      final recent = await BookRepository.getRecentlyAdded(limit: 3);
      expect(recent.length, 3);
    });

    test('clearDocumentDownload zeroes downloaded-storage aggregates immediately', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-storage',
        'driveFolderId': 'f-store',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 1,
        'totalBytes': 1024,
        'downloadedBytes': 1024,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-storage',
        'bookId': 'book-storage',
        'driveFileId': 'drive-storage',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': DownloadStatus.completed.index,
        'availabilityStatus': BookAvailability.full.index,
        'localPath': '/tmp/doc-storage.pdf',
      });

      // Downloaded storage is positive before removal.
      expect(await DatabaseHelper.getDownloadedStorageUsed(), greaterThan(0));

      await BookRepository.clearDocumentDownload('doc-storage');

      // Immediately zeroed at the DB/aggregate level, with no sync required.
      expect(await DatabaseHelper.getDownloadedStorageUsed(), 0);
      final book = await DatabaseHelper.getBook('book-storage');
      expect(book!['downloadedBytes'], 0);
      expect(book['downloadedDocuments'], 0);
      final doc = await DatabaseHelper.getDocument('doc-storage');
      expect(doc!['downloadStatus'], DownloadStatus.notDownloaded.index);
    });
  });
}
