import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/book_models.dart';
import '../../../providers/app_providers.dart';
import '../../widgets/book_card.dart';
import '../../widgets/empty_state.dart';
import '../book_detail/book_detail_screen.dart';
import '../reader/reader_screen.dart';
import '../../navigation/main_navigation_shell.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booksAsync = ref.watch(booksProvider);
    final continueReading = ref.watch(continueReadingProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(booksProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: _Header(l10n: l10n),
            ),

            // ── Search Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: AppConstants.responsiveMargin(context), top: AppConstants.stackSm, end: AppConstants.responsiveMargin(context), bottom: 0,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                    setState(() => _showSearch = value.isNotEmpty);
                  },
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: Icon(LucideIcons.search, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                    suffixIcon: _showSearch
                        ? IconButton(
                            icon: Icon(LucideIcons.x, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                              setState(() => _showSearch = false);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurfaceContainerHighest.withValues(alpha: 0.1) : AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // ── Search Results ──
            if (_showSearch && searchQuery.length >= 2)
            SliverToBoxAdapter(
              child: searchResults.when(
                data: (results) {
                  if (results.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          l10n.noResults,
                          style: AppTextStyles.bodyMedium(context),
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: AppConstants.responsiveMargin(context), top: AppConstants.stackMd, end: AppConstants.responsiveMargin(context), bottom: AppConstants.stackSm,
                      ),
                        child: Text(
                          '${results.length} ${l10n.search}',
                          style: AppTextStyles.labelSmall(context),
                        ),
                      ),
                      ...results.take(10).map((result) => _SearchResultTile(
                        result: result,
                        onTap: () => _openSearchResult(result),
                      )),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, e) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      l10n.errorLoadingLibrary,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ),
                ),
              ),
            ),

            // ── Continue Reading ──
            SliverToBoxAdapter(
              child: continueReading.when(
                data: (data) => data != null
                    ? _ContinueReading(
                        l10n: l10n,
                        data: data,
                        onTap: () {
                          final localPath = data['localPath'] as String?;
                          final documentId = data['documentId'] as String?;
                          final documentName = data['documentName'] as String? ?? '';
                          final bookId = data['bookId'] as String?;
                          final bookName = data['bookName'] as String? ?? '';
                          if (localPath != null && documentId != null && bookId != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReaderScreen(
                                  documentId: documentId,
                                  documentTitle: documentName,
                                  bookTitle: bookName,
                                  bookId: bookId,
                                  localPath: localPath,
                                ),
                              ),
                            );
                          }
                        },
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

            // ── Books ──
            booksAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: LucideIcons.bookOpen,
                        title: l10n.emptyLibrary,
                        subtitle: l10n.emptyLibrarySubtitle,
                        actionLabel: l10n.addBook,
                        onAction: () {
                          // Switch to Browse tab
                          ref.read(currentTabProvider.notifier).state = 1;
                        },
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsetsDirectional.only(
                    start: AppConstants.responsiveMargin(context),
                    top: AppConstants.stackMd,
                    end: AppConstants.responsiveMargin(context),
                    bottom: 100,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      addAutomaticKeepAlives: false,
                      (context, index) {
                        // First 3 items: section label + horizontal list + spacer
                        if (index == 0) {
                          return _SectionLabel(
                            label: l10n.recentlyAdded.toUpperCase(),
                          );
                        }
                        if (index == 1) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppConstants.stackMd),
                            child: SizedBox(
                              height: AppConstants.responsiveHorizontalListHeight(context),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsetsDirectional.only(end: AppConstants.responsiveMargin(context)),
                                itemCount: books.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: AppConstants.gutter),
                                itemBuilder: (context, index) {
                                  return BookCard(
                                    book: books[index],
                                    isDark: isDark,
                                    onTap: () => _openBookDetail(books[index]),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        if (index == 2) {
                          return _SectionLabel(
                            label: l10n.allBooks.toUpperCase(),
                          );
                        }
                        // Book tiles
                        final bookIndex = index - 3;
                        if (bookIndex >= 0 && bookIndex < books.length) {
                          return _BookTile(
                            book: books[bookIndex],
                            onTap: () => _openBookDetail(books[bookIndex]),
                            onDelete: () => _deleteBook(books[bookIndex]),
                          );
                        }
                        return null;
                      },
                      childCount: 3 + books.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => SliverFillRemaining(
                child: EmptyState(
                  icon: LucideIcons.alertTriangle,
                  title: l10n.errorLoadingLibrary,
                  subtitle: e.toString(),
                  actionLabel: l10n.retry,
                  onAction: () => ref.read(booksProvider.notifier).loadBooks(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBookDetail(Book book) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(bookId: book.id),
      ),
    );
  }

  Future<void> _deleteBook(Book book) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeFromLibrary),
        content: Text(l10n.removeBookConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    HapticFeedback.mediumImpact();

    bool undoPressed = false;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.bookRemoved),
        action: SnackBarAction(
          label: l10n.undo.toUpperCase(),
          onPressed: () {
            undoPressed = true;
            messenger.hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );

    await Future.delayed(const Duration(seconds: 5));

    if (!undoPressed && mounted) {
      try {
        await ref.read(booksProvider.notifier).removeBook(book.id);
      } catch (e) {
        debugPrint('Failed to delete book: $e');
      }
    }
  }

  void _openSearchResult(Map<String, dynamic> result) {
    if (!mounted) return;
    final type = result['type'] as String;
    if (type == 'book') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: result['id'] as String),
        ),
      );
    } else if (type == 'document') {
      final localPath = result['localPath'] as String?;
      if (localPath != null && localPath.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReaderScreen(
              documentId: result['id'] as String,
              documentTitle: result['sourceName'] as String? ?? '',
              bookTitle: result['bookName'] as String? ?? '',
              bookId: result['bookId'] as String,
              localPath: localPath,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(bookId: result['bookId'] as String),
          ),
        );
      }
    } else if (type == 'section') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: result['bookId'] as String),
        ),
      );
    }
  }
}

