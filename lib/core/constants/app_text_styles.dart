import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Codexa Typography System — Archival Modernist
/// Bodoni Moda (editorial) + Literata (reading) + Hanken Grotesk (UI)
abstract final class AppTextStyles {
  // ── Display / Hero ──
  static TextStyle displayLarge(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicBody : GoogleFonts.bodoniModa(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.02,
    )).copyWith(color: _onSurface(context));
  }

  // ── Headlines ──
  static TextStyle headlineLarge(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicHeading : GoogleFonts.bodoniModa(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.2,
    )).copyWith(color: _onSurface(context));
  }

  static TextStyle headlineMedium(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicHeading : GoogleFonts.bodoniModa(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.2,
    )).copyWith(color: _onSurface(context));
  }

  static TextStyle headlineSmall(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicHeading : GoogleFonts.bodoniModa(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.3,
    )).copyWith(color: _onSurface(context));
  }

  // ── Titles ──
  static TextStyle titleLarge(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicHeading : GoogleFonts.bodoniModa(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 1.4,
    )).copyWith(color: _onSurface(context));
  }

  static TextStyle titleMedium(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicHeading : GoogleFonts.bodoniModa(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.4,
    )).copyWith(color: _onSurface(context));
  }

  // ── Body ──
  static TextStyle bodyLarge(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicBody : GoogleFonts.literata(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.6,
    )).copyWith(color: _onSurface(context));
  }

  static TextStyle bodyMedium(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicBody : GoogleFonts.literata(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
    )).copyWith(color: _onSurface(context));
  }

  static TextStyle bodySmall(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicBody : GoogleFonts.literata(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    )).copyWith(color: _onSurface(context));
  }

  // ── Labels / UI ──
  static TextStyle labelLarge(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicLabel : GoogleFonts.hankenGrotesk(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0.05,
    )).copyWith(color: _onSurface(context));
  }

  static TextStyle labelMedium(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicLabel : GoogleFonts.hankenGrotesk(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0.05,
    )).copyWith(color: _onSurface(context));
  }

  static TextStyle labelSmall(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicLabel : GoogleFonts.hankenGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.08,
    )).copyWith(color: _onSurfaceVariant(context));
  }

  static TextStyle labelSmallTight(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return (isArabic ? _arabicLabel : GoogleFonts.hankenGrotesk(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.2,
      letterSpacing: 0.05,
    )).copyWith(color: _onSurfaceVariant(context));
  }

  // ── Arabic Fallbacks ──
  static TextStyle get _arabicBody => const TextStyle(
    fontFamily: 'NotoNaskhArabic',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.8,
  );

  static TextStyle get _arabicHeading => const TextStyle(
    fontFamily: 'NotoNaskhArabic',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get _arabicLabel => const TextStyle(
    fontFamily: 'NotoNaskhArabic',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // ── Helpers ──
  static Color _onSurface(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? AppColors.darkOnSurface
        : AppColors.onSurface;
  }

  static Color _onSurfaceVariant(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
  }
}
