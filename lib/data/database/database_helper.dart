import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/book_models.dart';

/// Codexa SQLite Database Helper
/// Manages all local persistence for books, documents, progress, bookmarks
class DatabaseHelper {
  static Database? _database;
  static Completer<Database>? _completer;
  static String? _testDatabasePath;

  @visibleForTesting
  static void setTestDatabasePath(String path) {
    _testDatabasePath = path;
  }

  /// Reset database state (for testing)
  static void reset() {
    _database = null;
    _completer = null;
    _testDatabasePath = null;
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    if (_completer != null) return _completer!.future;
    
    final completer = Completer<Database>();
    _completer = completer;
    try {
      _database = await _initDatabase();
      completer.complete(_database!);
      _completer = null;
      return _database!;
    } catch (e) {
      completer.completeError(e);
      _completer = null;
      rethrow;
    }
  }

  static Future<Database> _initDatabase() async {
    final path = _testDatabasePath ?? join(await getDatabasesPath(), AppConstants.databaseName);
    final db = await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
      await db.rawQuery('PRAGMA journal_mode = WAL');
    },
    );
    return db;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        driveFolderId TEXT NOT NULL,
        sourceName TEXT NOT NULL,
        localTitle TEXT,
        coverPath TEXT,
        addedAt TEXT NOT NULL,
        lastSyncedAt TEXT,
        syncStatus INTEGER NOT NULL DEFAULT 0,
        totalDocuments INTEGER NOT NULL DEFAULT 0,
        downloadedDocuments INTEGER NOT NULL DEFAULT 0,
        totalBytes INTEGER NOT NULL DEFAULT 0,
        downloadedBytes INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE book_sections (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        driveFolderId TEXT NOT NULL,
        parentSectionId TEXT,
        sourceName TEXT NOT NULL,
        localTitle TEXT,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE,
        FOREIGN KEY (parentSectionId) REFERENCES book_sections(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE book_documents (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        sectionId TEXT,
        driveFileId TEXT NOT NULL,
        sourceName TEXT NOT NULL,
        localPath TEXT,
        mimeType TEXT NOT NULL DEFAULT 'application/pdf',
        cloudModifiedAt TEXT,
        localDownloadedAt TEXT,
        fileSize INTEGER NOT NULL DEFAULT 0,
        downloadStatus INTEGER NOT NULL DEFAULT 0,
        availabilityStatus INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE,
        FOREIGN KEY (sectionId) REFERENCES book_sections(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_progress (
        id TEXT PRIMARY KEY,
        documentId TEXT NOT NULL UNIQUE,
        bookId TEXT NOT NULL,
        currentPage INTEGER NOT NULL DEFAULT 0,
        totalPages INTEGER NOT NULL DEFAULT 0,
        progressPercent REAL NOT NULL DEFAULT 0.0,
        lastOpenedAt TEXT NOT NULL,
        FOREIGN KEY (documentId) REFERENCES book_documents(id) ON DELETE CASCADE,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        documentId TEXT NOT NULL,
        page INTEGER NOT NULL,
        label TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (documentId) REFERENCES book_documents(id) ON DELETE CASCADE,
        UNIQUE(documentId, page)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_operations (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        documentId TEXT,
        operationType INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        progress REAL NOT NULL DEFAULT 0.0,
        startedAt TEXT NOT NULL,
        completedAt TEXT,
        errorCode TEXT,
        retryCount INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_books_drive_folder ON books(driveFolderId)');
    await db.execute('CREATE INDEX idx_sections_book ON book_sections(bookId)');
    await db.execute('CREATE INDEX idx_documents_book ON book_documents(bookId)');
    await db.execute('CREATE INDEX idx_documents_section ON book_documents(sectionId)');
    await db.execute('CREATE INDEX idx_documents_drive_file ON book_documents(driveFileId)');
    await db.execute('CREATE INDEX idx_progress_document ON reading_progress(documentId)');
    await db.execute('CREATE INDEX idx_progress_lastOpened ON reading_progress(lastOpenedAt)');
    await db.execute('CREATE INDEX idx_bookmarks_document ON bookmarks(documentId)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Recreate bookmarks table with UNIQUE constraint on (documentId, page)
      // Use temp table to preserve existing bookmarks (data-safe migration)
      await db.execute('''
        CREATE TABLE bookmarks_new (
          id TEXT PRIMARY KEY,
          documentId TEXT NOT NULL,
          page INTEGER NOT NULL,
          label TEXT,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (documentId) REFERENCES book_documents(id) ON DELETE CASCADE,
          UNIQUE(documentId, page)
        )
      ''');
      // Copy existing data (ignore duplicates if any)
      await db.execute('INSERT OR IGNORE INTO bookmarks_new SELECT * FROM bookmarks');
      await db.execute('DROP TABLE bookmarks');
      await db.execute('ALTER TABLE bookmarks_new RENAME TO bookmarks');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_bookmarks_document ON bookmarks(documentId)');
    }
    if (oldVersion < 3) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_progress_lastOpened ON reading_progress(lastOpenedAt)');
    }
  }

  // ════════════════════════════════════════════
  // BOOK OPERATIONS
  // ════════════════════════════════════════════

  static Future<void> insertBook(Map<String, dynamic> book) async {
    final db = await database;
    await db.insert('books', book, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> updateBook(String id, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update('books', updates, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteBook(String id) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, dynamic>?> getBook(String id) async {
    final db = await database;
    final results = await db.query('books', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  static Future<List<Map<String, dynamic>>> getAllBooks() async {
    final db = await database;
    return await db.query('books', orderBy: 'addedAt DESC');
  }

  static Future<List<Map<String, dynamic>>> getRecentBooks(int limit) async {
    final db = await database;
    return await db.query('books', orderBy: 'addedAt DESC', limit: limit);
  }

  static Future<Map<String, dynamic>?> getBookByDriveFolderId(String driveFolderId) async {
    final db = await database;
    final results = await db.query(
      'books',
      where: 'driveFolderId = ?',
      whereArgs: [driveFolderId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ════════════════════════════════════════════
  // SECTION OPERATIONS
  // ════════════════════════════════════════════

  static Future<void> insertSection(Map<String, dynamic> section) async {
    final db = await database;
    await db.insert('book_sections', section, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<List<Map<String, dynamic>>> getSectionsForBook(String bookId) async {
    final db = await database;
    return await db.query(
      'book_sections',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'sortOrder ASC',
    );
  }

  static Future<void> deleteSectionsForBook(String bookId) async {
    final db = await database;
    await db.delete('book_sections', where: 'bookId = ?', whereArgs: [bookId]);
  }

  // ════════════════════════════════════════════
  // DOCUMENT OPERATIONS
  // ════════════════════════════════════════════

  static Future<void> insertDocument(Map<String, dynamic> document) async {
    final db = await database;
    await db.insert('book_documents', document, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> updateDocument(String id, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update('book_documents', updates, where: 'id = ?', whereArgs: [id]);
  }

  /// Remove a document's local download AND immediately recompute its book's
  /// downloaded aggregates in a single atomic transaction, so Settings storage
  /// reflects the change without waiting for a later sync/download.
  static Future<void> removeDocumentDownload(String documentId) async {
    final db = await database;
    await db.transaction((txn) async {
      final found = await txn.query(
        'book_documents',
        columns: ['bookId'],
        where: 'id = ?',
        whereArgs: [documentId],
      );
      if (found.isEmpty) return;
      final bookId = found.first['bookId'] as String;

      await txn.update(
        'book_documents',
        {
          'downloadStatus': DownloadStatus.notDownloaded.index,
          'availabilityStatus': BookAvailability.cloudOnly.index,
          'localPath': null,
          'localDownloadedAt': null,
          'fileSize': 0,
        },
        where: 'id = ?',
        whereArgs: [documentId],
      );

      final docs = await txn.query(
        'book_documents',
        columns: ['downloadStatus', 'fileSize'],
        where: 'bookId = ?',
        whereArgs: [bookId],
      );
      int downloadedCount = 0;
      int downloadedBytes = 0;
      for (final d in docs) {
        if ((d['downloadStatus'] as int) == DownloadStatus.completed.index) {
          downloadedCount++;
          downloadedBytes += (d['fileSize'] as int?) ?? 0;
        }
      }
      await txn.update('books', {
        'downloadedDocuments': downloadedCount,
        'downloadedBytes': downloadedBytes,
      }, where: 'id = ?', whereArgs: [bookId]);
    });
  }

  static Future<List<Map<String, dynamic>>> getDocumentsForBook(String bookId) async {
    final db = await database;
    return await db.query(
      'book_documents',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'sourceName ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getDocumentsForSection(String sectionId) async {
    final db = await database;
    return await db.query(
      'book_documents',
      where: 'sectionId = ?',
      whereArgs: [sectionId],
      orderBy: 'sourceName ASC',
    );
  }

  static Future<Map<String, dynamic>?> getDocument(String id) async {
    final db = await database;
    final results = await db.query('book_documents', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  static Future<Map<String, dynamic>?> getDocumentByDriveFileId(String driveFileId) async {
    final db = await database;
    final results = await db.query(
      'book_documents',
      where: 'driveFileId = ?',
      whereArgs: [driveFileId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<void> deleteDocumentsForBook(String bookId) async {
    final db = await database;
    await db.delete('book_documents', where: 'bookId = ?', whereArgs: [bookId]);
  }

  static Future<List<Map<String, dynamic>>> searchDocuments(String query) async {
    final db = await database;
    // Escape backslashes first, then LIKE wildcards to treat them as literals
    final escapedQuery = query.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
    return await db.query(
      'book_documents',
      where: 'sourceName LIKE ? ESCAPE \'\\\'',
      whereArgs: ['%$escapedQuery%'],
      orderBy: 'sourceName ASC',
    );
  }

  // ════════════════════════════════════════════
  // READING PROGRESS OPERATIONS
  // ════════════════════════════════════════════

  static Future<void> upsertReadingProgress(Map<String, dynamic> progress) async {
    final db = await database;
    await db.insert('reading_progress', progress, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getReadingProgress(String documentId) async {
    final db = await database;
    final results = await db.query(
      'reading_progress',
      where: 'documentId = ?',
      whereArgs: [documentId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<Map<String, dynamic>?> getLastReadingProgress() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT rp.*, bd.sourceName as documentName, bd.localPath, b.sourceName as bookName, b.localTitle
      FROM reading_progress rp
      JOIN book_documents bd ON rp.documentId = bd.id
      JOIN books b ON rp.bookId = b.id
      ORDER BY rp.lastOpenedAt DESC
      LIMIT 1
    ''');
    return results.isNotEmpty ? results.first : null;
  }

  static Future<List<Map<String, dynamic>>> getRecentlyReadDocuments() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT rp.*, bd.sourceName as documentName, bd.localPath, b.sourceName as bookName, b.localTitle
      FROM reading_progress rp
      JOIN book_documents bd ON rp.documentId = bd.id
      JOIN books b ON rp.bookId = b.id
      ORDER BY rp.lastOpenedAt DESC
      LIMIT 10
    ''');
  }

  // ════════════════════════════════════════════
  // BOOKMARK OPERATIONS
  // ════════════════════════════════════════════

  static Future<void> insertBookmark(Map<String, dynamic> bookmark) async {
    final db = await database;
    await db.insert('bookmarks', bookmark, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deleteBookmark(String id) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getBookmarksForDocument(String documentId) async {
    final db = await database;
    return await db.query(
      'bookmarks',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'page ASC',
    );
  }

  static Future<bool> isPageBookmarked(String documentId, int page) async {
    final db = await database;
    final results = await db.query(
      'bookmarks',
      where: 'documentId = ? AND page = ?',
      whereArgs: [documentId, page],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  // ════════════════════════════════════════════
  // SEARCH OPERATIONS
  // ════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final db = await database;
    // Escape backslashes first, then LIKE wildcards to treat them as literals
    final escaped = query.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
    final searchPattern = '%$escaped%';

    final books = await db.query(
      'books',
      where: "(sourceName LIKE ? ESCAPE '\\' OR localTitle LIKE ? ESCAPE '\\')",
      whereArgs: [searchPattern, searchPattern],
    );

    final sections = await db.rawQuery('''
      SELECT bs.*, b.sourceName as bookName
      FROM book_sections bs
      JOIN books b ON bs.bookId = b.id
      WHERE (bs.sourceName LIKE ? ESCAPE '\\' OR bs.localTitle LIKE ? ESCAPE '\\')
    ''', [searchPattern, searchPattern]);

    final documents = await db.rawQuery('''
      SELECT bd.*, b.sourceName as bookName, bs.sourceName as sectionName
      FROM book_documents bd
      JOIN books b ON bd.bookId = b.id
      LEFT JOIN book_sections bs ON bd.sectionId = bs.id
      WHERE bd.sourceName LIKE ? ESCAPE '\\'
    ''', [searchPattern]);

    return [
      ...books.map((e) => {...e, 'type': 'book'}),
      ...sections.map((e) => {...e, 'type': 'section'}),
      ...documents.map((e) => {...e, 'type': 'document'}),
    ].take(50).toList();
  }

  // ════════════════════════════════════════════
  // STORAGE OPERATIONS
  // ════════════════════════════════════════════

  static Future<int> getTotalStorageUsed() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(totalBytes) as total FROM books');
    return (result.first['total'] as int?) ?? 0;
  }

  static Future<int> getDownloadedStorageUsed() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(downloadedBytes) as total FROM books');
    return (result.first['total'] as int?) ?? 0;
  }

  /// Reset stale download states (e.g., stuck in 'downloading', 'queued' or
  /// 'paused' after force-close). 'paused' cannot survive a restart (the
  /// in-memory queue is gone), so it is reset to a truthful 'notDownloaded'.
  static Future<void> resetStaleDownloads() async {
    final db = await database;
    await db.update(
      'book_documents',
      {'downloadStatus': DownloadStatus.notDownloaded.index},
      where: 'downloadStatus = ? OR downloadStatus = ? OR downloadStatus = ?',
      whereArgs: [
        DownloadStatus.downloading.index,
        DownloadStatus.queued.index,
        DownloadStatus.paused.index,
      ],
    );
  }
}
