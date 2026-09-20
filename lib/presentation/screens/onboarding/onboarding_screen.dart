import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../navigation/main_navigation_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: AppConstants.animationNormal,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    ref.read(onboardingCompleteProvider.notifier).completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppConstants.animationNormal,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRTL = l10n.isRTL;

    final pages = [
      (
        icon: LucideIcons.library,
        title: l10n.onboarding1Title,
        subtitle: l10n.onboarding1Subtitle,
      ),
      (
        icon: LucideIcons.clock,
        title: l10n.onboarding2Title,
        subtitle: l10n.onboarding2Subtitle,
      ),
      (
        icon: LucideIcons.bookOpen,
        title: l10n.onboarding3Title,
        subtitle: l10n.onboarding3Subtitle,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip Button ──
            Align(
              alignment: isRTL ? AlignmentDirectional.topStart : AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.marginMobile),
                child: TextButton(
                  onPressed: _onSkip,
                  child: Text(
                    l10n.skip,
                    style: AppTextStyles.labelMedium(context).copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // ── Page View ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return _buildPage(page, isDark);
                },
              ),
            ),

            // ── Page Indicators ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppConstants.stackMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: AppConstants.animationFast,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: _currentPage == index ? 32 : 8,
                    height: 2,
                    color: _currentPage == index
                        ? (isDark
                            ? AppColors.darkOnSurface
                            : AppColors.onSurface)
                        : (isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.outlineVariant),
                  ),
                ),
              ),
            ),

            // ── Action Button ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.marginMobile,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkOnSurface : AppColors.primary,
                    foregroundColor:
                        isDark ? AppColors.darkSurface : AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    _currentPage < pages.length - 1 ? l10n.next : l10n.getStarted,
                    style: AppTextStyles.labelMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.marginPage),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(({IconData icon, String title, String subtitle}) page, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.marginPage),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Icon(
                page.icon,
                size: 120,
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.stackLg),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium(context).copyWith(
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.stackSm),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.stackLg),
          Container(
            width: 48,
            height: 1,
            color: isDark ? AppColors.darkOutlineVariant : AppColors.agedPaper,
          ),
          const SizedBox(height: AppConstants.stackLg),
        ],
      ),
    );
  }
}
