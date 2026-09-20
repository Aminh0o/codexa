import 'package:sqflite/sqflite.dart';
import '../datasources/google_drive_service.dart';
import '../../domain/models/book_models.dart';

/// Result of applying a validated, atomic sync merge to local SQLite.
class SyncMergeSummary {
  final List<Map<String, dynamic>> appliedProgress;
  final List<Map<String, dynamic>> appliedBookmarks;
  final int skippedProgress;
  final int skippedBookmarks;

  const SyncMergeSummary({
    required this.appliedProgress,
    required this.appliedBookmarks,
    this.skippedProgress = 0,
    this.skippedBookmarks = 0,
  });
}

/// Pure, network-free synchronization logic.
///
/// Kept free of Google Drive / Riverpod so it can be unit-tested directly and
/// reused by [SyncNotifier]. All functions are side-effect free except
/// [applyLocalMerge], which writes to SQLite inside a single transaction.
class SyncEngine {
  /// Decide whether a discovery result is a suspicious empty listing that must
  /// NOT be applied as a destructive replace: Drive reported zero documents
  /// while the local library already had some. Treating this as a transient
  /// glitch (instead of "the user deleted everything") preserves the library,
  /// its offline copies, reading progress and bookmarks.
  static bool isSuspiciousEmptyListing(
    List<dynamic> discoveredDocuments,
    List<dynamic> existingDocuments,
  ) {
    return discoveredDocuments.isEmpty && existingDocuments.isNotEmpty;
  }

  /// Return the ids of documents that may be safely deleted after a discovery
  /// diff. A document is only removable when its Drive file has disappeared AND
  /// it is not a completed local download — a valid offline copy (and the
  /// reading progress / bookmarks that cascade from it) is always preserved.
  static List<String> documentsToDelete(
    List<Map<String, dynamic>> existingDocs,
    Set<String> currentDriveIds,
  ) {
    final toDelete = <String>[];
    for (final doc in existingDocs) {
      final driveId = doc['driveFileId'] as String? ?? '';
      if (driveId.isEmpty || currentDriveIds.contains(driveId)) continue;
      final completedLocally =
          (doc['downloadStatus'] as int) == DownloadStatus.completed.index;
      if (completedLocally) continue; // never destroy a valid local copy
      toDelete.add(doc['id'] as String);
    }
    return toDelete;
  }

  /// Deterministically pick the single authoritative sync-metadata file.
  ///
  /// Rule: newest `modifiedTime` wins; exact ties are broken by the greatest
  /// `id`. Files without a usable timestamp are treated as oldest. Returns
  /// null only when there are no candidates. This guarantees that duplicate
  /// `.codexa_sync.json` files never cause an arbitrary (possibly stale) copy
  /// to be selected.
  static DriveFile? selectAuthoritativeSyncFile(List<DriveFile> files) {
    DriveFile? best;
    for (final f in files) {
      if (best == null) {
        best = f;
        continue;
      }
      final a = f.modifiedTime;
      final b = best.modifiedTime;
      if (a == null && b == null) {
        if (f.id.compareTo(best.id) > 0) best = f;
        continue;
      }
      if (a == null) continue; // candidate older than best (best has a time)
      if (b == null) {
        best = f; // candidate has a time, best does not
        continue;
      }
      if (a.isAfter(b) ||
          (a.isAtSameMomentAs(b) && f.id.compareTo(best.id) > 0)) {
        best = f;
      }
    }
    return best;
  }

  /// Merge local + remote reading progress keyed by `documentId`.
  ///
  /// Newer `lastOpenedAt` always wins; neither newer-local nor newer-remote
  /// data is ever discarded.
  static Map<String, Map<String, dynamic>> mergeProgress(
    List<Map<String, dynamic>> local,
    List remote,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final p in local) {
      final docId = p['documentId'];
      if (docId is String) merged[docId] = p;
    }
    for (final item in remote) {
      if (item is! Map) continue;
      final rp = Map<String, dynamic>.from(item);
      final docId = rp['documentId'];
      if (docId is! String) continue;
      final existing = merged[docId];
      if (existing == null) {
        merged[docId] = rp;
        continue;
      }
      final localTime =
          DateTime.tryParse(existing['lastOpenedAt']?.toString() ?? '');
      final remoteTime = DateTime.tryParse(rp['lastOpenedAt']?.toString() ?? '');
      if (localTime == null) {
        merged[docId] = rp; // unparseable local → accept remote
      } else if (remoteTime != null && remoteTime.isAfter(localTime)) {
        merged[docId] = rp;
      }
    }
    return merged;
  }

  /// Merge local + remote bookmarks keyed by bookmark `id` (union by identity).
  static Map<String, Map<String, dynamic>> mergeBookmarks(
    List<Map<String, dynamic>> local,
    List remote,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final b in local) {
      final id = b['id'];
      if (id is String) merged[id] = b;
    }
    for (final item in remote) {
      if (item is! Map) continue;
      final rb = Map<String, dynamic>.from(item);
      final id = rb['id'];
      if (id is String) merged[id] = rb;
    }
    return merged;
  }

  /// Atomically apply merged progress/bookmarks to SQLite.
  ///
  /// * Runs in a single transaction — any failure rolls back ALL local changes.
  /// * Validates that every referenced document (and, for progress, book) still
  ///   exists before inserting, so orphaned cloud rows cannot throw an FK error
  ///   and abort the whole sync.
  /// * Idempotent — re-applying the same rows yields the same database state.
  /// * Never deletes existing local rows, so progress/bookmarks survive sync.
  static Future<SyncMergeSummary> applyLocalMerge(
    Database db, {
    required List<Map<String, dynamic>> progress,
    required List<Map<String, dynamic>> bookmarks,
  }) async {
    final appliedProgress = <Map<String, dynamic>>[];
    final appliedBookmarks = <Map<String, dynamic>>[];
    int skippedProgress = 0;
    int skippedBookmarks = 0;

    await db.transaction((txn) async {
      final docRows = await txn.query('book_documents', columns: ['id']);
      final existingDocs = docRows.map((r) => r['id'] as String).toSet();
      final bookRows = await txn.query('books', columns: ['id']);
      final existingBooks = bookRows.map((r) => r['id'] as String).toSet();

      for (final p in progress) {
        final docId = p['documentId'];
        final bookId = p['bookId'];
        final docOk = docId is String && existingDocs.contains(docId);
        final bookOk = bookId is String && existingBooks.contains(bookId);
        if (!docOk || !bookOk) {
          skippedProgress++;
          continue;
        }
        await txn.insert('reading_progress', p,
            conflictAlgorithm: ConflictAlgorithm.replace);
        appliedProgress.add(p);
      }

      for (final b in bookmarks) {
        final docId = b['documentId'];
        if (docId is! String || !existingDocs.contains(docId)) {
          skippedBookmarks++;
          continue;
        }
        await txn.insert('bookmarks', b,
            conflictAlgorithm: ConflictAlgorithm.replace);
        appliedBookmarks.add(b);
      }
    });

    return SyncMergeSummary(
      appliedProgress: appliedProgress,
      appliedBookmarks: appliedBookmarks,
      skippedProgress: skippedProgress,
      skippedBookmarks: skippedBookmarks,
    );
  }
}
