// lib/config/theme_config.dart
import 'package:flutter/material.dart';

/// Màu sắc cho ứng dụng y tế
class AppColors {
  AppColors._();

  // Màu chính - xanh dương
  static const Color primary = Color(0xFF1565C0); // Blue 800
  static const Color primaryLight = Color(0xFF42A5F5); // Blue 400
  static const Color primaryDark = Color(0xFF0D47A1); // Blue 900

  // Màu cơ bản
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF9E9E9E);

  // Màu nền
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;

  // Màu text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  // Màu trạng thái
  static const Color success = Color(0xFF4CAF50); // Xanh lá
  static const Color warning = Color(0xFFFF9800); // Cam
  static const Color error = Color(0xFFE53935); // Đỏ
  static const Color info = Color(0xFF2196F3); // Xanh dương nhạt

  // Màu input
  static const Color inputFill = Color(0xFFF3F8FF);
  static const Color inputBorder = Color(0xFFE0E0E0);
}

/// Kiểu chữ cho ứng dụng
class AppTextStyles {
  AppTextStyles._();

  // Tiêu đề
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Nội dung
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // AppBar
  static const TextStyle appBar = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

/// Kích thước và khoảng cách
class AppSizes {
  AppSizes._();

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Margin
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Button
  static const double buttonHeight = 48.0;

  // Icon
  static const double iconSmall = 20.0;
  static const double iconMedium = 30.0;
  static const double iconLarge = 40.0;
}

/// Kiểu button
class AppButtonStyles {
  AppButtonStyles._();

  // Button chính
  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
    ),
    padding: const EdgeInsets.symmetric(
      vertical: AppSizes.paddingMedium,
      horizontal: AppSizes.paddingLarge,
    ),
    minimumSize: const Size(0, AppSizes.buttonHeight),
  );

  // Button phụ
  static ButtonStyle secondary = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
    ),
    padding: const EdgeInsets.symmetric(
      vertical: AppSizes.paddingMedium,
      horizontal: AppSizes.paddingLarge,
    ),
    minimumSize: const Size(0, AppSizes.buttonHeight),
  );
}

/// Kiểu input
class AppInputStyles {
  AppInputStyles._();

  static InputDecoration standard({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(AppSizes.paddingMedium),
    );
  }
}

/// Theme chính của ứng dụng
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: AppColors.background,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      titleTextStyle: AppTextStyles.appBar,
      centerTitle: true,
      elevation: 0,
    ),

    // Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppButtonStyles.primary,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppButtonStyles.secondary,
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );
}