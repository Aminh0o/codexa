import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../datasources/google_drive_service.dart';
import '../../domain/models/book_models.dart';

enum DownloadQueueState { idle, downloading, paused }

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._();
  factory DownloadManager() => _instance;
  DownloadManager._();

  final _queue = <String>[];
  final _cancelledIds = <String>{};
  final _progressController = StreamController<DownloadProgress>.broadcast();
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  DownloadQueueState _state = DownloadQueueState.idle;
  DownloadQueueState get state => _state;

  /// Queue a document for download
  Future<void> queueDownload(String documentId) async {
    if (_queue.contains(documentId)) return;
    _queue.add(documentId);
    await DatabaseHelper.updateDocument(documentId, {
      'downloadStatus': DownloadStatus.queued.index,
    });
    _processQueue();
  }

  /// Queue a document for download by document object
  Future<void> queueDocumentDownload(BookDocument doc) async {
    await queueDownload(doc.id);
  }

  /// Queue all documents in a book
  Future<void> queueBookDownload(String bookId) async {
    final docs = await DatabaseHelper.getDocumentsForBook(bookId);
    for (final doc in docs) {
      if ((doc['downloadStatus'] as int) == DownloadStatus.notDownloaded.index ||
          (doc['downloadStatus'] as int) == DownloadStatus.failed.index) {
        await queueDownload(doc['id'] as String);
      }
    }
  }

  /// Cancel a specific download (does not affect other downloads)
  Future<void> cancelDownload(String documentId) async {
    _queue.remove(documentId);
    _cancelledIds.add(documentId);
    await DatabaseHelper.updateDocument(documentId, {
      'downloadStatus': DownloadStatus.notDownloaded.index,
    });
    _progressController.add(DownloadProgress(
      documentId: documentId,
      status: DownloadStatus.notDownloaded,
      progress: 0,
    ));
  }

  /// Retry a failed download
  Future<void> retryDownload(String documentId) async {
    await queueDownload(documentId);
  }

  /// Pause all downloads
  Future<void> pauseDownloads() async {
    _state = DownloadQueueState.paused;
    _progressController.add(DownloadProgress(
      documentId: '',
      status: DownloadStatus.paused,
      progress: 0,
    ));
  }

  /// Resume all downloads
  Future<void> resumeDownloads() async {
    if (_state == DownloadQueueState.paused) {
      _state = DownloadQueueState.idle;
      _processQueue();
    }
  }

  /// Process the download queue
  Future<void> _processQueue() async {
    if (_state == DownloadQueueState.downloading) return;
    if (_state == DownloadQueueState.paused) return;
    if (_queue.isEmpty) return;

    _state = DownloadQueueState.downloading;

    try {
      while (_queue.isNotEmpty) {
        // Check if paused — stop processing but keep state as paused
        if (_state == DownloadQueueState.paused) break;

        final documentId = _queue.first;
        
        // Skip cancelled downloads
        if (_cancelledIds.contains(documentId)) {
          _cancelledIds.remove(documentId);
          _queue.remove(documentId);
          continue;
        }
        
        final outcome = await _downloadDocument(documentId);

        // A paused document stays at the head of the queue so Resume restarts it.
        if (outcome == DownloadStatus.paused) break;

        _queue.remove(documentId);
      }
    } finally {
      // Only reset to idle if not paused
      if (_state != DownloadQueueState.paused) {
        _state = DownloadQueueState.idle;
      }
    }
  }

  /// Download a single document using streaming to disk (no memory OOM)
  Future<DownloadStatus> _downloadDocument(String documentId) async {
    final docData = await DatabaseHelper.getDocument(documentId);
    if (docData == null) return DownloadStatus.notDownloaded;

    final doc = BookDocument.fromMap(docData);

    // Skip local-only books (no Drive file ID)
    if (doc.driveFileId.isEmpty) {
      await DatabaseHelper.updateDocument(documentId, {
        'downloadStatus': DownloadStatus.completed.index,
      });
      _progressController.add(DownloadProgress(
        documentId: documentId,
        status: DownloadStatus.completed,
        progress: 1.0,
      ));
      return DownloadStatus.completed;
    }

    String? filePath;
    try {
      // Check if cancelled before starting
      if (_cancelledIds.contains(documentId)) {
        _cancelledIds.remove(documentId);
        await DatabaseHelper.updateDocument(documentId, {
          'downloadStatus': DownloadStatus.notDownloaded.index,
        });
        return DownloadStatus.notDownloaded;
      }

      await DatabaseHelper.updateDocument(documentId, {
        'downloadStatus': DownloadStatus.downloading.index,
      });
      _progressController.add(DownloadProgress(
        documentId: documentId,
        status: DownloadStatus.downloading,
        progress: 0,
      ));

      // Get local storage directory
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(p.join(appDir.path, 'codexa', 'books'));
      await booksDir.create(recursive: true);

      filePath = p.join(booksDir.path, '${doc.id}.pdf');

      // Stream download directly to disk (no memory OOM)
      await GoogleDriveService.downloadFileToDisk(
        doc.driveFileId,
        filePath,
        onProgress: (progress) {
          // Check cancellation or pause during download — return false to abort
          if (_cancelledIds.contains(documentId) ||
              _state == DownloadQueueState.paused) {
            return false; // Signal abort to stop streaming
          }
          _progressController.add(DownloadProgress(
            documentId: documentId,
            status: DownloadStatus.downloading,
            progress: progress,
          ));
          return true;
        },
      );

      // Cancelled exactly at the completion boundary — honor it, never mark done.
      if (_cancelledIds.contains(documentId)) {
        _cancelledIds.remove(documentId);
        final file = File(filePath);
        if (await file.exists()) await file.delete();
        await DatabaseHelper.updateDocument(documentId, {
          'downloadStatus': DownloadStatus.notDownloaded.index,
        });
        return DownloadStatus.notDownloaded;
      }
      // Paused exactly at the completion boundary — treat as paused, not done.
      if (_state == DownloadQueueState.paused) {
        final file = File(filePath);
        if (await file.exists()) await file.delete();
        await DatabaseHelper.updateDocument(documentId, {
          'downloadStatus': DownloadStatus.paused.index,
        });
        _progressController.add(DownloadProgress(
          documentId: documentId,
          status: DownloadStatus.paused,
          progress: 0,
        ));
        return DownloadStatus.paused;
      }

      // Update database
      await DatabaseHelper.updateDocument(documentId, {
        'localPath': filePath,
        'localDownloadedAt': DateTime.now().toIso8601String(),
        'downloadStatus': DownloadStatus.completed.index,
        'availabilityStatus': BookAvailability.full.index,
        'fileSize': await File(filePath).length(),
      });

      // Update book stats
      await _updateBookDownloadStats(doc.bookId);

      _progressController.add(DownloadProgress(
        documentId: documentId,
        status: DownloadStatus.completed,
        progress: 1.0,
      ));
      return DownloadStatus.completed;
    } catch (e) {
      // A pause/cancel surfaces here as an abort exception — it is NOT a failure.
      // Only genuine errors (network, disk, auth) mark the item failed.
      if (filePath != null) {
        final partial = File(filePath);
        if (await partial.exists()) await partial.delete();
      }

      if (_cancelledIds.contains(documentId)) {
        _cancelledIds.remove(documentId);
        await DatabaseHelper.updateDocument(documentId, {
          'downloadStatus': DownloadStatus.notDownloaded.index,
        });
        _progressController.add(DownloadProgress(
          documentId: documentId,
          status: DownloadStatus.notDownloaded,
          progress: 0,
        ));
        return DownloadStatus.notDownloaded;
      }
      if (_state == DownloadQueueState.paused) {
        await DatabaseHelper.updateDocument(documentId, {
          'downloadStatus': DownloadStatus.paused.index,
        });
        _progressController.add(DownloadProgress(
          documentId: documentId,
          status: DownloadStatus.paused,
          progress: 0,
        ));
        return DownloadStatus.paused;
      }

      await DatabaseHelper.updateDocument(documentId, {
        'downloadStatus': DownloadStatus.failed.index,
      });
      _progressController.add(DownloadProgress(
        documentId: documentId,
        status: DownloadStatus.failed,
        progress: 0,
        error: e.toString(),
      ));
      return DownloadStatus.failed;
    }
  }

  /// Update book download statistics
  Future<void> _updateBookDownloadStats(String bookId) async {
    final docs = await DatabaseHelper.getDocumentsForBook(bookId);
    int downloaded = 0;
    int downloadedBytes = 0;

    for (final doc in docs) {
      if ((doc['downloadStatus'] as int) == DownloadStatus.completed.index) {
        downloaded++;
        downloadedBytes += (doc['fileSize'] as int?) ?? 0;
      }
    }

    await DatabaseHelper.updateBook(bookId, {
      'downloadedDocuments': downloaded,
      'downloadedBytes': downloadedBytes,
    });
  }

  /// Get all downloads with their status
  static Future<List<Map<String, dynamic>>> getAllDownloads() async {
    final db = await DatabaseHelper.database;
    return await db.rawQuery('''
      SELECT bd.*, b.sourceName as bookName, b.localTitle as bookLocalTitle
      FROM book_documents bd
      JOIN books b ON bd.bookId = b.id
      WHERE bd.downloadStatus != 0
      ORDER BY bd.downloadStatus ASC, bd.sourceName ASC
    ''');
  }

  /// Get download count by status
  static Future<Map<String, int>> getDownloadCounts() async {
    final db = await DatabaseHelper.database;
    final results = await db.rawQuery('''
      SELECT downloadStatus, COUNT(*) as count
      FROM book_documents
      GROUP BY downloadStatus
    ''');
    final counts = <String, int>{
      'downloaded': 0,
      'downloading': 0,
      'queued': 0,
      'paused': 0,
      'failed': 0,
    };
    for (final row in results) {
      final statusIndex = row['downloadStatus'] as int;
      if (statusIndex < 0 || statusIndex >= DownloadStatus.values.length) continue;
      final status = DownloadStatus.values[statusIndex];
      switch (status) {
        case DownloadStatus.completed:
          counts['downloaded'] = row['count'] as int;
        case DownloadStatus.downloading:
          counts['downloading'] = row['count'] as int;
        case DownloadStatus.queued:
          counts['queued'] = row['count'] as int;
        case DownloadStatus.paused:
          counts['paused'] = row['count'] as int;
        case DownloadStatus.failed:
          counts['failed'] = row['count'] as int;
        default:
          break;
      }
    }
    return counts;
  }

  void dispose() {
    _progressController.close();
  }
}

class DownloadProgress {
  final String documentId;
  final DownloadStatus status;
  final double progress;
  final String? error;

  DownloadProgress({
    required this.documentId,
    required this.status,
    required this.progress,
    this.error,
  });
}
