import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../domain/models/book_models.dart';
import '../../../providers/app_providers.dart';
import '../reader/reader_screen.dart';
import '../../widgets/empty_state.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  static const int _pageSize = 20;
  int _visibleBookCount = _pageSize;
  bool _isPaused = false;
  final Set<String> _expandedBooks = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDownloads();
    });
  }

  Future<void> _loadDownloads() async {
    if (!mounted) return;
    setState(() {
      _visibleBookCount = _pageSize;
    });
    ref.invalidate(downloadsProvider);
    ref.invalidate(downloadCountsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadsAsync = ref.watch(downloadsProvider);
    final countsAsync = ref.watch(downloadCountsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      body: Column(
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsetsDirectional.only(start: AppConstants.responsiveMargin(context), top: 12, end: AppConstants.responsiveMargin(context), bottom: 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
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
                  ],
                ),
                const SizedBox(height: 24),
                // Title
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.downloads,
                    style: AppTextStyles.headlineLarge(context).copyWith(
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: downloadsAsync.when(
                    data: (downloads) {
                      if (downloads.isEmpty) {
                        return _buildEmptyState(context, l10n, isDark);
                      }
                      return _buildDownloadsList(context, l10n, isDark, downloads);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => EmptyState(
                      icon: LucideIcons.alertTriangle,
                      title: l10n.genericError,
                      subtitle: e.toString(),
                      actionLabel: l10n.retry,
                      onAction: () => ref.invalidate(downloadsProvider),
                    ),
                  ),
          ),

          // ── Summary Bar ──
          _buildSummaryBar(context, l10n, isDark, countsAsync),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.arrowDownToLine,
            size: 48,
            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noDownloadsYet,
            style: AppTextStyles.headlineMedium(context),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.libraryEmptyDescription,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsList(BuildContext context, AppLocalizations l10n, bool isDark,
      List<Map<String, dynamic>> downloads) {
    // Group downloads by book
    final downloadsByBook = <String, List<Map<String, dynamic>>>{};
    for (final download in downloads) {
      final bookId = download['bookId'] as String? ?? '';
      downloadsByBook.putIfAbsent(bookId, () => []).add(download);
    }

    // Separate standalone files from book groups
    final standaloneFiles = downloadsByBook.remove('') ?? [];
    final bookKeys = downloadsByBook.keys.toList();
    final visibleBooks = bookKeys.take(_visibleBookCount).toList();
    final hasMore = bookKeys.length > _visibleBookCount;
    final totalItems = visibleBooks.length + standaloneFiles.length + (hasMore ? 1 : 0);

    return ListView.builder(
      addAutomaticKeepAlives: false,
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppConstants.responsiveMargin(context), vertical: AppConstants.responsiveMargin(context)),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Standalone files first
        if (index < standaloneFiles.length) {
          return _buildDownloadTile(context, l10n, isDark, standaloneFiles[index]);
        }

        final bookIndex = index - standaloneFiles.length;

        // Load more button
        if (bookIndex >= visibleBooks.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _visibleBookCount += _pageSize;
                  });
                },
                child: Text(l10n.loadMore),
              ),
            ),
          );
        }

        final bookId = visibleBooks[bookIndex];
        final bookDownloads = downloadsByBook[bookId]!;
        final bookName = bookDownloads.first['bookName'] as String? ??
            bookDownloads.first['bookLocalTitle'] as String? ??
            l10n.unknownBook;

        return _buildBookGroup(context, l10n, isDark, bookId, bookName, bookDownloads);
      },
    );
  }

  Widget _buildBookGroup(BuildContext context, AppLocalizations l10n, bool isDark,
      String bookId, String bookName, List<Map<String, dynamic>> downloads) {
    final isExpanded = _expandedBooks.contains(bookId);
    int completedCount = 0, downloadingCount = 0, queuedCount = 0, failedCount = 0;
    for (final d in downloads) {
      final s = d['downloadStatus'] as int;
      if (s == DownloadStatus.completed.index) {
        completedCount++;
      } else if (s == DownloadStatus.downloading.index) {
        downloadingCount++;
      } else if (s == DownloadStatus.queued.index) {
        queuedCount++;
      } else if (s == DownloadStatus.failed.index) {
        failedCount++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Header (tappable to expand/collapse)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedBooks.remove(bookId);
                } else {
                  _expandedBooks.add(bookId);
                }
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                border: BorderDirectional(
                  start: BorderSide(
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Book name + count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookName.toUpperCase(),
                          style: AppTextStyles.labelSmall(context).copyWith(
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${downloads.length} ${downloads.length == 1 ? l10n.documentLabel : l10n.downloads}',
                          style: AppTextStyles.labelSmall(context),
                        ),
                      ],
                    ),
                  ),
                  // Status badges
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (completedCount > 0)
                           _buildBadge(context, '$completedCount', LucideIcons.checkCircle,
                              isDark ? AppColors.darkSuccess : AppColors.success),
                           _buildBadge(context, '$downloadingCount', LucideIcons.arrowDownToLine,
                              isDark ? AppColors.darkTertiary : AppColors.slateBlue),
                           _buildBadge(context, '$queuedCount', LucideIcons.hourglass,
                              isDark ? AppColors.darkWarning : AppColors.warning),
                           _buildBadge(context, '$failedCount', LucideIcons.alertCircle,
                              isDark ? AppColors.darkError : AppColors.error),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Documents (only when expanded)
          if (isExpanded)
            ...downloads.map((download) => _buildDownloadTile(context, l10n, isDark, download)),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadTile(BuildContext context, AppLocalizations l10n, bool isDark,
      Map<String, dynamic> download) {
    final statusIndex = download['downloadStatus'] as int;
    final downloadStatus = (statusIndex >= 0 && statusIndex < DownloadStatus.values.length)
        ? DownloadStatus.values[statusIndex]
        : DownloadStatus.notDownloaded;
    final docName = download['sourceName'] as String? ?? l10n.unknown;
    final fileSize = download['fileSize'] as int? ?? 0;

    return InkWell(
      onTap: downloadStatus == DownloadStatus.completed ? () => _openDocument(context, download) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
              width: 0.5,
            ),
          ),
          color: downloadStatus == DownloadStatus.completed
              ? null
              : (isDark ? AppColors.darkSurfaceContainerHighest.withValues(alpha: 0.1) : null),
        ),
        child: Row(
          children: [
            // Status icon
            Icon(
              _getStatusIcon(downloadStatus),
              size: 18,
              color: _getStatusColor(downloadStatus, isDark),
            ),
            const SizedBox(width: 12),

            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docName,
                    style: AppTextStyles.bodyMedium(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fileSize > 0)
                    Text(
                      _formatFileSize(fileSize),
                      style: AppTextStyles.labelSmall(context),
                    ),
                ],
              ),
            ),

            // Actions
            if (downloadStatus == DownloadStatus.downloading ||
                downloadStatus == DownloadStatus.queued)
              IconButton(
                icon: Icon(LucideIcons.xCircle, size: 18,
                    color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                onPressed: () => _cancelDownload(download['id'] as String),
              )
            else if (downloadStatus == DownloadStatus.failed ||
                downloadStatus == DownloadStatus.paused)
              IconButton(
                icon: Icon(LucideIcons.refreshCw, size: 18,
                    color: isDark ? AppColors.darkTertiary : AppColors.antiqueGold),
                onPressed: () => _retryDownload(download['id'] as String),
              )
            else if (downloadStatus == DownloadStatus.completed)
              IconButton(
                icon: Icon(LucideIcons.book, size: 18,
                    color: isDark ? AppColors.darkTertiary : AppColors.antiqueGold),
                onPressed: () => _openDocument(context, download),
              ),
            if (downloadStatus == DownloadStatus.completed)
              IconButton(
                icon: Icon(LucideIcons.trash2, size: 18,
                    color: isDark ? AppColors.darkError : AppColors.error),
                onPressed: () => _deleteDownload(context, download),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, AppLocalizations l10n, bool isDark,
      AsyncValue<Map<String, int>> countsAsync) {
    return Container(
      padding: EdgeInsets.all(AppConstants.responsiveMargin(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            width: 1,
          ),
        ),
      ),
      child: countsAsync.when(
        data: (counts) {
          final total = counts.values.fold(0, (sum, c) => sum + c);
          final downloaded = counts['downloaded'] ?? 0;
          final downloading = counts['downloading'] ?? 0;
          final queued = counts['queued'] ?? 0;
          final failed = counts['failed'] ?? 0;
          final paused = counts['paused'] ?? 0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total',
                    style: AppTextStyles.headlineMedium(context).copyWith(
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    l10n.downloads,
                    style: AppTextStyles.labelSmall(context),
                  ),
                ],
              ),

              // Status breakdown
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (downloaded > 0)
                      _buildSummaryItem(context, '$downloaded', l10n.downloaded,
                          isDark ? AppColors.darkSuccess : AppColors.success),
                    if (downloading > 0)
                      _buildSummaryItem(context, '$downloading', l10n.downloading,
                          isDark ? AppColors.darkTertiary : AppColors.antiqueGold),
                    if (queued > 0)
                      _buildSummaryItem(context, '$queued', l10n.queued,
                          isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                    if (paused > 0)
                      _buildSummaryItem(context, '$paused', l10n.paused,
                          isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                    if (failed > 0)
                      _buildSummaryItem(context, '$failed', l10n.failed,
                          isDark ? AppColors.darkError : AppColors.error),
                  ],
                ),
              ),

              // Actions
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (downloading > 0 || queued > 0 || paused > 0)
                      TextButton(
                        onPressed: () => _togglePauseResume(),
                        child: Text(_isPaused ? l10n.resume : l10n.pause),
                      ),
                    if (failed > 0)
                      TextButton(
                        onPressed: () => _retryAllFailed(),
                        child: Text(l10n.retryAllFailed),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              l10n.genericError,
              style: AppTextStyles.labelSmall(context).copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String count, String label, Color color) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16),
      child: Column(
        children: [
          Text(
            count,
            style: AppTextStyles.headlineMedium(context).copyWith(
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall(context).copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return LucideIcons.fileText;
      case DownloadStatus.downloading:
      case DownloadStatus.queued:
        return LucideIcons.arrowDownToLine;
      case DownloadStatus.paused:
        return LucideIcons.hourglass;
      case DownloadStatus.failed:
        return LucideIcons.alertTriangle;
      case DownloadStatus.notDownloaded:
      case DownloadStatus.unavailable:
        return LucideIcons.helpCircle;
    }
  }

  Color _getStatusColor(DownloadStatus status, bool isDark) {
    switch (status) {
      case DownloadStatus.completed:
        return isDark ? AppColors.darkSuccess : AppColors.success;
      case DownloadStatus.downloading:
        return isDark ? AppColors.darkTertiary : AppColors.antiqueGold;
      case DownloadStatus.queued:
        return isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
      case DownloadStatus.failed:
        return isDark ? AppColors.darkError : AppColors.error;
      default:
        return isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _openDocument(BuildContext context, Map<String, dynamic> download) {
    final l10n = AppLocalizations.of(context);
    final localPath = download['localPath'] as String?;
    final documentId = download['id'] as String?;
    final documentTitle = download['sourceName'] as String? ?? l10n.documentLabel;
    final bookId = download['bookId'] as String?;
    final bookName = download['bookName'] as String? ?? download['bookLocalTitle'] as String? ?? '';

    if (localPath == null || documentId == null || bookId == null) return;
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          documentId: documentId,
          documentTitle: documentTitle,
          bookTitle: bookName,
          bookId: bookId,
          localPath: localPath,
        ),
      ),
    );
  }

  Future<void> _cancelDownload(String documentId) async {
    try {
      final dm = ref.read(downloadManagerProvider);
      await dm.cancelDownload(documentId);
      ref.invalidate(downloadsProvider);
      ref.invalidate(downloadCountsProvider);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.downloadCancelled)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.downloadFailed(e.toString())), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteDownload(BuildContext context, Map<String, dynamic> download) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeDownloadsConfirmTitle),
        content: Text(l10n.removeDownloadsConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      HapticFeedback.mediumImpact();
      try {
        final docId = download['id'] as String;
        final localPath = download['localPath'] as String?;
        if (localPath != null && localPath.isNotEmpty) {
          final file = File(localPath);
          if (await file.exists()) await file.delete();
        }
        await BookRepository.clearDocumentDownload(docId);
        ref.invalidate(downloadsProvider);
        ref.invalidate(downloadCountsProvider);
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.genericError), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _retryDownload(String documentId) async {
    try {
      final dm = ref.read(downloadManagerProvider);
      await dm.retryDownload(documentId);
      ref.invalidate(downloadsProvider);
      ref.invalidate(downloadCountsProvider);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.retryingDownload)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.downloadFailed(e.toString())), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _retryAllFailed() async {
    final downloads = ref.read(downloadsProvider).valueOrNull;
    int retryCount = 0;
    if (downloads != null) {
      final dm = ref.read(downloadManagerProvider);
      for (final download in downloads) {
        if ((download['downloadStatus'] as int) == DownloadStatus.failed.index) {
          try {
            await dm.retryDownload(download['id'] as String);
            retryCount++;
          } catch (_) {
            // Continue retrying other downloads even if one fails
          }
        }
      }
      ref.invalidate(downloadsProvider);
      ref.invalidate(downloadCountsProvider);
    }
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(retryCount > 0 ? l10n.retryAllFailed : l10n.noDownloadsYet)),
      );
    }
  }

  void _togglePauseResume() async {
    final dm = ref.read(downloadManagerProvider);
    if (_isPaused) {
      await dm.resumeDownloads();
    } else {
      await dm.pauseDownloads();
    }
    if (!mounted) return;
    setState(() => _isPaused = !_isPaused);
    ref.invalidate(downloadsProvider);
    ref.invalidate(downloadCountsProvider);
  }
}
