import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        surface: AppColors.white,
        onSurface: AppColors.darkGray,
      ),
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'Roboto',
    );
  }
}
