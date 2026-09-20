import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../datasources/google_drive_service.dart';
import '../services/sync_engine.dart';
import '../../domain/models/book_models.dart';
import 'download_manager.dart';

class BookRepository {
  static const _uuid = Uuid();

  /// Add a local PDF as a book (offline mode)
  /// The file will be uploaded to Drive BOOKS folder when online
  static Future<Book> addLocalBook({
    required String localFilePath,
    required String fileName,
  }) async {
    final bookId = _uuid.v4();
    final docId = _uuid.v4();
    final file = File(localFilePath);
    final fileSize = await file.length();

    final book = Book(
      id: bookId,
      driveFolderId: '', // Will be filled when synced to Drive
      sourceName: fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
      addedAt: DateTime.now(),
      syncStatus: SyncStatus.idle,
      totalDocuments: 1,
      downloadedDocuments: 1,
      totalBytes: fileSize,
      downloadedBytes: fileSize,
    );

    // Atomic: book + document in single transaction to prevent orphaned records
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      await txn.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.insert('book_documents', {
        'id': docId,
        'bookId': bookId,
        'sectionId': null,
        'driveFileId': '', // Will be filled when synced
        'sourceName': fileName,
        'localPath': localFilePath,
        'mimeType': 'application/pdf',
        'cloudModifiedAt': null,
        'localDownloadedAt': DateTime.now().toIso8601String(),
        'fileSize': fileSize,
        'downloadStatus': DownloadStatus.completed.index,
        'availabilityStatus': BookAvailability.full.index,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });

    return book;
  }

  /// Add a Drive folder as a book
  static Future<Book> addBook(DriveFile folder) async {
    // Use transaction to prevent TOCTOU race between check and insert
    final db = await DatabaseHelper.database;
    return await db.transaction<Book>((txn) async {
      final existing = await txn.query(
        'books',
        where: 'driveFolderId = ?',
        whereArgs: [folder.id],
      );
      if (existing.isNotEmpty) {
        throw Exception('This folder is already in your library');
      }

      final bookId = _uuid.v4();
      final book = Book(
        id: bookId,
        driveFolderId: folder.id,
        sourceName: folder.name,
        addedAt: DateTime.now(),
        syncStatus: SyncStatus.checking,
      );

      await txn.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
      return book;
    });
  }

  /// Add a single Drive PDF file as a book
  static Future<Book> addDriveFileAsBook(DriveFile file) async {
    if (file.mimeType != 'application/pdf') {
      throw Exception('Only PDF files can be added as books');
    }

    // Check if already added
    final existing = await DatabaseHelper.getBookByDriveFolderId(file.id);
    if (existing != null) throw Exception('This file is already in your library');

    final bookId = _uuid.v4();
    final docId = _uuid.v4();
    final title = file.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

    final book = Book(
      id: bookId,
      driveFolderId: file.id, // Store file ID in driveFolderId field
      sourceName: title,
      addedAt: DateTime.now(),
      syncStatus: SyncStatus.updated,
      totalDocuments: 1,
      downloadedDocuments: 0,
      totalBytes: file.size ?? 0,
      downloadedBytes: 0,
    );

    // Atomic: book + document in single transaction to prevent orphaned records
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      await txn.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.insert('book_documents', {
        'id': docId,
        'bookId': bookId,
        'sectionId': null,
        'driveFileId': file.id,
        'sourceName': file.name,
        'localPath': null,
        'mimeType': 'application/pdf',
        'cloudModifiedAt': file.modifiedTime?.toIso8601String(),
        'localDownloadedAt': null,
        'fileSize': file.size ?? 0,
        'downloadStatus': DownloadStatus.notDownloaded.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });

    return book;
  }

