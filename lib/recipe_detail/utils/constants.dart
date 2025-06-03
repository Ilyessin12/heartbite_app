import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFB71C1C); // Dark red color
  static const cardBackground = Color(0xFFF8F0F0); // Light pink background
  static const textPrimary = Color(0xFF333333);
  static const textSecondary = Color(0xFF666666);
}

class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}