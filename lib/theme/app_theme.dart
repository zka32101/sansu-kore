/// Centralized theme and color palette for the application
/// Ensures consistency across all screens and widgets
///
/// UI デザイン統一 Phase 2: shared_core v3.0.0 AppColors/AppTypography 統合

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' show buildAppTheme, AppButton, AppCard, AppDialog, AppAppBar, AppSnackBar;

// 小学コレ！算数メインカラー（赤系 #E74C3C）
// 既存の多数の画面がこれらの定数を直接参照しているため、残す必要がある。
// v3.0.0: shared_core の SubjectColors.math（#1E40AF）との差分は意図的に保持
const kPrimaryColor = Color(0xFFE74C3C);
const kPrimaryDark = Color(0xFFC0392B);
const kPrimaryDeep = Color(0xFF922B21);
const kAccentGreen = Color(0xFF27AE60);
const kAccentBlue = Color(0xFF2980B9);
const kAccentOrange = Color(0xFFF39C12);
const kBgLight = Color(0xFFFDF6F0);
const kTextDark = Color(0xFF2C3E50);
const kTextMuted = Color(0xFF7F8C8D);

ThemeData buildSansuTheme() => buildAppTheme(
  primaryColor: kPrimaryColor,
  secondaryColor: kAccentGreen,
  bgColor: kBgLight,
);

// v3.0.0: 将来の Material Design 3 統一テーマ
// AppColors / AppTypography を使用する拡張テーマ関数
// 現在は既存の AppTheme と共存：段階的移行予定
ThemeData buildSansuThemeV3() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    primary: kPrimaryColor,
    secondary: kAccentGreen,
    surface: Colors.white,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: kBgLight,
  textTheme: const TextTheme(),  // TODO: Implement custom typography in Phase 4
  appBarTheme: AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),  // TODO: Use AppTypography when available
  ),
);

enum GradeGroup { low, mid, high }

GradeGroup gradeGroupOf(int grade) {
  if (grade <= 2) return GradeGroup.low;
  if (grade <= 4) return GradeGroup.mid;
  return GradeGroup.high;
}

Color gradeColor(GradeGroup g) {
  switch (g) {
    case GradeGroup.low: return const Color(0xFFE74C3C);
    case GradeGroup.mid: return const Color(0xFFC0392B);
    case GradeGroup.high: return const Color(0xFF922B21);
  }
}

/// Application color palette - centralized for easy theming
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Secondary colors
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF2E7D32);
  static const Color secondaryLight = Color(0xFF81C784);

  // Success/Failure/Warning colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Neutral colors
  static const Color grey = Color(0xFF757575);
  static const Color greyLight = Color(0xFFBDBDBD);
  static const Color greyLighter = Color(0xFFEEEEEE);
  static const Color greyDark = Color(0xFF424242);
  static const Color greyDarker = Color(0xFF212121);

  // Background colors
  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color bgDark = Color(0xFF121212);
  static const Color bgSurface = Color(0xFFFFFFFF);

  // Accuracy/Performance colors
  static const Color accuracyExcellent = Color(0xFF4CAF50); // >= 80%
  static const Color accuracyGood = Color(0xFF8BC34A);      // >= 60%
  static const Color accuracyFair = Color(0xFFFFB74D);      // >= 40%
  static const Color accuracyPoor = Color(0xFFEF5350);      // < 40%

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
}

/// Application text styles - centralized for consistent typography
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnPrimary,
  );
}

/// Application theme data - light and dark themes
class AppTheme {
  /// Light theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      cardColor: AppColors.bgSurface,
      dividerColor: AppColors.greyLighter,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.greyLighter,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
    );
  }

  /// Dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.greyDarker,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      cardColor: AppColors.greyDarker,
      dividerColor: AppColors.greyDark,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.greyDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
    );
  }
}

/// Convenience extension for accessing colors
extension ColorExtension on BuildContext {
  /// Get theme data from context
  ThemeData get theme => Theme.of(this);

  /// Get color scheme from context
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Check if current theme is dark
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Spacing constants for consistent layout
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants for consistent corners
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double full = 999.0;
}
