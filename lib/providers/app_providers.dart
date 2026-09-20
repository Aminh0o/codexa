import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/database_helper.dart';
import '../../data/datasources/google_auth_service.dart';
import '../../data/datasources/google_drive_service.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/repositories/download_manager.dart';
import '../../data/repositories/reading_progress_repository.dart';
import '../../data/services/sync_engine.dart';
import '../../domain/models/book_models.dart';

// ════════════════════════════════════════════
// SHARED PREFERENCES CACHE (single instance)
// ════════════════════════════════════════════
Future<SharedPreferences>? _prefsFuture;
SharedPreferences? _cachedPrefs;

Future<SharedPreferences> getPrefs() async {
  if (_cachedPrefs != null) return _cachedPrefs!;
  _prefsFuture ??= SharedPreferences.getInstance();
  _cachedPrefs = await _prefsFuture!;
  return _cachedPrefs!;
}

// ════════════════════════════════════════════
// CONNECTIVITY
// ════════════════════════════════════════════

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  // Emit current state first (onConnectivityChanged only emits on changes)
  final initial = await connectivity.checkConnectivity();
  yield initial.any((r) => r != ConnectivityResult.none);
  await for (final results in connectivity.onConnectivityChanged) {
    yield results.any((r) => r != ConnectivityResult.none);
  }
});

// ════════════════════════════════════════════
// THEME & LOCALE
// ════════════════════════════════════════════

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }
  Future<void> _load() async {
    try {
      final prefs = await getPrefs();
      final index = prefs.getInt(AppConstants.keyThemeMode) ?? 2;
      state = ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
    } catch (e) {
      debugPrint('[ThemeMode] Failed to load theme preference: $e');
    }
  }
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await getPrefs();
      await prefs.setInt(AppConstants.keyThemeMode, mode.index);
    } catch (e) {
      debugPrint('[ThemeMode] Failed to save theme preference: $e');
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar')) {
    _load();
  }
  Future<void> _load() async {
    try {
      final prefs = await getPrefs();
      final code = prefs.getString(AppConstants.keyLanguage) ?? 'ar';
      state = Locale(code);
    } catch (e) {
      debugPrint('[Locale] Failed to load locale preference: $e');
    }
  }
  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      final prefs = await getPrefs();
      await prefs.setString(AppConstants.keyLanguage, locale.languageCode);
    } catch (e) {
      debugPrint('[Locale] Failed to save locale preference: $e');
    }
  }
}

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) => OnboardingNotifier());

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _load();
  }
  Future<void> _load() async {
    try {
      final prefs = await getPrefs();
      state = prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;
    } catch (e) {
      debugPrint('[Onboarding] Failed to load onboarding state: $e');
    }
  }
  Future<void> completeOnboarding() async {
    state = true;
    try {
      final prefs = await getPrefs();
      await prefs.setBool(AppConstants.keyOnboardingComplete, true);
    } catch (e) {
      debugPrint('[Onboarding] Failed to save onboarding state: $e');
    }
  }
}

// ════════════════════════════════════════════
// AUTH STATE
// ════════════════════════════════════════════

enum AuthStatus { unknown, unauthenticated, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? name;
  final String? photo;
  final String? error;
  final String? booksFolderId;

