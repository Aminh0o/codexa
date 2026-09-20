import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/book_models.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final bool isDark;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = AppConstants.responsiveBookCardWidth(context);
    final cardHeight = AppConstants.responsiveBookCardHeight(context);

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: book.title,
        button: true,
        child: SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: cardHeight,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.parchmentCard,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.book,
                    size: cardWidth * 0.23,
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.title,
                style: AppTextStyles.labelSmall(context).copyWith(
                  fontSize: (cardWidth * 0.11).clamp(12.0, 16.0),
                  letterSpacing: 0,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                book.sourceName,
                style: AppTextStyles.labelSmall(context).copyWith(
                  fontSize: (cardWidth * 0.09).clamp(10.0, 13.0),
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
