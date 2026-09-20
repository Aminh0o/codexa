import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../screens/library/library_screen.dart';
import '../screens/browse/browse_screen.dart';
import '../screens/downloads/downloads_screen.dart';
import '../screens/settings/settings_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  Widget? _currentScreen;
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final l10n = AppLocalizations.of(context);

    // Lazy rebuild only when tab changes — avoids keeping all 4 screens alive
    if (currentTab != _currentTabIndex) {
      _currentTabIndex = currentTab;
      _currentScreen = _buildScreen(currentTab);
    }
    _currentScreen ??= _buildScreen(currentTab);

    final navItems = [
      _NavItemData(icon: LucideIcons.bookOpen, label: l10n.navLibrary),
      _NavItemData(icon: LucideIcons.globe, label: l10n.navBrowse),
      _NavItemData(
          icon: LucideIcons.arrowDownToLine, label: l10n.navDownloads),
      _NavItemData(icon: LucideIcons.settings, label: l10n.navSettings),
    ];

    return Scaffold(
      body: _currentScreen,
      bottomNavigationBar: _NavBar(
        currentTab: currentTab,
        navItems: navItems,
        onTabTap: (index) {
          if (index == currentTab) return;
          HapticFeedback.selectionClick();
          ref.read(currentTabProvider.notifier).state = index;
        },
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const LibraryScreen();
      case 1:
        return const BrowseScreen();
      case 2:
        return const DownloadsScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const LibraryScreen();
    }
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

class _NavBar extends StatelessWidget {
  final int currentTab;
  final List<_NavItemData> navItems;
  final ValueChanged<int> onTabTap;

  const _NavBar({
    required this.currentTab,
    required this.navItems,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeBottom = math.max(bottomPadding, 8.0);

    final activeColor = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final inactiveColor =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerLow
            : AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: safeBottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(navItems.length, (index) {
              final isActive = currentTab == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTabTap(index),
                  child: Semantics(
                    label: navItems[index].label,
                    button: true,
                    selected: isActive,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          navItems[index].icon,
                          size: 22,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          navItems[index].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? activeColor : inactiveColor,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