  AuthState({
    this.status = AuthStatus.unknown,
    this.email,
    this.name,
    this.photo,
    this.error,
    this.booksFolderId,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? name,
    String? photo,
    String? error,
    String? booksFolderId,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      error: error ?? this.error,
      booksFolderId: booksFolderId ?? this.booksFolderId,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkAuth();
  }

  bool _ensuringBooksFolder = false;

  Future<void> _checkAuth() async {
    try {
      final isSignedIn = await GoogleAuthService.isSignedIn();
      if (isSignedIn) {
        // Don't destroy auth state when offline — keep user signed in
        // and show local library content. Token refresh will happen when online.
        final token = await GoogleAuthService.getValidAccessToken();
        if (token == null) {
          // Token expired and refresh failed (likely offline) — stay signed in
          // with local data only. Token will refresh on next successful network call.
          final email = await GoogleAuthService.getUserEmail();
          final name = await GoogleAuthService.getUserName();
          final photo = await GoogleAuthService.getUserPhoto();
          state = AuthState(
            status: AuthStatus.authenticated,
            email: email,
            name: name,
            photo: photo,
          );
          _ensureBooksFolder();
          return;
        }
        final email = await GoogleAuthService.getUserEmail();
        final name = await GoogleAuthService.getUserName();
        final photo = await GoogleAuthService.getUserPhoto();
        state = AuthState(
          status: AuthStatus.authenticated,
          email: email,
          name: name,
          photo: photo,
        );
        // Ensure BOOKS folder exists on Drive
        _ensureBooksFolder();
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> _ensureBooksFolder() async {
    if (_ensuringBooksFolder) return;
    _ensuringBooksFolder = true;
    try {
      String? folderId;
      try {
        final prefs = await getPrefs();
        folderId = prefs.getString(AppConstants.keyBooksFolderId);
      } catch (e) {
        debugPrint('[Auth] Failed to load books folder ID from cache: $e');
      }

      // Use cached folder ID without verifying online (for offline support)
      if (folderId != null) {
        state = state.copyWith(booksFolderId: folderId);
        return;
      }

      // No cached ID — only try online if we have a valid token
      final token = await GoogleAuthService.getValidAccessToken();
      if (token == null) {
        // No token available — can't create Drive folder. Use null folder ID.
        // User can still use local books.
        return;
      }

      try {
        final booksFolder = await GoogleDriveService.findOrCreateBooksFolder();
        folderId = booksFolder.id;
        try {
          final prefs = await getPrefs();
          await prefs.setString(AppConstants.keyBooksFolderId, folderId);
        } catch (e) {
          debugPrint('[Auth] Failed to save books folder ID: $e');
        }
        state = state.copyWith(booksFolderId: folderId);
      } on DriveAuthException catch (e) {
        debugPrint('Auth failed ensuring BOOKS folder: $e');
      } catch (e) {
        debugPrint('Failed to ensure BOOKS folder (offline?): $e');
      }
    } finally {
      _ensuringBooksFolder = false;
    }
  }

  void setBooksFolderId(String folderId) {
    state = state.copyWith(booksFolderId: folderId);
  }

  Future<void> signIn() async {
    try {
      state = state.copyWith(status: AuthStatus.unknown);
      final result = await GoogleAuthService.signIn();
      if (result.isSuccess) {
        state = AuthState(
          status: AuthStatus.authenticated,
          email: result.userEmail,
          name: result.userName,
          photo: result.userPhoto,
        );
        // Find or create BOOKS folder after fresh sign-in
        _ensureBooksFolder();
      } else if (result.isCancelled) {
        state = AuthState(status: AuthStatus.unauthenticated);
      } else {
        state = AuthState(
          status: AuthStatus.error,
          error: result.errorMessage,
        );
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleAuthService.signOut();
    } finally {
      try {
        final prefs = await getPrefs();
        await prefs.remove(AppConstants.keyBooksFolderId);
      } catch (e) {
        debugPrint('[Auth] Failed to remove books folder ID on sign-out: $e');
      }
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Get the cached BOOKS folder ID (synchronous)
  Future<String?> getBooksFolderId() async {
    try {
      final prefs = await getPrefs();
      return prefs.getString(AppConstants.keyBooksFolderId);
    } catch (e) {
      debugPrint('[Auth] Failed to get books folder ID: $e');
      return null;
    }
  }
}

// ════════════════════════════════════════════
// BOOKS
// ════════════════════════════════════════════

final booksProvider = StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
  return BooksNotifier(ref)..loadBooks();
});

class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final Ref _ref;
  BooksNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> loadBooks() async {
    state = const AsyncValue.loading();
    try {
      final books = await BookRepository.getAllBooks();
      state = AsyncValue.data(books);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBook(DriveFile folder) async {
    try {
      final book = await BookRepository.addBook(folder);
      await BookRepository.discoverBookStructure(book.id);
      await loadBooks();
      _ref.invalidate(downloadsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addDriveFileAsBook(DriveFile file) async {
    try {
      await BookRepository.addDriveFileAsBook(file);
      await loadBooks();
      _ref.invalidate(downloadsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addLocalBook(String localFilePath, String fileName) async {
    try {
      await BookRepository.addLocalBook(
        localFilePath: localFilePath,
        fileName: fileName,
      );
      await loadBooks();
      _ref.invalidate(downloadsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncLocalBookToDrive(String bookId) async {
    try {
      final book = await BookRepository.getBook(bookId);
      if (book == null || book.driveFolderId.isNotEmpty) return;

      String? booksFolderId;
      try {
        final prefs = await getPrefs();
        booksFolderId = prefs.getString(AppConstants.keyBooksFolderId);
      } catch (e) {
        debugPrint('[Books] Failed to load books folder ID for sync: $e');
      }
      if (booksFolderId == null) {
        debugPrint('Cannot sync book $bookId: no BOOKS folder ID');
        return;
      }

      // Create a folder for this book inside BOOKS
      final bookFolder = await GoogleDriveService.createFolder(
        book.sourceName,
        parentId: booksFolderId,
      );

      // Get the local document
      final docs = await BookRepository.getDocumentsForBook(bookId);
      if (docs.isEmpty) return;

      final doc = docs.first;
      if (doc.localPath == null) return;

      // Upload the file
      final fileBytes = await File(doc.localPath!).readAsBytes();
      final uploadedFile = await GoogleDriveService.uploadFile(
        fileName: doc.sourceName,
        bytes: fileBytes,
        mimeType: 'application/pdf',
        parentId: bookFolder.id,
      );

      // Update book and document with Drive IDs
      await DatabaseHelper.updateBook(bookId, {
        'driveFolderId': bookFolder.id,
        'syncStatus': SyncStatus.updated.index,
      });
      await DatabaseHelper.updateDocument(doc.id, {
        'driveFileId': uploadedFile.id,
      });

      await loadBooks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeBook(String bookId) async {
    await BookRepository.removeBook(bookId);
    await loadBooks();
    _ref.invalidate(downloadsProvider);
    _ref.invalidate(downloadCountsProvider);
  }

  Future<void> refresh() async => loadBooks();
}

// ════════════════════════════════════════════
// BOOK DETAIL
// ════════════════════════════════════════════

final bookDetailProvider = FutureProvider.family<BookDetailState?, String>((ref, bookId) async {
  final results = await Future.wait([
    BookRepository.getBook(bookId),
    BookRepository.getSectionsForBook(bookId),
    BookRepository.getDocumentsForBook(bookId),
  ]);
  final book = results[0] as Book?;
  if (book == null) return null;
  final sections = results[1] as List<BookSection>;
  final documents = results[2] as List<BookDocument>;
  return BookDetailState(book: book, sections: sections, documents: documents);
});

class BookDetailState {
  final Book book;
  final List<BookSection> sections;
  final List<BookDocument> documents;

  BookDetailState({
    required this.book,
    required this.sections,
    required this.documents,
  });
}

// ════════════════════════════════════════════
// CONTINUE READING
// ════════════════════════════════════════════

final continueReadingProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await ReadingProgressRepository.getContinueReading();
});

// ════════════════════════════════════════════
// SEARCH
// ════════════════════════════════════════════

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty || query.length < 2) return [];

  final completer = Completer<List<Map<String, dynamic>>>();
  final timer = Timer(const Duration(milliseconds: 300), () async {
    try {
      final results = await BookRepository.search(query);
      if (!completer.isCompleted) completer.complete(results);
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }
  });

  ref.onDispose(() {
    timer.cancel();
    if (!completer.isCompleted) completer.completeError(StateError('Disposed'));
  });

  return completer.future;
});

// ════════════════════════════════════════════
// DOWNLOADS
// ════════════════════════════════════════════

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final dm = DownloadManager();
  Timer? debounce;
  final sub = dm.progressStream.listen((_) {
    // Throttle invalidation to avoid excessive DB reads on every progress tick
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 1), () {
      ref.invalidate(downloadsProvider);
      ref.invalidate(downloadCountsProvider);
    });
  });
  ref.onDispose(() {
    debounce?.cancel();
    sub.cancel();
  });
  return dm;
});

final downloadsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DownloadManager.getAllDownloads();
});

final downloadCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await DownloadManager.getDownloadCounts();
});

// ════════════════════════════════════════════
// DRIVE BROWSING
// ════════════════════════════════════════════

final driveFolderProvider =
    FutureProvider.family<DriveListState, String?>((ref, folderId) async {
  return await DriveBrowseState.load(folderId);
});

class DriveListState {
  final List<DriveFile> folders;
  final List<DriveFile> files;
  final String? nextPageToken;
  final bool hasMore;

  DriveListState({
    required this.folders,
    required this.files,
    this.nextPageToken,
    this.hasMore = false,
  });

  static Future<DriveListState> load(String? folderId) async {
    final result = await GoogleDriveService.listFolder(folderId: folderId);
    return DriveListState(
      folders: result.files.where((f) => f.isFolder).toList(),
      files: result.files.where((f) => !f.isFolder).toList(),
      nextPageToken: result.nextPageToken,
      hasMore: result.nextPageToken != null,
    );
  }
}

// Alias for convenience
typedef DriveBrowseState = DriveListState;

// ════════════════════════════════════════════
// SYNC
// ════════════════════════════════════════════

// NOTE: Sync now implements bidirectional sync for reading progress and bookmarks via `.codexa_sync.json`.
// It merges remote and local states by timestamp (`lastOpenedAt`).

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});

class SyncState {
  final bool isSyncing;
  final String? currentBookId;
  final double progress;
  final String? error;

  SyncState({
    this.isSyncing = false,
    this.currentBookId,
    this.progress = 0,
    this.error,
  });
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(SyncState());

  Future<void> syncBook(String bookId) async {
    state = SyncState(isSyncing: true, currentBookId: bookId);
    try {
      await BookRepository.discoverBookStructure(bookId);
      state = SyncState(isSyncing: false);
    } catch (e) {
      state = SyncState(error: e.toString());
    }
  }

  Future<void> syncAll() async {
    state = SyncState(isSyncing: true);
    try {
      final prefs = await getPrefs();
      final booksFolderId = prefs.getString(AppConstants.keyBooksFolderId);
      if (booksFolderId == null) throw Exception('No books folder found');

      // 1. Discover structure FIRST so newly-referenced documents exist locally.
      //    This is required for new-device restoration and prevents the merge
      //    below from touching rows whose documents are not yet present.
      final db = await DatabaseHelper.database;
      final books = await BookRepository.getAllBooks();
      for (int i = 0; i < books.length; i++) {
        state = SyncState(
          isSyncing: true,
          currentBookId: books[i].id,
          progress: (i + 1) / (books.length + 1),
        );
        await BookRepository.discoverBookStructure(books[i].id);
      }

      // 2. Deterministically select the single authoritative metadata file
      //    (newest modifiedTime, tie-broken by id) — never an arbitrary duplicate.
      final candidates = await GoogleDriveService.listFilesByName(
        '.codexa_sync.json',
        parentId: booksFolderId,
      );
      final authoritative = SyncEngine.selectAuthoritativeSyncFile(candidates);

      // 3. Load remote metadata from the authoritative file only.
      Map<String, dynamic>? remoteData;
      if (authoritative != null) {
        final bytes = await GoogleDriveService.downloadFile(authoritative.id);
        remoteData = jsonDecode(utf8.decode(bytes));
      }

      // 4. Merge local + remote — newer local or remote rows are never discarded.
      final localProgress = await db.query('reading_progress');
      final localBookmarks = await db.query('bookmarks');
      final mergedProgress = SyncEngine.mergeProgress(
        localProgress, remoteData?['progress'] as List? ?? const []);
      final mergedBookmarks = SyncEngine.mergeBookmarks(
        localBookmarks, remoteData?['bookmarks'] as List? ?? const []);

      // 5. Apply the merge to SQLite atomically: validates referenced documents,
      //    skips orphans, and rolls back ALL local changes on any failure.
      await SyncEngine.applyLocalMerge(
        db,
        progress: mergedProgress.values.toList(),
        bookmarks: mergedBookmarks.values.toList(),
      );

      // 6. Publish the full merged view back to Drive, updating the authoritative
      //    file in place so exactly one generation always exists. Pushing the
      //    complete merged set (not just locally-applied rows) means other
      //    devices' cloud data is never lost by this device's partial state.
      final finalData = {
        'progress': mergedProgress.values.toList(),
        'bookmarks': mergedBookmarks.values.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      final payload = utf8.encode(jsonEncode(finalData));
      final String authoritativeId;
      if (authoritative != null) {
        await GoogleDriveService.updateFileBytes(authoritative.id, payload);
        authoritativeId = authoritative.id;
      } else {
        final created = await GoogleDriveService.uploadFile(
          fileName: '.codexa_sync.json',
          bytes: payload,
          mimeType: 'application/json',
          parentId: booksFolderId,
        );
        authoritativeId = created.id;
      }

      // 7. Consolidate duplicates deterministically: delete every non-authoritative
      //    candidate. Cleanup failures are reported, never silently swallowed.
      for (final f in candidates.where((f) => f.id != authoritativeId)) {
        try {
          await GoogleDriveService.deleteFile(f.id);
        } catch (e) {
          debugPrint('[Sync] failed to remove duplicate metadata ${f.id}: $e');
        }
      }

      state = SyncState();
    } catch (e) {
      state = SyncState(error: e.toString());
    }
  }
}
