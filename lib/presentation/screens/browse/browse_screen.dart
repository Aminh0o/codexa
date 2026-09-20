import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/datasources/google_drive_service.dart';
import '../../../data/database/database_helper.dart';
import '../../../providers/app_providers.dart';
import '../../navigation/main_navigation_shell.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final List<_BreadcrumbItem> _breadcrumbs = [];
  String? _currentFolderId;
  bool _isLoading = false;
  List<DriveFile> _folders = [];
  List<DriveFile> _files = [];
  String? _error;
  bool _hasMore = false;
  String? _nextPageToken;
  AuthStatus _lastAuthStatus = AuthStatus.unknown;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initialized = true;
      _initBrowse();
    });
  }

  void _onAuthChanged(AuthStatus newStatus) {
    if (!mounted) return;
    if (newStatus == AuthStatus.authenticated && _lastAuthStatus != AuthStatus.authenticated) {
      // Just signed in — reset and re-init
      setState(() {
        _breadcrumbs.clear();
        _currentFolderId = null;
        _folders = [];
        _files = [];
        _error = null;
      });
      _initBrowse();
    } else if (newStatus != AuthStatus.authenticated && _lastAuthStatus == AuthStatus.authenticated) {
      // Signed out — clear
      setState(() {
        _breadcrumbs.clear();
        _currentFolderId = null;
        _folders = [];
        _files = [];
        _error = 'not_connected';
      });
    }
    _lastAuthStatus = newStatus;
  }

  Future<void> _initBrowse() async {
    if (!mounted) return;
    // Try to get the BOOKS folder ID from auth state or SharedPreferences
    String? booksFolderId;
    try {
      final authState = ref.read(authProvider);
      booksFolderId = authState.booksFolderId;
    } catch (_) {
      // Widget may be deactivated
      return;
    }

    if (booksFolderId == null) {
      // Fallback: read from SharedPreferences
      final prefs = await getPrefs();
      booksFolderId = prefs.getString(AppConstants.keyBooksFolderId);
    }

    if (!mounted) return;
    if (booksFolderId != null) {
      // Verify the folder still exists
      try {
        final folder = await GoogleDriveService.getFile(booksFolderId);
        if (!mounted) return;
        if (folder != null) {
          _breadcrumbs.add(_BreadcrumbItem(id: booksFolderId, name: AppConstants.booksFolderName));
          _loadFolder(booksFolderId);
          return;
        }
      } catch (_) {
        // Folder verification failed — will try to recreate below
      }
    }

    // No BOOKS folder found — show error or create it
    if (!mounted) return;
    _showNoConnectionOrRoot();
  }

  void _showNoConnectionOrRoot() {
    if (!mounted) return;
    AuthStatus authStatus;
    try {
      authStatus = ref.read(authProvider).status;
    } catch (_) {
      return;
    }
    if (authStatus != AuthStatus.authenticated) {
      setState(() {
        _error = 'not_connected';
      });
      return;
    }
    // Authenticated but no BOOKS folder — try to create it
    _createBooksFolderAndBrowse();
  }

  Future<void> _createBooksFolderAndBrowse() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final booksFolder = await GoogleDriveService.findOrCreateBooksFolder();
      final prefs = await getPrefs();
      await prefs.setString(AppConstants.keyBooksFolderId, booksFolder.id);
      ref.read(authProvider.notifier).setBooksFolderId(booksFolder.id);
      _breadcrumbs.add(_BreadcrumbItem(id: booksFolder.id, name: AppConstants.booksFolderName));
      _loadFolder(booksFolder.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFolder(String? folderId, {String? pageToken}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await GoogleDriveService.listFolder(
        folderId: folderId,
        pageToken: pageToken,
      );
      if (!mounted) return;
      setState(() {
        if (pageToken == null) {
          _folders = result.files.where((f) => f.isFolder).toList();
          _files = result.files.where((f) => !f.isFolder).toList();
        } else {
          _folders.addAll(result.files.where((f) => f.isFolder));
          _files.addAll(result.files.where((f) => !f.isFolder));
        }
        _hasMore = result.nextPageToken != null;
        _nextPageToken = result.nextPageToken;
        _currentFolderId = folderId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToFolder(DriveFile folder) {
    HapticFeedback.selectionClick();
    _breadcrumbs.add(_BreadcrumbItem(id: folder.id, name: folder.name));
    _loadFolder(folder.id);
  }

  void _navigateToBreadcrumb(int index) {
    final item = _breadcrumbs[index];
    _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
    _currentFolderId = item.id;
    _loadFolder(item.id);
  }

  Future<void> _addAsBook(DriveFile folder) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(booksProvider.notifier).addBook(folder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.folderAdded(folder.name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.genericError}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _addFileAsBook(DriveFile file) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(booksProvider.notifier).addDriveFileAsBook(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.folderAdded(file.name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.genericError}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _downloadDriveFile(DriveFile file) async {
    if (file.mimeType != 'application/pdf') return;
    final l10n = AppLocalizations.of(context);
    try {
      // Route through the provider to ensure DB consistency
      await ref.read(booksProvider.notifier).addDriveFileAsBook(file);

      // Find the document we just created to queue download
      final existing = await DatabaseHelper.getBookByDriveFolderId(file.id);
      if (existing != null) {
        final docs = await DatabaseHelper.getDocumentsForBook(existing['id'] as String);
        if (docs.isNotEmpty) {
          final dm = ref.read(downloadManagerProvider);
          await dm.queueDownload(docs.first['id'] as String);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.downloadQueued)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.downloadFailed(e.toString())), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for auth changes (must be in build for ConsumerWidget)
    ref.listen(authProvider, (prev, next) {
      if (_initialized) _onAuthChanged(next.status);
    });

    // Check connectivity
    final connectivityAsync = ref.watch(connectivityProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      body: Column(
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsetsDirectional.only(start: AppConstants.responsiveMargin(context), top: 12, end: AppConstants.responsiveMargin(context), bottom: 0),
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    height: 40,
                    child: Image.asset(
                      'assets/logos/header_logo_full.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                         LucideIcons.bookOpen,
                        size: 32,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.stackSm),
                // ── Breadcrumbs ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: AppConstants.stackSm),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant, width: 0.5,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_breadcrumbs.length, (i) {
                        final item = _breadcrumbs[i];
                        final isLast = i == _breadcrumbs.length - 1;
                        final displayName = item.id == null ? l10n.myDrive : item.name;
                        return Row(
                          children: [
                            if (i > 0) ...[
                              Icon(
                                 LucideIcons.chevronRight,
                                size: 16,
                                color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                              ),
                              const SizedBox(width: 4),
                            ],
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: isLast ? null : () => _navigateToBreadcrumb(i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                child: Semantics(
                                  label: isLast ? displayName : 'Navigate to $displayName',
                                  button: !isLast,
                                  child: Text(
                                    displayName,
                                    style: AppTextStyles.labelSmall(context).copyWith(
                                      fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                                      color: isLast
                                          ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                                          : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: connectivityAsync.when(
              data: (isConnected) {
                if (!isConnected) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                           LucideIcons.cloudOff,
                          size: 48,
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.notConnected,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.connectToBrowseDrive,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSmall(context).copyWith(
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (_isLoading && _folders.isEmpty && _files.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                           _error == 'not_connected' ? LucideIcons.cloudOff : LucideIcons.alertTriangle,
                          size: 48,
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error == 'not_connected'
                              ? l10n.notConnected
                              : _error!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_error == 'not_connected')
                          OutlinedButton(
                            onPressed: () {
                              ref.read(currentTabProvider.notifier).state = 3;
                            },
                            child: Text(l10n.signIn),
                          )
                        else
                          OutlinedButton(
                            onPressed: () {
                              if (_currentFolderId != null) {
                                _loadFolder(_currentFolderId);
                              } else {
                                _initBrowse();
                              }
                            },
                            child: Text(l10n.retry),
                          ),
                      ],
                    ),
                  );
                }
                if (_folders.isEmpty && _files.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Icon(LucideIcons.library, size: 48,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(l10n.thisFolderIsEmpty, style: AppTextStyles.titleMedium(context).copyWith(
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        )),
                        const SizedBox(height: 8),
                        Text(
                          _currentFolderId != null && _breadcrumbs.isNotEmpty && _breadcrumbs.first.id == _currentFolderId
                              ? l10n.addBookFoldersFromDrive
                              : '',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppConstants.responsiveMargin(context),
                    vertical: AppConstants.stackMd,
                  ),
                  children: [
                    // Folders
                    if (_folders.isNotEmpty) ...[
                      Text(l10n.folders.toUpperCase(), style: AppTextStyles.labelSmall(context).copyWith(
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      )),
                      const SizedBox(height: 8),
                      ..._folders.map((folder) => _DriveItemTile(
                        file: folder,
                        onTap: () => _navigateToFolder(folder),
                        onAddBook: () => _addAsBook(folder),
                      )),
                      const SizedBox(height: AppConstants.stackMd),
                    ],
                    // Files
                    if (_files.isNotEmpty) ...[
                      Text(l10n.files.toUpperCase(), style: AppTextStyles.labelSmall(context).copyWith(
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      )),
                      const SizedBox(height: 8),
                      ..._files.map((file) => _DriveItemTile(
                        file: file,
                        onAddBook: () => _addFileAsBook(file),
                        onDownload: () => _downloadDriveFile(file),
                      )),
                    ],
                    // Load more
                    if (_hasMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : OutlinedButton(
                                  onPressed: () => _loadFolder(_currentFolderId, pageToken: _nextPageToken),
                                  child: Text(l10n.loadMore),
                                ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                       LucideIcons.alertTriangle,
                      size: 48,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.genericError,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        if (_currentFolderId != null) {
                          _loadFolder(_currentFolderId);
                        } else {
                          _initBrowse();
                        }
                      },
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbItem {
  final String? id;
  final String name;
  _BreadcrumbItem({required this.id, required this.name});
}

class _DriveItemTile extends StatelessWidget {
  final DriveFile file;
  final VoidCallback? onTap;
  final VoidCallback? onAddBook;
  final VoidCallback? onDownload;

  const _DriveItemTile({
    required this.file,
    this.onTap,
    this.onAddBook,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFolder = file.isFolder;

    return Semantics(
      label: '${file.name}${isFolder ? ', folder' : ', PDF file'}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant, width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                 isFolder ? LucideIcons.folder : LucideIcons.fileText,
                color: isFolder
                    ? (isDark ? AppColors.darkTertiary : AppColors.antiqueGold)
                    : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name, style: AppTextStyles.bodyMedium(context).copyWith(
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (!isFolder)
                      Text(l10n.pdfLabel, style: AppTextStyles.labelSmall(context).copyWith(
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      )),
                  ],
                ),
              ),
              if (isFolder && onAddBook != null)
                IconButton(
                   icon: Icon(LucideIcons.plusCircle, size: 20,
                      color: isDark ? AppColors.darkTertiary : AppColors.antiqueGold),
                  onPressed: onAddBook,
                  tooltip: l10n.addToLibrary,
                )
              else if (isFolder)
                 Icon(LucideIcons.chevronRight,
                    color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant)
              else if (!isFolder) ...[
                if (onAddBook != null)
                  IconButton(
                     icon: Icon(LucideIcons.plusCircle, size: 18,
                        color: isDark ? AppColors.darkTertiary : AppColors.antiqueGold),
                    onPressed: onAddBook,
                    tooltip: l10n.addToLibrary,
                  ),
                if (onDownload != null)
                  IconButton(
                     icon: Icon(LucideIcons.download, size: 18,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                    onPressed: onDownload,
                    tooltip: l10n.download,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