// ════════════════════════════════════════════
// HEADER
// ════════════════════════════════════════════
class _Header extends StatelessWidget {
  final AppLocalizations l10n;
  const _Header({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: AppConstants.marginMobile, top: 12, end: AppConstants.marginMobile, bottom: 0,
      ),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: AppConstants.stackMd),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Text(
              l10n.libraryTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineLarge(context).copyWith(
                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// SECTION LABEL
// ════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(width: 16, height: 1, color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.labelMedium(context).copyWith(
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════
// CONTINUE READING
// ════════════════════════════════════════════
class _ContinueReading extends StatelessWidget {
  final AppLocalizations l10n;
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  const _ContinueReading({required this.l10n, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookName = data['bookLocalTitle'] ?? data['bookName'] ?? '';
    final docName = data['documentName'] ?? '';
    final page = data['currentPage'] ?? 0;
    final total = data['totalPages'] ?? 0;
    final percent = data['progressPercent'] ?? 0.0;

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppConstants.marginMobile, top: AppConstants.stackMd, end: AppConstants.marginMobile, bottom: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 16, height: 1, color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.continueReading.toUpperCase(),
                  style: AppTextStyles.labelMedium(context).copyWith(
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.stackSm),
          Semantics(
            label: '$bookName, $docName',
            button: true,
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                  border: Border.all(
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface, width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bookName, style: AppTextStyles.headlineSmall(context).copyWith(
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    )),
                    const SizedBox(height: 4),
                    Text(docName, style: AppTextStyles.bodySmall(context).copyWith(
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                    )),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Text(l10n.pageOf(page, total), style: AppTextStyles.labelSmall(context).copyWith(
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                          ), overflow: TextOverflow.ellipsis),
                        ),
                        const Spacer(),
                        Text('${(percent * 100).round()}%', style: AppTextStyles.labelSmall(context).copyWith(
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percent.toDouble(),
                      backgroundColor: isDark ? AppColors.darkSurfaceContainerHighest : AppColors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(isDark ? AppColors.darkOnSurface : AppColors.onSurface),
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

// ════════════════════════════════════════════
// BOOK TILE
// ════════════════════════════════════════════
class _BookTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _BookTile({required this.book, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '${book.title}, ${book.sourceName}',
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
              Icon(LucideIcons.book, size: 20,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: AppTextStyles.bodyMedium(context).copyWith(
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${book.totalDocuments} ${l10n.documentsCountText} \u00B7 ${book.downloadedDocuments == book.totalDocuments ? l10n.downloadedText : "${book.downloadedDocuments}/${book.totalDocuments}"}',
                      style: AppTextStyles.labelSmall(context).copyWith(
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') {
                    HapticFeedback.mediumImpact();
                    onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'delete', child: Text(l10n.removeLabel)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// SEARCH RESULT TILE
// ════════════════════════════════════════════
class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onTap;
  const _SearchResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = result['type'] as String;
    final name = result['sourceName'] as String? ?? '';

    IconData icon;
    String subtitle;
    switch (type) {
      case 'book':
        icon = LucideIcons.book;
        subtitle = '';
      case 'section':
        icon = LucideIcons.folder;
        subtitle = '';
      case 'document':
        icon = LucideIcons.fileText;
        subtitle = '';
      default:
        icon = LucideIcons.helpCircle;
        subtitle = '';
    }

    return Semantics(
      label: name,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.marginMobile, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.bodySmall(context).copyWith(
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: AppTextStyles.labelSmall(context).copyWith(
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
