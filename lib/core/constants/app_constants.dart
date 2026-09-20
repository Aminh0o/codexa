import 'package:flutter/widgets.dart';

/// Codexa App Constants
abstract final class AppConstants {
  static const String appName = 'Codexa';
  static const String appTagline = 'A library of your own';

  // ── Spacing (4px baseline grid) ──
  static const double unit = 4;
  static const double stackSm = 8;
  static const double stackMd = 24;
  static const double stackLg = 48;
  static const double marginMobile = 20; // 1.25rem
  static const double marginTablet = 40; // 2.5rem
  static const double marginDesktop = 80; // 5rem
  static const double gutter = 24; // 1.5rem
  static const double marginPage = 32; // 2rem

  // ── Border ──
  static const double borderWidth = 1;
  static const double hairlineWidth = 0.5;
  static const double borderRadius = 0; // Sharp corners — archival

  // ── Animation ──
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationPage = Duration(milliseconds: 600);

  // ── Splash ──
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration splashFadeDuration = Duration(milliseconds: 800);

  // ── Onboarding ──
  static const int onboardingPageCount = 3;

  // ── Download ──
  static const int maxConcurrentDownloads = 3;
  static const int downloadRetryLimit = 3;

  // ── Database ──
  static const String databaseName = 'codexa.db';
  static const int databaseVersion = 3;

  // ── Storage Keys ──
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language_code';
  static const String keyLastSync = 'last_sync_timestamp';
  static const String keyBooksFolderId = 'books_folder_id';
  static const String booksFolderName = 'BOOKS';
  static const String keyPageTurnAnimation = 'page_turn_animation';
  static const String keyShowProgressBar = 'show_progress_bar';
  static const String keyNightMode = 'night_mode';
  static const String keyRotationAngle = 'rotation_angle';

  // ── Responsive ──
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 1024;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  static double responsiveMargin(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1024) return marginDesktop;
    if (w >= 600) return marginTablet;
    return marginMobile;
  }

  static double responsiveBookCardWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1024) return 160;
    if (w >= 600) return 140;
    return 120;
  }

  static double responsiveBookCardHeight(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1024) return 240;
    if (w >= 600) return 210;
    return 180;
  }

  static double responsiveHorizontalListHeight(BuildContext context) {
    final cardH = responsiveBookCardHeight(context);
    return cardH + 80; // card + title + spacing
  }

  static double responsiveDialogHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * 0.6).clamp(300.0, 500.0);
  }
}
