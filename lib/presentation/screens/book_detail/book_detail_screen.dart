import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/book_models.dart';
import '../../../providers/app_providers.dart';
import '../../../data/services/pdf_metadata_service.dart';
import '../../../data/repositories/book_repository.dart';
import '../../../data/repositories/reading_progress_repository.dart';
import '../reader/reader_screen.dart';
import '../../widgets/empty_state.dart';
import '../../../core/constants/app_text_styles.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _isLoadingMetadata = false;
  bool _hasScheduledMetadataLoad = false;
  Uint8List? _coverImage;
  PdfMetadata? _metadata;
  Future<List<Map<String, dynamic>>>? _readingProgressFuture;
  List<BookDocument> _lastDownloadedDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(bookDetailProvider(widget.bookId));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasScheduledMetadataLoad || _metadata != null) return;

    final bookAsync = ref.read(bookDetailProvider(widget.bookId));
    bookAsync.whenData((state) {
      if (state != null && state.documents.isNotEmpty) {
        _hasScheduledMetadataLoad = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadMetadata(state.documents);
        });
      }
    });
  }

  Future<void> _loadMetadata(List<BookDocument> documents) async {
    if (_isLoadingMetadata || _metadata != null || documents.isEmpty) return;
    _isLoadingMetadata = true;

    // Find first downloaded document to extract metadata and cover
    final downloadedDocs = documents.where((d) => d.isDownloaded && d.localPath != null).toList();
    if (downloadedDocs.isEmpty) {
      _isLoadingMetadata = false;
      return;
    }

    final firstDoc = downloadedDocs.first;
    final file = File(firstDoc.localPath!);

    if (await file.exists()) {
      try {
        final metadata = await PdfMetadataService.extractFromFile(firstDoc.localPath!);
        final cover = await PdfMetadataService.generateThumbnail(firstDoc.localPath!);

        if (mounted) {
          setState(() {
            _metadata = metadata;
            _coverImage = cover;
          });
        }
      } catch (e) {
        _isLoadingMetadata = false;
        debugPrint('Failed to load metadata: $e');
      }
    } else {
      _isLoadingMetadata = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookAsync = ref.watch(bookDetailProvider(widget.bookId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      body: bookAsync.when(
        data: (state) {
          if (state == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                     LucideIcons.book,
                    size: 64,
                    color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.bookNotFound,
                    style: AppTextStyles.titleMedium(context).copyWith(
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(l10n.goBack),
                  ),
                ],
              ),
            );
          }
          final book = state.book;
          final sections = state.sections;
          final documents = state.documents;
          final downloadedDocs = documents.where((d) => d.isDownloaded).toList();
          final downloadedCount = downloadedDocs.length;
          final totalCount = documents.length;

          return CustomScrollView(
            slivers: [
              // Header with cover
              SliverToBoxAdapter(
                child: _buildHeader(context, l10n, book, downloadedCount, totalCount),
              ),

              // Metadata Section
              if (_metadata != null)
                SliverToBoxAdapter(
                  child: _buildMetadataSection(context, l10n),
                ),

              // Actions
              SliverToBoxAdapter(
                child: _buildActions(context, l10n, book, documents, downloadedDocs),
              ),

              // Reading Progress
              SliverToBoxAdapter(
                child: _buildReadingProgress(context, l10n, documents, downloadedDocs),
              ),

              // Table of Contents
              SliverToBoxAdapter(
                child: _buildTableOfContents(context, l10n, sections, documents),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: LucideIcons.alertTriangle,
          title: l10n.genericError,
          subtitle: e.toString(),
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(bookDetailProvider(widget.bookId)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n,
      Book book, int downloadedCount, int totalCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsetsDirectional.only(start: AppConstants.responsiveMargin(context), top: 16, end: AppConstants.responsiveMargin(context), bottom: 0),
      child: Column(
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(LucideIcons.arrowLeft,
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  AppConstants.appName,
                  style: AppTextStyles.headlineMedium(context).copyWith(
                    letterSpacing: 2,
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.moreVertical,
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                onPressed: () => _showBookMenu(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Book Header with Cover
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              Container(
                width: AppConstants.responsiveBookCardWidth(context),
                height: AppConstants.responsiveBookCardHeight(context),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerHighest
                      : AppColors.surfaceContainerHighest,
                  border: Border.all(
                    color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                child: _coverImage != null
                    ? Image.memory(
                        _coverImage!,
                        fit: BoxFit.cover,
                      )
                    : Stack(
                        children: [
                          Center(
                            child: Icon(LucideIcons.book, size: 48,
                                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.surface,
                                border: Border.all(
                                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                l10n.pdfLabel,
                                style: AppTextStyles.labelSmallTight(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 16),
              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: AppTextStyles.headlineMedium(context).copyWith(
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                    if (_metadata?.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _metadata!.author!,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.documentsCount(totalCount)} · $downloadedCount ${l10n.downloadedText}',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_metadata == null) return const SizedBox.shrink();

    final metadataItems = <Map<String, String>>[];

    if (_metadata!.author != null) {
      metadataItems.add({'label': l10n.authorLabel, 'value': _metadata!.author!});
    }
    if (_metadata!.subject != null) {
      metadataItems.add({'label': l10n.subjectLabel, 'value': _metadata!.subject!});
    }
    if (_metadata!.creator != null) {
      metadataItems.add({'label': l10n.creatorLabel, 'value': _metadata!.creator!});
    }
    if (_metadata!.producer != null) {
      metadataItems.add({'label': l10n.producerLabel, 'value': _metadata!.producer!});
    }
    if (_metadata!.pageCount > 0) {
      metadataItems.add({'label': l10n.pagesLabel, 'value': '${_metadata!.pageCount}'});
    }
    if (_metadata!.creationDate != null) {
      metadataItems.add({'label': l10n.createdLabel, 'value': _formatDate(_metadata!.creationDate!)});
    }
    if (_metadata!.modificationDate != null) {
      metadataItems.add({'label': l10n.modifiedLabel, 'value': _formatDate(_metadata!.modificationDate!)});
    }

    if (metadataItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsetsDirectional.only(start: AppConstants.responsiveMargin(context), top: 16, end: AppConstants.responsiveMargin(context), bottom: 0),
      padding: EdgeInsets.all(AppConstants.responsiveMargin(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.documentInformation,
            style: AppTextStyles.titleLarge(context).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in metadataItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: (AppConstants.responsiveMargin(context) * 4).clamp(80.0, 120.0),
                    child: Text(
                      item['label']!,
                      style: AppTextStyles.labelSmall(context).copyWith(
                        fontSize: 12,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value']!,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n,
      Book book, List<BookDocument> documents, List<BookDocument> downloadedDocs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsetsDirectional.only(start: AppConstants.responsiveMargin(context), top: 16, end: AppConstants.responsiveMargin(context), bottom: 0),
      padding: EdgeInsets.all(AppConstants.responsiveMargin(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
        border: Border.all(
          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          Text(
            '${l10n.documentsCount(documents.length)} · ${downloadedDocs.length} ${l10n.downloadedText}',
            style: AppTextStyles.labelMedium(context).copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Continue Reading
              if (downloadedDocs.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _openFirstDownloaded(context, downloadedDocs),
                   icon: const Icon(LucideIcons.book, size: 18),
                  label: Text(l10n.continueReadingAction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    foregroundColor: isDark ? AppColors.darkSurface : AppColors.onPrimary,
                  ),
                ),

              // Download All
              OutlinedButton.icon(
                onPressed: () => _downloadAll(),
                 icon: const Icon(LucideIcons.download, size: 18),
                label: Text(l10n.downloadAll),
              ),

              // Remove Local Downloads (keep library metadata, free storage)
              if (downloadedDocs.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _removeLocalDownloads(downloadedDocs),
                  icon: const Icon(LucideIcons.hardDrive, size: 18),
                  label: Text(l10n.removeDownloadsAction),
                ),

              // Sync
              OutlinedButton.icon(
                onPressed: () => _syncBook(),
                 icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(l10n.sync),
              ),

              // Remove
              OutlinedButton.icon(
                onPressed: () => _removeBook(),
                 icon: const Icon(LucideIcons.trash2, size: 18),
                label: Text(l10n.removeBook),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.darkError : AppColors.error,
                  side: BorderSide(
                    color: isDark ? AppColors.darkError : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingProgress(BuildContext context, AppLocalizations l10n,
      List<BookDocument> documents, List<BookDocument> downloadedDocs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (downloadedDocs.isEmpty) return const SizedBox.shrink();

    // Only create new future if the document list changed
    if (_readingProgressFuture == null || !_sameDocs(downloadedDocs, _lastDownloadedDocs)) {
      _lastDownloadedDocs = downloadedDocs;
      _readingProgressFuture = _getReadingProgress(downloadedDocs);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _readingProgressFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final progressList = snapshot.data!;
        final totalProgress = progressList.fold<double>(
          0,
          (sum, p) => sum + (p['progress'] as double),
        ) / progressList.length;

    return Container(
      margin: const EdgeInsetsDirectional.only(start: AppConstants.marginMobile, top: 16, end: AppConstants.marginMobile, bottom: 0),
      padding: const EdgeInsets.all(AppConstants.marginMobile),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
            border: Border.all(
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.readingProgressLabel,
                style: AppTextStyles.titleLarge(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalProgress,
                        backgroundColor: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.darkTertiary : AppColors.antiqueGold,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(totalProgress * 100).toInt()}%',
                    style: AppTextStyles.labelMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getReadingProgress(List<BookDocument> docs) async {
    final progressList = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final progress = await ReadingProgressRepository.getProgress(doc.id);
      if (progress != null) {
        progressList.add({
          'documentId': doc.id,
          'progress': progress.progressPercent,
        });
      }
    }

    return progressList;
  }

  bool _sameDocs(List<BookDocument> a, List<BookDocument> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Widget _buildTableOfContents(BuildContext context, AppLocalizations l10n,
      List<BookSection> sections, List<BookDocument> documents) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (sections.isEmpty && documents.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group documents by section
    final docsBySection = <String?, List<BookDocument>>{};
    for (final doc in documents) {
      final key = doc.sectionId;
      docsBySection.putIfAbsent(key, () => []).add(doc);
    }

    final unsectioned = docsBySection[null] ?? [];

    return Container(
      margin: const EdgeInsetsDirectional.only(start: AppConstants.marginMobile, top: 16, end: AppConstants.marginMobile, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
              l10n.tableOfContents,
              style: AppTextStyles.headlineLarge(context).copyWith(
                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sections with their documents
          for (final section in sections) ...[
            // Section header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                border: BorderDirectional(
                  start: BorderSide(
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    width: 4,
                  ),
                ),
              ),
              child: Text(
                section.title.toUpperCase(),
                style: AppTextStyles.labelSmall(context).copyWith(
                  letterSpacing: 0.15,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ),

            // Documents in this section
            for (final doc in (docsBySection[section.id] ?? []))
              _buildDocumentTile(context, l10n, doc),
          ],

          // Unsectioned documents
          if (unsectioned.isNotEmpty)
            for (final doc in unsectioned)
              _buildDocumentTile(context, l10n, doc),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, AppLocalizations l10n, BookDocument doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDownloaded = doc.isDownloaded;

    return InkWell(
      onTap: isDownloaded ? () => _openDocument(context, doc) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
              width: 0.5,
            ),
          ),
          color: isDownloaded
              ? null
              : (isDark ? AppColors.darkSurfaceContainerHighest.withValues(alpha: 0.1) : null),
        ),
        child: Row(
          children: [
            Icon(
              isDownloaded ? LucideIcons.fileText : LucideIcons.arrowDownToLine,
              size: 18,
              color: isDownloaded
                  ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                  : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                doc.title,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ),
            if (!isDownloaded)
              IconButton(
                 icon: Icon(LucideIcons.download, size: 18,
                    color: isDark ? AppColors.darkTertiary : AppColors.antiqueGold),
                onPressed: () => _downloadDocument(doc),
              ),
          ],
        ),
      ),
    );
  }

  void _openFirstDownloaded(BuildContext context, List<BookDocument> docs) {
    if (docs.isNotEmpty) {
      _openDocument(context, docs.first);
    }
  }

  void _openDocument(BuildContext context, BookDocument doc) {
    if (!mounted) return;
    if (doc.localPath == null || doc.localPath!.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          documentId: doc.id,
          documentTitle: doc.title,
          bookTitle: ref.read(bookDetailProvider(widget.bookId)).value?.book.title ?? '',
          bookId: widget.bookId,
          localPath: doc.localPath!,
        ),
      ),
    );
  }

  Future<void> _downloadDocument(BookDocument doc) async {
    try {
      final l10n = AppLocalizations.of(context);
      final dm = ref.read(downloadManagerProvider);
      await dm.queueDocumentDownload(doc);
      ref.invalidate(bookDetailProvider(widget.bookId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.downloadingProgress(doc.title))),
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

  Future<void> _downloadAll() async {
    try {
      final l10n = AppLocalizations.of(context);
      final dm = ref.read(downloadManagerProvider);
      await dm.queueBookDownload(widget.bookId);
      ref.invalidate(bookDetailProvider(widget.bookId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.downloadQueued)),
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

  Future<void> _syncBook() async {
    final l10n = AppLocalizations.of(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.syncing), duration: const Duration(seconds: 2)),
      );
    }
    try {
      await ref.read(syncProvider.notifier).syncBook(widget.bookId);
      ref.invalidate(bookDetailProvider(widget.bookId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.syncComplete)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.syncFailed), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _removeLocalDownloads(List<BookDocument> downloadedDocs) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeDownloadsConfirmTitle),
        content: Text(l10n.removeDownloadsConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      for (final doc in downloadedDocs) {
        final localPath = doc.localPath;
        if (localPath != null && localPath.isNotEmpty) {
          try {
            final file = File(localPath);
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
        await BookRepository.clearDocumentDownload(doc.id);
      }
      ref.invalidate(booksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.removeDownloadsDone)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericError), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _removeBook() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeBook),
        content: Text(l10n.removeBookConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.removeBook, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await ref.read(booksProvider.notifier).removeBook(widget.bookId);
        if (mounted) {
          Navigator.of(context).pop(); // dismiss loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bookRemoved)),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // dismiss loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.genericError), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showBookMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
               leading: const Icon(LucideIcons.pencil),
              title: Text(l10n.renameLabel),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog();
              },
            ),
            ListTile(
               leading: const Icon(LucideIcons.refreshCw),
              title: Text(l10n.sync),
              onTap: () {
                Navigator.pop(ctx);
                _syncBook();
              },
            ),
            ListTile(
               leading: Icon(LucideIcons.trash2, color: AppColors.error),
              title: Text(l10n.removeLabel, style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _removeBook();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final locale = AppLocalizations.of(context).locale.languageCode;
    return DateFormat.yMMMd(locale).format(date);
  }

  void _showRenameDialog() {
    final l10n = AppLocalizations.of(context);
    final bookAsync = ref.read(bookDetailProvider(widget.bookId));
    final book = bookAsync.value?.book;
    if (book == null) return;

    final controller = TextEditingController(text: book.title);
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
          title: Text(l10n.renameLabel),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.renameLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setDialogState(() {}),
            onSubmitted: (_) {
              if (controller.text.trim().isNotEmpty) {
                _submitRename(controller, safeDispose, ctx);
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
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => _submitRename(controller, safeDispose, ctx),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    ).then((_) => safeDispose());
  }

  void _submitRename(TextEditingController controller, VoidCallback safeDispose, BuildContext ctx) {
    final newTitle = controller.text.trim();
    if (newTitle.isEmpty) return;
    final bookAsync = ref.read(bookDetailProvider(widget.bookId));
    final book = bookAsync.value?.book;
    if (book == null) return;

    final l10n = AppLocalizations.of(context);
    safeDispose();
    Navigator.of(ctx).pop();

    BookRepository.renameBookLocally(book.id, newTitle).then((_) {
      ref.invalidate(bookDetailProvider(widget.bookId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bookRenamed)),
        );
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericError), backgroundColor: AppColors.error),
        );
      }
    });
  }
}
