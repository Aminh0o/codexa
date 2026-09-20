import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:codexa/data/database/database_helper.dart';
import 'package:codexa/data/datasources/google_drive_service.dart';
import 'package:codexa/data/services/sync_engine.dart';
import 'package:codexa/domain/models/book_models.dart';

DriveFile _file(String id, {DateTime? modified}) => DriveFile(
      id: id,
      name: '.codexa_sync.json',
      mimeType: 'application/json',
      modifiedTime: modified,
    );

void main() {
  sqfliteFfiInit();

  group('SyncEngine.selectAuthoritativeSyncFile', () {
    test('returns null when there are no candidates', () {
      expect(SyncEngine.selectAuthoritativeSyncFile(const []), isNull);
    });

    test('duplicate metadata: newest modifiedTime is authoritative', () {
      final stale = _file('aaa', modified: DateTime(2020));
      final fresh = _file('bbb', modified: DateTime(2024));
      final chosen =
          SyncEngine.selectAuthoritativeSyncFile([stale, fresh, _file('ccc', modified: DateTime(2022))]);
      expect(chosen?.id, 'bbb');
    });

    test('equal timestamps resolve deterministically by greatest id', () {
      final t = DateTime(2024);
      final chosen = SyncEngine.selectAuthoritativeSyncFile(
          [_file('x1', modified: t), _file('x9', modified: t), _file('x5', modified: t)]);
      expect(chosen?.id, 'x9');
    });

    test('files without a timestamp are treated as oldest', () {
      final chosen = SyncEngine.selectAuthoritativeSyncFile(
          [_file('nots'), _file('ts', modified: DateTime(2021))]);
      expect(chosen?.id, 'ts');
    });
  });

  group('SyncEngine.mergeProgress', () {
    Map<String, dynamic> row(String doc, String when, int page) => {
          'id': 'p-$doc',
          'documentId': doc,
          'bookId': 'book-1',
          'currentPage': page,
          'totalPages': 10,
          'progressPercent': page / 10,
          'lastOpenedAt': when,
        };

    test('newer local wins over stale remote (never discard local)', () {
      final merged = SyncEngine.mergeProgress(
        [row('doc-1', '2024-06-01T00:00:00Z', 9)],
        [row('doc-1', '2020-01-01T00:00:00Z', 1)],
      );
      expect(merged['doc-1']!['currentPage'], 9);
    });

    test('newer remote wins over stale local', () {
      final merged = SyncEngine.mergeProgress(
        [row('doc-1', '2020-01-01T00:00:00Z', 1)],
        [row('doc-1', '2024-06-01T00:00:00Z', 7)],
      );
      expect(merged['doc-1']!['currentPage'], 7);
    });

    test('remote-only documents are added', () {
      final merged = SyncEngine.mergeProgress(
        [row('doc-1', '2024-01-01T00:00:00Z', 2)],
        [row('doc-2', '2024-02-01T00:00:00Z', 5)],
      );
      expect(merged.keys.toSet(), {'doc-1', 'doc-2'});
    });
  });

  group('SyncEngine.applyLocalMerge (atomic, validated)', () {
    late Database db;

    Future<void> seedBookAndDoc(String bookId, String docId) async {
      await db.insert('books', {
        'id': bookId,
        'driveFolderId': 'folder-$bookId',
        'sourceName': 'Book $bookId',
        'addedAt': DateTime.now().toIso8601String(),
        'syncStatus': 0,
        'totalDocuments': 1,
        'downloadedDocuments': 0,
        'totalBytes': 0,
        'downloadedBytes': 0,
      });
      await db.insert('book_documents', {
        'id': docId,
        'bookId': bookId,
        'sectionId': null,
        'driveFileId': 'drive-$docId',
        'sourceName': 'Doc $docId',
        'mimeType': 'application/pdf',
        'fileSize': 0,
        'downloadStatus': 0,
        'availabilityStatus': 0,
      });
    }

    Map<String, dynamic> progress(String id, String docId, String bookId) => {
          'id': id,
          'documentId': docId,
          'bookId': bookId,
          'currentPage': 3,
          'totalPages': 10,
          'progressPercent': 0.3,
          'lastOpenedAt': DateTime.now().toIso8601String(),
        };

    Map<String, dynamic> bookmark(String id, String docId, int page) => {
          'id': id,
          'documentId': docId,
          'page': page,
          'label': null,
          'createdAt': DateTime.now().toIso8601String(),
        };

    setUp(() async {
      databaseFactory = databaseFactoryFfi;
      DatabaseHelper.reset();
      DatabaseHelper.setTestDatabasePath(inMemoryDatabasePath);
      db = await DatabaseHelper.database;
      await db.delete('reading_progress');
      await db.delete('bookmarks');
      await db.delete('book_documents');
      await db.delete('books');
    });

    test('successful atomic merge persists valid rows', () async {
      await seedBookAndDoc('book-1', 'doc-1');
      final summary = await SyncEngine.applyLocalMerge(
        db,
        progress: [progress('p1', 'doc-1', 'book-1')],
        bookmarks: [bookmark('b1', 'doc-1', 4)],
      );
      expect(summary.appliedProgress.length, 1);
      expect(summary.appliedBookmarks.length, 1);
      expect(await db.query('reading_progress'), hasLength(1));
      expect(await db.query('bookmarks'), hasLength(1));
    });

    test('new-device restore: cloud progress applied after documents discovered', () async {
      // Simulate discovery having just created the document locally.
      await seedBookAndDoc('book-9', 'doc-9');
      final summary = await SyncEngine.applyLocalMerge(
        db,
        progress: [progress('p9', 'doc-9', 'book-9')],
        bookmarks: [bookmark('b9', 'doc-9', 2)],
      );
      expect(summary.appliedProgress.length, 1);
      expect(summary.skippedProgress, 0);
    });

    test('orphan cloud rows (missing document) are skipped without throwing', () async {
      await seedBookAndDoc('book-1', 'doc-1');
      final summary = await SyncEngine.applyLocalMerge(
        db,
        progress: [
          progress('p1', 'doc-1', 'book-1'),
          progress('p-ghost', 'ghost-doc', 'book-1'), // references missing doc
        ],
        bookmarks: [bookmark('b-ghost', 'ghost-doc', 1)],
      );
      expect(summary.appliedProgress.length, 1);
      expect(summary.skippedProgress, 1);
      expect(summary.skippedBookmarks, 1);
      expect(await db.query('reading_progress'), hasLength(1));
    });

    test('any insertion failure rolls back ALL local changes', () async {
      await seedBookAndDoc('book-1', 'doc-1');
      final good = progress('p-good', 'doc-1', 'book-1');
      // Second row passes validation but has an unknown column -> insert throws
      // inside the transaction, which must roll back the first row too.
      final bad = {...progress('p-bad', 'doc-1', 'book-1'), 'bogusColumn': 1};

      await expectLater(
        SyncEngine.applyLocalMerge(
          db,
          progress: [good, bad],
          bookmarks: [],
        ),
        throwsA(anything),
      );

      expect(await db.query('reading_progress'), isEmpty,
          reason: 'transaction must roll back the successfully-inserted row');
    });

    test('repeated sync is idempotent (no duplicates, stable state)', () async {
      await seedBookAndDoc('book-1', 'doc-1');
      final rows = [progress('p1', 'doc-1', 'book-1')];
      final marks = [bookmark('b1', 'doc-1', 6)];

      final first = await SyncEngine.applyLocalMerge(db, progress: rows, bookmarks: marks);
      final second = await SyncEngine.applyLocalMerge(db, progress: rows, bookmarks: marks);

      expect(first.appliedProgress.length, second.appliedProgress.length);
      expect(await db.query('reading_progress'), hasLength(1));
      expect(await db.query('bookmarks'), hasLength(1));
    });

    test('existing progress/bookmarks survive a sync that adds new data', () async {
      await seedBookAndDoc('book-1', 'doc-1');
      await SyncEngine.applyLocalMerge(
        db,
        progress: [progress('p-old', 'doc-1', 'book-1')],
        bookmarks: [bookmark('b-old', 'doc-1', 1)],
      );

      // A later merge that only carries a different document must not wipe old rows.
      await seedBookAndDoc('book-2', 'doc-2');
      await SyncEngine.applyLocalMerge(
        db,
        progress: [progress('p-new', 'doc-2', 'book-2')],
        bookmarks: [bookmark('b-new', 'doc-2', 5)],
      );

      final progressIds =
          (await db.query('reading_progress')).map((r) => r['id']).toSet();
      final bookmarkIds =
          (await db.query('bookmarks')).map((r) => r['id']).toSet();
      expect(progressIds, containsAll(['p-old', 'p-new']));
      expect(bookmarkIds, containsAll(['b-old', 'b-new']));
    });
  });

  group('SyncEngine discovery-safety helpers', () {
    Map<String, dynamic> doc(String id, String driveId, DownloadStatus s) => {
          'id': id,
          'driveFileId': driveId,
          'downloadStatus': s.index,
        };

    test('isSuspiciousEmptyListing flags empty result over non-empty library', () {
      expect(
        SyncEngine.isSuspiciousEmptyListing(const [], const [{'id': 'x'}]),
        isTrue,
      );
    });

    test('isSuspiciousEmptyListing is false for a genuinely empty library', () {
      expect(SyncEngine.isSuspiciousEmptyListing(const [], const []), isFalse);
    });

    test('isSuspiciousEmptyListing is false when documents were discovered', () {
      expect(
        SyncEngine.isSuspiciousEmptyListing(
            const [{'id': 'a'}], const [{'id': 'x'}]),
        isFalse,
      );
    });

    test('documentsToDelete preserves a completed local copy of a vanished file', () {
      final existing = [
        doc('keep-me', 'drive-gone', DownloadStatus.completed),
      ];
      final toDelete = SyncEngine.documentsToDelete(existing, <String>{});
      expect(toDelete, isEmpty);
    });

    test('documentsToDelete removes only vanished, non-downloaded documents', () {
      final existing = [
        doc('present', 'drive-1', DownloadStatus.completed),
        doc('gone-not-downloaded', 'drive-2', DownloadStatus.notDownloaded),
        doc('gone-failed', 'drive-3', DownloadStatus.failed),
        doc('gone-downloaded', 'drive-4', DownloadStatus.completed),
      ];
      final current = <String>{'drive-1'}; // drive-2/3/4 vanished from Drive
      final toDelete = SyncEngine.documentsToDelete(existing, current);
      expect(toDelete, containsAll(['gone-not-downloaded', 'gone-failed']));
      expect(toDelete, isNot(contains('present')));
      expect(toDelete, isNot(contains('gone-downloaded')));
    });

    test('documentsToDelete never removes local-only docs (empty driveFileId)', () {
      final existing = [doc('local', '', DownloadStatus.completed)];
      expect(SyncEngine.documentsToDelete(existing, <String>{}), isEmpty);
    });
  });
}
