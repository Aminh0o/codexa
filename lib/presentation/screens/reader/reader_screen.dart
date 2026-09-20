import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/repositories/reading_progress_repository.dart';
import '../../../data/services/pdf_search_service.dart';
import '../../../providers/app_providers.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String documentId;
  final String documentTitle;
  final String bookTitle;
  final String bookId;
  final String localPath;

  const ReaderScreen({
    super.key,
    required this.documentId,
    required this.documentTitle,
    required this.bookTitle,
    required this.bookId,
    required this.localPath,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  bool _chromeVisible = true;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isCurrentPageBookmarked = false;
  bool _pageTurnAnimation = true;
  bool _showProgressBar = false;
  PdfViewerController? _controller;
  PdfDocumentRef? _documentRef;
  Timer? _saveTimer;
  Timer? _bookmarkLoadTimer;
  bool _hasUnsavedProgress = false;
  int? _pendingRestorePage;

  // Enhanced reader state
  double _rotationAngle = 0;
  bool _nightMode = false;
  List<PdfOutlineNode>? _outline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSettings();
      _loadBookmarks();
      _loadDocument();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  void _loadDocument() {
    _documentRef = PdfDocumentRefFile(widget.localPath);
  }

  Future<void> _restoreProgress() async {
    if (_controller == null || !mounted) return;
    try {
      final progress = await ReadingProgressRepository.getProgress(widget.documentId);
      if (progress != null && progress.currentPage > 0 && mounted) {
        if (_totalPages == 0) {
          _pendingRestorePage = progress.currentPage;
          return;
        }
        final targetPage = progress.currentPage.clamp(1, _totalPages);
        setState(() {
          _currentPage = targetPage;
        });
        _controller!.goToPage(pageNumber: targetPage);
        _loadBookmarks();
      }
    } catch (e) {
      debugPrint('Failed to restore reading progress: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await getPrefs();
      if (!mounted) return;
      setState(() {
        _pageTurnAnimation = prefs.getBool(AppConstants.keyPageTurnAnimation) ?? true;
        _showProgressBar = prefs.getBool(AppConstants.keyShowProgressBar) ?? false;
        _nightMode = prefs.getBool(AppConstants.keyNightMode) ?? false;
        _rotationAngle = prefs.getDouble(AppConstants.keyRotationAngle) ?? 0;
      });
    } catch (e) {
      debugPrint('Failed to load reader settings: $e');
    }
  }

  Future<void> _saveNightMode(bool value) async {
    try {
      final prefs = await getPrefs();
      await prefs.setBool(AppConstants.keyNightMode, value);
    } catch (e) {
      debugPrint('Failed to save night mode: $e');
    }
  }

  Future<void> _saveRotationAngle(double angle) async {
    try {
      final prefs = await getPrefs();
      await prefs.setDouble(AppConstants.keyRotationAngle, angle);
    } catch (e) {
      debugPrint('Failed to save rotation angle: $e');
    }
  }

  Future<void> _loadBookmarks() async {
    _bookmarkLoadTimer?.cancel();
    _bookmarkLoadTimer = Timer(const Duration(milliseconds: 300), () async {
      final bookmarks = await ReadingProgressRepository.getBookmarks(widget.documentId);
      if (mounted) {
        setState(() {
          _isCurrentPageBookmarked = bookmarks.any((b) => b.page == _currentPage);
        });
      }
    });
  }

  void _toggleChrome() {
    setState(() {
      _chromeVisible = !_chromeVisible;
    });
  }

  void _scheduleSave() {
    _hasUnsavedProgress = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveProgress();
    });
  }

  void _saveProgress() {
    if (!_hasUnsavedProgress || _totalPages == 0) return;
    final documentId = widget.documentId;
    final bookId = widget.bookId;
    final currentPage = _currentPage;
    final totalPages = _totalPages;
    ReadingProgressRepository.saveProgress(
      documentId: documentId,
      bookId: bookId,
      currentPage: currentPage,
      totalPages: totalPages,
    ).then((_) {
      _hasUnsavedProgress = false;  // only clear on success
      // Invalidate continue reading provider after successful save
      if (mounted) {
        ref.invalidate(continueReadingProvider);
      }
    }).catchError((e) {
      debugPrint('Failed to save reading progress: $e');
      // flag stays true → next _scheduleSave() will retry
    });
  }

  void _goToPage(int page) {
    if (_controller != null && page >= 1 && page <= _totalPages) {
      _controller!.goToPage(pageNumber: page);
      setState(() {
        _currentPage = page;
      });
      _loadBookmarks();
      _scheduleSave();
    }
  }

  Future<void> _toggleBookmark() async {
    final l10n = AppLocalizations.of(context);
    final wasBookmarked = _isCurrentPageBookmarked;
    HapticFeedback.lightImpact();
    setState(() {
      _isCurrentPageBookmarked = !wasBookmarked;
    });
    try {
      if (wasBookmarked) {
        final bookmarks = await ReadingProgressRepository.getBookmarks(widget.documentId);
        final bookmark = bookmarks.where((b) => b.page == _currentPage).firstOrNull;
        if (bookmark != null) {
          await ReadingProgressRepository.removeBookmark(bookmark.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bookmarkRemoved), duration: const Duration(seconds: 1)),
          );
        }
      } else {
        await ReadingProgressRepository.addBookmark(
          documentId: widget.documentId,
          page: _currentPage,
          label: '${l10n.page} $_currentPage',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bookmarkAdded), duration: const Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCurrentPageBookmarked = wasBookmarked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.genericError}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Enhanced Reader Actions ──

  void _rotateLeft() {
    setState(() {
      _rotationAngle = (_rotationAngle - pi / 2) % (2 * pi);
    });
    _saveRotationAngle(_rotationAngle);
  }

  void _rotateRight() {
    setState(() {
      _rotationAngle = (_rotationAngle + pi / 2) % (2 * pi);
    });
    _saveRotationAngle(_rotationAngle);
  }

  void _toggleNightMode() {
    setState(() {
      _nightMode = !_nightMode;
    });
    _saveNightMode(_nightMode);
  }

  void _showGoToPageDialog() {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    var disposed = false;
    void safeDispose() {
      if (!disposed) {
        disposed = true;
        try { controller.dispose(); } catch (_) {}
      }
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.goToPage),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '${l10n.enterPageNumber} (1-$_totalPages)',
              border: const OutlineInputBorder(),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (value) {
              final page = int.tryParse(value);
              if (page != null && page >= 1 && page <= _totalPages) {
                _goToPage(page);
                safeDispose();
                Navigator.of(ctx).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                safeDispose();
                Navigator.of(ctx).pop();
              },
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final page = int.tryParse(controller.text);
                if (page != null && page >= 1 && page <= _totalPages) {
                  _goToPage(page);
                  safeDispose();
                  Navigator.of(ctx).pop();
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    ).then((_) => safeDispose());
  }

  void _showSearchDialog() {
    final l10n = AppLocalizations.of(context);
    final searchController = TextEditingController();
    var disposed = false;
    void safeDispose() {
      if (!disposed) {
        disposed = true;
        try { searchController.dispose(); } catch (_) {}
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool isSearching = false;
          List<PdfSearchResult> results = [];
          String? error;

          return AlertDialog(
            title: Text(l10n.search),
            content: SizedBox(
              width: double.maxFinite,
              height: AppConstants.responsiveDialogHeight(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                         icon: const Icon(LucideIcons.search),
                        onPressed: () async {
                          final query = searchController.text.trim();
                          if (query.isEmpty || widget.localPath.isEmpty) return;
                          setDialogState(() {
                            isSearching = true;
                            error = null;
                          });
                          try {
                            final searchResults = await PdfSearchService.searchInPdf(
                              widget.localPath,
                              query,
                              maxResults: 50,
                            );
                            if (ctx.mounted) {
                              setDialogState(() {
                                results = searchResults;
                                isSearching = false;
                              });
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setDialogState(() {
                                error = e.toString();
                                isSearching = false;
                              });
                            }
                          }
                        },
                      ),
                    ),
                    onSubmitted: (_) async {
                      final query = searchController.text.trim();
                      if (query.isEmpty || widget.localPath.isEmpty) return;
                      setDialogState(() {
                        isSearching = true;
                        error = null;
                      });
                      try {
                        final searchResults = await PdfSearchService.searchInPdf(
                          widget.localPath,
                          query,
                          maxResults: 50,
                        );
                        if (ctx.mounted) {
                          setDialogState(() {
                            results = searchResults;
                            isSearching = false;
                          });
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() {
                            error = e.toString();
                            isSearching = false;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isSearching)
                    const CircularProgressIndicator()
                  else if (error != null)
                    Text(
                      error!,
                      style: TextStyle(color: AppColors.error),
                    )
                  else if (results.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              result.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium(context),
                            ),
                            subtitle: Text(
                              '${l10n.page} ${result.pageNumber}',
                              style: AppTextStyles.labelSmall(context),
                            ),
                            onTap: () {
                              safeDispose();
                              Navigator.of(ctx).pop();
                              _goToPage(result.pageNumber);
                            },
                          );
                        },
                      ),
                    )
                  else if (searchController.text.isNotEmpty && !isSearching)
                    Text(
                      l10n.noResults,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  safeDispose();
                  Navigator.of(ctx).pop();
                },
                child: Text(l10n.cancel),
              ),
            ],
          );
        },
      ),
    ).then((_) => safeDispose());
  }

  void _showOutlineDialog() {
    final l10n = AppLocalizations.of(context);
    if (_outline == null || _outline!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tableOfContentsTitle)),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tableOfContentsTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: AppConstants.responsiveDialogHeight(context),
          child: _buildOutlineList(_outline!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineList(List<PdfOutlineNode> nodes) {
    // Flatten the outline tree into a single list with depth info
    final flatItems = <({PdfOutlineNode node, int depth})>[];
    void flatten(List<PdfOutlineNode> nodeList, int depth) {
      for (final node in nodeList) {
        flatItems.add((node: node, depth: depth));
        if (node.children.isNotEmpty) {
          flatten(node.children, depth + 1);
        }
      }
    }
    flatten(nodes, 0);

    return ListView.builder(
      shrinkWrap: true,
      itemCount: flatItems.length,
      itemBuilder: (context, index) {
        final item = flatItems[index];
        return ListTile(
          contentPadding: EdgeInsetsDirectional.only(start: 16.0 + item.depth * 16.0),
          title: Text(
            item.node.title,
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontSize: 13 - item.depth * 0.5,
              fontWeight: item.node.children.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          dense: true,
          onTap: () {
            if (item.node.dest != null) {
              _goToPage(item.node.dest!.pageNumber);
            }
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _loadOutline(PdfDocument document) async {
    try {
      final outline = await document.loadOutline();
      if (mounted) {
        setState(() {
          _outline = outline;
        });
      }
    } catch (e) {
      debugPrint('Failed to load outline: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _bookmarkLoadTimer?.cancel();
    // Save synchronously while widget is still alive (documentId is valid)
    if (_hasUnsavedProgress && _totalPages > 0) {
      _saveProgress();
    }
    // Release PDF document reference to free memory on low-end devices
    _documentRef = null;
    super.dispose();
  }

  // Save progress when app goes to background (before OS may kill process)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _nightMode
        ? Colors.black
        : (isDark ? AppColors.darkSurface : AppColors.surface);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasUnsavedProgress) {
          _saveProgress();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
        children: [
          // Top Chrome
          AnimatedOpacity(
            opacity: _chromeVisible ? 1.0 : 0.0,
            duration: _pageTurnAnimation
                ? const Duration(milliseconds: 200)
                : Duration.zero,
            child: _chromeVisible
                ? _TopChrome(
                    documentTitle: widget.documentTitle,
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    isBookmarked: _isCurrentPageBookmarked,
                    libraryLabel: AppLocalizations.of(context).navLibrary,
                    onBack: () => Navigator.of(context).pop(),
                    onBookmark: _toggleBookmark,
                    onMenuPressed: _showReaderMenu,
                  )
                : const SizedBox.shrink(),
          ),

          // PDF Viewer
          Expanded(
            child: GestureDetector(
              onTap: _toggleChrome,
              child: _documentRef != null
                  ? _buildPdfViewer(bgColor)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),

          // Progress Bar
          if (_showProgressBar && _totalPages > 0 && _chromeVisible)
            LinearProgressIndicator(
              value: _totalPages > 0 ? _currentPage / _totalPages : 0,
              backgroundColor: (_nightMode || isDark)
                  ? AppColors.darkOutlineVariant
                  : AppColors.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                (_nightMode || isDark) ? AppColors.darkTertiary : AppColors.antiqueGold,
              ),
              minHeight: 2,
            ),

          // Bottom Chrome
          AnimatedOpacity(
            opacity: _chromeVisible ? 1.0 : 0.0,
            duration: _pageTurnAnimation
                ? const Duration(milliseconds: 200)
                : Duration.zero,
            child: _chromeVisible && _totalPages > 0
                ? _BottomChrome(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    onPageChanged: _goToPage,
                    onGoToPage: _showGoToPageDialog,
                    onRotateLeft: _rotateLeft,
                    onRotateRight: _rotateRight,
                    onNightMode: _toggleNightMode,
                    nightMode: _nightMode,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPdfViewer(Color bgColor) {
    Widget viewer = PdfViewer(
      _documentRef!,
      params: PdfViewerParams(
        onPageChanged: (pageNumber) {
          if (pageNumber != null) {
            HapticFeedback.selectionClick();
            setState(() {
              _currentPage = pageNumber;
            });
            _scheduleSave();
            _loadBookmarks();
          }
        },
        onDocumentChanged: (document) {
          if (document != null) {
            setState(() {
              _totalPages = document.pages.length;
            });
            _loadOutline(document);
            if (_pendingRestorePage != null && _controller != null) {
              final targetPage = _pendingRestorePage!.clamp(1, _totalPages);
              _pendingRestorePage = null;
              setState(() {
                _currentPage = targetPage;
              });
              _controller!.goToPage(pageNumber: targetPage);
              _loadBookmarks();
            }
          }
        },
        onViewerReady: (document, controller) {
          _controller = controller;
          _restoreProgress();
        },
        backgroundColor: bgColor,
        margin: 0,
        errorBannerBuilder: (context, error, stackTrace, documentRef) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Icon(LucideIcons.alertTriangle, size: 48,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).genericError,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall(context),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Apply night mode color inversion — invert RGB channels for dark reading
    if (_nightMode) {
      viewer = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1, 0, 0, 0, 1,
          0, -1, 0, 0, 1,
          0, 0, -1, 0, 1,
          0, 0, 0, 1, 0,
        ]),
        child: viewer,
      );
    }

    // Apply rotation
    if (_rotationAngle != 0) {
      viewer = Transform.rotate(
        angle: _rotationAngle,
        child: viewer,
      );
    }

    return viewer;
  }

  void _showReaderMenu() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
               leading: Icon(LucideIcons.bookmark, color: isDark ? AppColors.darkTertiary : AppColors.antiqueGold),
              title: Text(l10n.bookmark),
              subtitle: Text(_isCurrentPageBookmarked ? l10n.bookmarkAdded : '${l10n.page} $_currentPage'),
              onTap: () {
                Navigator.of(ctx).pop();
                _toggleBookmark();
              },
            ),
            ListTile(
               leading: const Icon(LucideIcons.list),
              title: Text(l10n.tableOfContentsTitle),
              subtitle: Text(_outline != null ? '${_outline!.length} ${l10n.contents}' : ''),
              onTap: () {
                Navigator.of(ctx).pop();
                _showOutlineDialog();
              },
            ),
            ListTile(
               leading: const Icon(LucideIcons.search),
              title: Text(l10n.search),
              onTap: () {
                Navigator.of(ctx).pop();
                _showSearchDialog();
              },
            ),
            const Divider(),
            ListTile(
               leading: const Icon(LucideIcons.rotateCcw),
              title: Text(l10n.rotateLeft),
              onTap: () {
                Navigator.of(ctx).pop();
                _rotateLeft();
              },
            ),
            ListTile(
               leading: const Icon(LucideIcons.rotateCw),
              title: Text(l10n.rotateRight),
              onTap: () {
                Navigator.of(ctx).pop();
                _rotateRight();
              },
            ),
            const Divider(),
            ListTile(
               leading: Icon(_nightMode ? LucideIcons.sun : LucideIcons.moon),
              title: Text(_nightMode ? l10n.lightMode : l10n.nightMode),
              onTap: () {
                Navigator.of(ctx).pop();
                _toggleNightMode();
              },
            ),
            ListTile(
               leading: const Icon(LucideIcons.file),
              title: Text(l10n.goToPage),
              subtitle: Text('${l10n.page} $_currentPage ${l10n.ofText} $_totalPages'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showGoToPageDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// TOP CHROME
// ════════════════════════════════════════════

class _TopChrome extends StatelessWidget {
  final String documentTitle;
  final int currentPage;
  final int totalPages;
  final bool isBookmarked;
  final String libraryLabel;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final VoidCallback onMenuPressed;

  const _TopChrome({
    required this.documentTitle,
    required this.currentPage,
    required this.totalPages,
    required this.isBookmarked,
    required this.libraryLabel,
    required this.onBack,
    required this.onBookmark,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: AppConstants.gutter, top: 16, end: AppConstants.gutter, bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.95) : AppColors.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Go back',
            button: true,
            child: IconButton(
               icon: Icon(LucideIcons.arrowLeft,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
              onPressed: onBack,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  documentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMedium(context),
                ),
                Text(
                  '$libraryLabel  ·  $currentPage / $totalPages',
                  style: AppTextStyles.labelSmall(context),
                ),
              ],
            ),
          ),
          Semantics(
            label: isBookmarked ? 'Remove bookmark' : 'Bookmark page',
            button: true,
            child: IconButton(
              icon: Icon(
                 isBookmarked ? LucideIcons.bookmark : LucideIcons.bookmark,
                color: isDark ? AppColors.darkTertiary : AppColors.antiqueGold,
              ),
              onPressed: onBookmark,
            ),
          ),
          Semantics(
            label: 'Reader menu',
            button: true,
            child: IconButton(
               icon: Icon(LucideIcons.moreVertical,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
              onPressed: onMenuPressed,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// BOTTOM CHROME
// ════════════════════════════════════════════

class _BottomChrome extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final void Function(int) onPageChanged;
  final VoidCallback onGoToPage;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onNightMode;
  final bool nightMode;

  const _BottomChrome({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onGoToPage,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onNightMode,
    required this.nightMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppConstants.gutter, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.95) : AppColors.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$currentPage',
                  style: AppTextStyles.labelSmall(context),
                  textAlign: TextAlign.end,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    inactiveTrackColor: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                    thumbColor: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    overlayColor: (isDark ? AppColors.darkOnSurface : AppColors.onSurface).withValues(alpha: 0.1),
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: currentPage.toDouble().clamp(1.0, totalPages.toDouble()),
                    min: 1,
                    max: totalPages.toDouble(),
                    onChanged: (value) => onPageChanged(value.round()),
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$totalPages',
                  style: AppTextStyles.labelSmall(context),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionChip(
                 icon: LucideIcons.rotateCcw,
                onTap: onRotateLeft,
                semanticsLabel: 'Rotate left',
              ),
              const SizedBox(width: 8),
              _ActionChip(
                 icon: nightMode ? LucideIcons.sun : LucideIcons.moon,
                onTap: onNightMode,
                semanticsLabel: 'Night mode',
              ),
              const SizedBox(width: 8),
              _ActionChip(
                 icon: LucideIcons.rotateCw,
                onTap: onRotateRight,
                semanticsLabel: 'Rotate right',
              ),
              const SizedBox(width: 8),
              _ActionChip(
                 icon: LucideIcons.file,
                onTap: onGoToPage,
                semanticsLabel: 'Go to page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// ACTION CHIP
// ════════════════════════════════════════════

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticsLabel;

  const _ActionChip({
    required this.icon,
    required this.onTap,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.parchmentCard,
            border: Border.all(
              color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
