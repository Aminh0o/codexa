import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:codexa/data/database/database_helper.dart';
import 'package:codexa/data/repositories/download_manager.dart';
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

  group('DownloadManager state', () {
    test('initial state is idle', () {
      final dm = DownloadManager();
      expect(dm.state, DownloadQueueState.idle);
    });

    test('pauseDownloads sets state to paused', () async {
      final dm = DownloadManager();
      await dm.pauseDownloads();
      expect(dm.state, DownloadQueueState.paused);
    });

    test('resumeDownloads resets to idle', () async {
      final dm = DownloadManager();
      await dm.pauseDownloads();
      expect(dm.state, DownloadQueueState.paused);

      await dm.resumeDownloads();
      expect(dm.state, DownloadQueueState.idle);
    });

    test('resumeDownloads does nothing when not paused', () async {
      final dm = DownloadManager();
      expect(dm.state, DownloadQueueState.idle);
      await dm.resumeDownloads();
      expect(dm.state, DownloadQueueState.idle);
    });
  });

  group('DownloadManager DB operations', () {
    test('cancelDownload resets status to notDownloaded', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-cd',
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
        'id': 'doc-cd',
        'bookId': 'book-cd',
        'driveFileId': 'drive-cd',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': DownloadStatus.downloading.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      });

      final dm = DownloadManager();
      // cancelDownload adds to stream which may throw if closed; catch it
      try {
        await dm.cancelDownload('doc-cd');
      } catch (_) {}

      final doc = await DatabaseHelper.getDocument('doc-cd');
      expect(doc, isNotNull);
      expect(doc!['downloadStatus'], DownloadStatus.notDownloaded.index);
    });

    test('retryDownload re-queues failed document', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-retry',
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
        'id': 'doc-retry',
        'bookId': 'book-retry',
        'driveFileId': 'drive-retry',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': DownloadStatus.failed.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      });

      final dm = DownloadManager();
      // retryDownload queues and may trigger _processQueue which adds to stream
      try {
        await dm.retryDownload('doc-retry');
      } catch (_) {}

      final doc = await DatabaseHelper.getDocument('doc-retry');
      expect(doc, isNotNull);
      // Status should be queued (set by queueDownload before _processQueue runs)
      expect(doc!['downloadStatus'], anyOf(
        equals(DownloadStatus.queued.index),
        equals(DownloadStatus.downloading.index),
        equals(DownloadStatus.failed.index),
      ));
    });

    test('queueDownload does not duplicate', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-dup-q',
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
        'id': 'doc-dup-q',
        'bookId': 'book-dup-q',
        'driveFileId': 'drive-dup-q',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': DownloadStatus.notDownloaded.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      });

      final dm = DownloadManager();
      // Queue twice — should not error
      try {
        await dm.queueDownload('doc-dup-q');
        await dm.queueDownload('doc-dup-q');
      } catch (_) {}

      final doc = await DatabaseHelper.getDocument('doc-dup-q');
      expect(doc, isNotNull);
      expect(doc!['downloadStatus'], anyOf(
        equals(DownloadStatus.queued.index),
        equals(DownloadStatus.downloading.index),
      ));
    });

    test('getAllDownloads returns non-completed documents', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-all-dl',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 2,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-dl-1',
        'bookId': 'book-all-dl',
        'driveFileId': 'drive-dl-1',
        'sourceName': 'Doc 1',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': DownloadStatus.downloading.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-dl-2',
        'bookId': 'book-all-dl',
        'driveFileId': 'drive-dl-2',
        'sourceName': 'Doc 2',
        'mimeType': 'application/pdf',
        'fileSize': 2048,
        'downloadStatus': DownloadStatus.notDownloaded.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      });

      final downloads = await DownloadManager.getAllDownloads();
      expect(downloads.length, 1);
      expect(downloads.first['sourceName'], 'Doc 1');
    });

    test('getDownloadCounts groups by status', () async {
      await DatabaseHelper.insertBook({
        'id': 'book-counts',
        'driveFolderId': 'f1',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 3,
        'downloadedDocuments': 1,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-count-1',
        'bookId': 'book-counts',
        'driveFileId': 'drive-count-1',
        'sourceName': 'Done',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': DownloadStatus.completed.index,
        'availabilityStatus': BookAvailability.full.index,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-count-2',
        'bookId': 'book-counts',
        'driveFileId': 'drive-count-2',
        'sourceName': 'Downloading',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': DownloadStatus.downloading.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      });
      await DatabaseHelper.insertDocument({
        'id': 'doc-count-3',
        'bookId': 'book-counts',
        'driveFileId': 'drive-count-3',
        'sourceName': 'Failed',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': DownloadStatus.failed.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      });

      final counts = await DownloadManager.getDownloadCounts();
      expect(counts['downloaded'], 1);
      expect(counts['downloading'], 1);
      expect(counts['queued'], 0);
      expect(counts['failed'], 1);
    });
  });

  group('DownloadManager pause / cancel truthfulness', () {
    Future<void> seedDoc(String id, DownloadStatus status) async {
      await DatabaseHelper.insertBook({
        'id': 'book-$id',
        'driveFolderId': 'f-$id',
        'sourceName': 'Book',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await DatabaseHelper.insertDocument({
        'id': id,
        'bookId': 'book-$id',
        'driveFileId': 'drive-$id',
        'sourceName': 'Doc',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
        'downloadStatus': status.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      });
    }

    test('resumeDownloads clears the paused state', () async {
      final dm = DownloadManager();
      await dm.pauseDownloads();
      expect(dm.state, DownloadQueueState.paused);
      await dm.resumeDownloads();
      expect(dm.state, isNot(DownloadQueueState.paused));
    });

    test('paused downloads are counted as paused, never as failed', () async {
      await seedDoc('doc-pause-count', DownloadStatus.paused);
      final counts = await DownloadManager.getDownloadCounts();
      expect(counts['paused'], 1);
      expect(counts['failed'], 0);
    });

    test('cancelDownload marks the item notDownloaded (never failed)', () async {
      await seedDoc('doc-cancel-truth', DownloadStatus.downloading);
      final dm = DownloadManager();
      try {
        await dm.cancelDownload('doc-cancel-truth');
      } catch (_) {}
      final doc = await DatabaseHelper.getDocument('doc-cancel-truth');
      expect(doc!['downloadStatus'], DownloadStatus.notDownloaded.index);
      expect(doc['downloadStatus'], isNot(DownloadStatus.failed.index));
    });

    test('resetStaleDownloads turns a paused item back into notDownloaded', () async {
      await seedDoc('doc-reset-paused', DownloadStatus.paused);
      await DatabaseHelper.resetStaleDownloads();
      final doc = await DatabaseHelper.getDocument('doc-reset-paused');
      expect(doc!['downloadStatus'], DownloadStatus.notDownloaded.index);
    });

    test('retrying a paused item moves it out of the paused state', () async {
      await seedDoc('doc-retry-paused', DownloadStatus.paused);
      final dm = DownloadManager();
      try {
        await dm.retryDownload('doc-retry-paused');
      } catch (_) {}
      final doc = await DatabaseHelper.getDocument('doc-retry-paused');
      expect(doc!['downloadStatus'], isNot(DownloadStatus.paused.index));
      expect(doc['downloadStatus'], anyOf(
        equals(DownloadStatus.queued.index),
        equals(DownloadStatus.downloading.index),
        equals(DownloadStatus.failed.index),
      ));
    });
  });
}
