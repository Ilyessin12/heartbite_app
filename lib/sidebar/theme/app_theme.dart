import 'package:flutter/material.dart';

class AppColors {
  // Update the color palette to match the design
  static const Color primary = Color(0xFF8E1616);
  static const Color secondary = Color(0xFFF9E3D5);
  static const Color background = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF000000);
  static const Color grayLight = Color(0xFFE3E5E8);
  static const Color grayMedium = Color(0xFFD7D7D7);
  static const Color grayDark = Color(0xFF303030);
  static const Color darkHeader = Color(0xFF0A1A22);
  static const Color tabInactive = Color(0xFFAAAAAA);
  static const Color cardOverlay = Color(0x80000000);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: AppColors.text,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: AppColors.grayDark,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.5);
          }
          return AppColors.grayMedium;
        }),
      ),
    );
  }
}