  /// Discover book structure (sections and documents)
  /// Uses atomic replacement to prevent data loss on network failure
  static Future<void> discoverBookStructure(String bookId) async {
    final bookData = await DatabaseHelper.getBook(bookId);
    if (bookData == null) return;

    final book = Book.fromMap(bookData);
    final driveFolderId = book.driveFolderId;

    // First, discover from Drive BEFORE deleting anything
    // If network fails here, existing data is preserved
    // Discover ALL subfolders at any depth so nested part→chapter structures are captured
    final subfolders = await GoogleDriveService.discoverAllSubfoldersRecursive(driveFolderId);
    int sectionOrder = 0;
    final Map<String, String> folderToSectionId = {};
    final newSections = <Map<String, dynamic>>[];

    for (final folder in subfolders) {
      final sectionId = _uuid.v4();
      folderToSectionId[folder.id] = sectionId;
      final parentSectionId = folder.parentId != null ? folderToSectionId[folder.parentId] : null;
      newSections.add({
        'id': sectionId,
        'bookId': bookId,
        'driveFolderId': folder.id,
        'parentSectionId': parentSectionId,
        'sourceName': folder.name,
        'localTitle': null,
        'sortOrder': sectionOrder++,
      });
    }

    // Discover PDFs recursively
    final pdfs = await GoogleDriveService.discoverPDFs(driveFolderId);
    int totalBytes = 0;
    final newDocuments = <Map<String, dynamic>>[];

    for (final pdf in pdfs) {
      final sectionId = folderToSectionId[pdf.parentId];
      newDocuments.add({
        'id': _uuid.v4(),
        'bookId': bookId,
        'sectionId': sectionId,
        'driveFileId': pdf.id,
        'sourceName': pdf.name,
        'localPath': null,
        'mimeType': 'application/pdf',
        'cloudModifiedAt': pdf.modifiedTime?.toIso8601String(),
        'localDownloadedAt': null,
        'fileSize': pdf.size ?? 0,
        'downloadStatus': DownloadStatus.notDownloaded.index,
        'availabilityStatus': BookAvailability.cloudOnly.index,
      });
      totalBytes += pdf.size ?? 0;
    }

    // Only after successful discovery, replace existing data
    // First, get existing download status AND IDs to preserve them
    final existingDocs = await DatabaseHelper.getDocumentsForBook(bookId);
    final downloadStatusMap = <String, Map<String, dynamic>>{};
    final existingIdMap = <String, String>{}; // driveFileId -> existing document ID
    for (final doc in existingDocs) {
      final driveFileId = doc['driveFileId'] as String? ?? '';
      if (driveFileId.isNotEmpty) {
        existingIdMap[driveFileId] = doc['id'] as String;
        downloadStatusMap[driveFileId] = {
          'localPath': doc['localPath'],
          'localDownloadedAt': doc['localDownloadedAt'],
          'downloadStatus': doc['downloadStatus'],
          'availabilityStatus': doc['availabilityStatus'],
        };
      }
    }

    // Safety: a successful-but-empty listing for a book that previously had
    // documents is treated as a transient glitch, not a real "everything was
    // deleted" — never wipe the library (and cascade local copies' progress).
    if (SyncEngine.isSuspiciousEmptyListing(newDocuments, existingDocs)) {
      return;
    }

    // Replace sections and safely diff documents without triggering CASCADE delete on progress/bookmarks
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('book_sections', where: 'bookId = ?', whereArgs: [bookId]);
      for (final section in newSections) {
        await txn.insert('book_sections', section, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // Track Drive IDs discovered in this sync
      final currentDriveIds = <String>{};

      for (final doc in newDocuments) {
        final driveFileId = doc['driveFileId'] as String;
        currentDriveIds.add(driveFileId);

        final existingId = existingIdMap[driveFileId];
        if (existingId != null) {
          doc['id'] = existingId;
          final existing = downloadStatusMap[driveFileId];
          if (existing != null) {
            doc['localPath'] = existing['localPath'];
            doc['localDownloadedAt'] = existing['localDownloadedAt'];
            final status = existing['downloadStatus'] as int;
            doc['downloadStatus'] = (status == DownloadStatus.downloading.index)
                ? DownloadStatus.notDownloaded.index
                : status;
            doc['availabilityStatus'] = existing['availabilityStatus'];
          }
          // Update existing doc in place to prevent CASCADE delete on progress/bookmarks
          await txn.update(
            'book_documents',
            doc,
            where: 'id = ?',
            whereArgs: [existingId],
          );
        } else {
          // New document discovered on Drive
          await txn.insert('book_documents', doc, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      // Delete only documents that vanished from Drive AND have no valid local
      // download. A completed offline copy is preserved (with its progress and
      // bookmarks) even if the cloud file is gone.
      final deletableIds =
          SyncEngine.documentsToDelete(existingDocs, currentDriveIds);
      for (final id in deletableIds) {
        await txn.delete('book_documents', where: 'id = ?', whereArgs: [id]);
      }

      // Recompute downloaded totals from the database so preserved offline
      // copies keep counting toward storage accurately (cloud totals come from
      // the freshly discovered Drive listing).
      final agg = await txn.rawQuery(
        'SELECT COUNT(*) AS c, COALESCE(SUM(fileSize), 0) AS b '
        'FROM book_documents WHERE bookId = ? AND downloadStatus = ?',
        [bookId, DownloadStatus.completed.index],
      );
      final downloadedCount = (agg.first['c'] as int?) ?? 0;
      final downloadedBytes = (agg.first['b'] as int?) ?? 0;

      await txn.update('books', {
        'totalDocuments': pdfs.length,
        'downloadedDocuments': downloadedCount,
        'totalBytes': totalBytes,
        'downloadedBytes': downloadedBytes,
        'syncStatus': SyncStatus.updated.index,
        'lastSyncedAt': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [bookId]);
    });
  }

  /// Get all books
  static Future<List<Book>> getAllBooks() async {
    final data = await DatabaseHelper.getAllBooks();
    return data.map((m) => Book.fromMap(m)).toList();
  }

  /// Get a single book
  static Future<Book?> getBook(String id) async {
    final data = await DatabaseHelper.getBook(id);
    return data != null ? Book.fromMap(data) : null;
  }

  /// Get sections for a book
  static Future<List<BookSection>> getSectionsForBook(String bookId) async {
    final data = await DatabaseHelper.getSectionsForBook(bookId);
    return data.map((m) => BookSection.fromMap(m)).toList();
  }

  /// Get documents for a book
  static Future<List<BookDocument>> getDocumentsForBook(String bookId) async {
    final data = await DatabaseHelper.getDocumentsForBook(bookId);
    return data.map((m) => BookDocument.fromMap(m)).toList();
  }

  /// Get documents for a section
  static Future<List<BookDocument>> getDocumentsForSection(String sectionId) async {
    final data = await DatabaseHelper.getDocumentsForSection(sectionId);
    return data.map((m) => BookDocument.fromMap(m)).toList();
  }

  /// Remove a book from the library (but not from Drive)
  static Future<void> removeBook(String bookId) async {
    // Cancel any in-progress downloads for this book's documents
    final docs = await DatabaseHelper.getDocumentsForBook(bookId);
    final dm = DownloadManager();
    for (final doc in docs) {
      await dm.cancelDownload(doc['id'] as String);
    }

    // Collect local file paths before deleting DB records
    final localPaths = <String>[];
    for (final doc in docs) {
      if (doc['localPath'] != null) {
        localPaths.add(doc['localPath'] as String);
      }
    }

    // Clean up all related data in a single transaction FIRST
    final db = await DatabaseHelper.database;
    await db.transaction((txn) async {
      for (final doc in docs) {
        await txn.delete('reading_progress', where: 'documentId = ?', whereArgs: [doc['id']]);
        await txn.delete('bookmarks', where: 'documentId = ?', whereArgs: [doc['id']]);
      }
      await txn.delete('book_sections', where: 'bookId = ?', whereArgs: [bookId]);
      await txn.delete('books', where: 'id = ?', whereArgs: [bookId]);
    });

    // Delete local files AFTER DB transaction succeeds
    // If transaction fails, files are preserved for retry
    for (final path in localPaths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best-effort cleanup — DB is already clean
      }
    }
  }

  /// Rename book locally (does not modify Drive)
  static Future<void> renameBookLocally(String bookId, String newTitle) async {
    await DatabaseHelper.updateBook(bookId, {'localTitle': newTitle});
  }

  /// Rename section locally
  static Future<void> renameSectionLocally(String sectionId, String newTitle) async {
    final db = await DatabaseHelper.database;
    await db.update('book_sections', {'localTitle': newTitle},
        where: 'id = ?', whereArgs: [sectionId]);
  }

  /// Search books, sections, documents
  static Future<List<Map<String, dynamic>>> search(String query) async {
    return await DatabaseHelper.searchAll(query);
  }

  /// Clear download data for a document (reset status, remove local path)
  /// and immediately refresh the owning book's downloaded aggregates.
  static Future<void> clearDocumentDownload(String documentId) async {
    await DatabaseHelper.removeDocumentDownload(documentId);
  }

  /// Get continue reading (last read document)
  static Future<Map<String, dynamic>?> getContinueReading() async {
    return await DatabaseHelper.getLastReadingProgress();
  }

  /// Get recently read documents
  static Future<List<Map<String, dynamic>>> getRecentlyRead() async {
    return await DatabaseHelper.getRecentlyReadDocuments();
  }

  /// Get recently added books
  static Future<List<Book>> getRecentlyAdded({int limit = 10}) async {
    final data = await DatabaseHelper.getRecentBooks(limit);
    return data.map((m) => Book.fromMap(m)).toList();
  }
}
