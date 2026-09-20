import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Ornamental Divider — Archival-style section divider with diamond mark
class OrnamentalDivider extends StatelessWidget {
  final double width;
  final Color? color;

  const OrnamentalDivider({
    super.key,
    this.width = 96,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = color ??
        (isDark ? AppColors.darkOutlineVariant : AppColors.agedPaper);

    return SizedBox(
      width: width,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Horizontal line
          Positioned(
            top: 5.5,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color: dividerColor,
            ),
          ),
          // Diamond
          Positioned(
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  border: Border.all(color: dividerColor, width: 1),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
