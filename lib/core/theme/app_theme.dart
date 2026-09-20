import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// Codexa Light & Dark Themes — Archival Modernist
abstract final class AppTheme {
  // ════════════════════════════════════════════
  // LIGHT THEME
  // ════════════════════════════════════════════
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceTint: AppColors.surfaceTint,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ════════════════════════════════════════════
  // DARK THEME
  // ════════════════════════════════════════════
  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkOnSecondary,
      secondaryContainer: AppColors.darkSecondaryContainer,
      onSecondaryContainer: AppColors.darkOnSecondaryContainer,
      tertiary: AppColors.darkTertiary,
      onTertiary: AppColors.darkOnTertiary,
      tertiaryContainer: AppColors.darkTertiaryContainer,
      onTertiaryContainer: AppColors.darkOnTertiaryContainer,
      error: AppColors.darkError,
      onError: AppColors.darkOnError,
      errorContainer: AppColors.darkErrorContainer,
      onErrorContainer: AppColors.darkOnErrorContainer,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      inverseSurface: AppColors.surface,
      onInverseSurface: AppColors.onSurface,
      inversePrimary: AppColors.primary,
      surfaceTint: AppColors.darkOnSurface,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ════════════════════════════════════════════
  // SHARED THEME BUILDER
  // ════════════════════════════════════════════
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'BodoniModa',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        selectedItemColor: colorScheme.onSurface,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'HankenGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.08,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.parchmentCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.agedPaper,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
        thickness: 0.5,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.antiqueGold, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.05,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide(color: colorScheme.onSurface),
          textStyle: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.05,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onSurface;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.surfaceContainerHighest;
          return colorScheme.surfaceContainerHigh;
        }),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'BodoniModa', fontSize: 48, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.02, color: colorScheme.onSurface,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'BodoniModa', fontSize: 32, fontWeight: FontWeight.w600, height: 1.2, color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'BodoniModa', fontSize: 28, fontWeight: FontWeight.w600, height: 1.2, color: colorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontFamily: 'BodoniModa', fontSize: 22, fontWeight: FontWeight.w500, height: 1.4, color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Literata', fontSize: 18, fontWeight: FontWeight.w400, height: 1.6, color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Literata', fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontFamily: 'HankenGrotesk', fontSize: 14, fontWeight: FontWeight.w500, height: 1.2, letterSpacing: 0.05, color: colorScheme.onSurface,
        ),
        labelSmall: TextStyle(
          fontFamily: 'HankenGrotesk', fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.08, color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
