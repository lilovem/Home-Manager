import 'package:flutter/material.dart';
import 'app_colors.dart';

/// סגנונות טקסט מרכזיים.
/// כל שינוי בגופן/גודל/משקל של האפליקציה נעשה כאן בלבד.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Rubik'; // גופן תומך עברית, יתווסף בשלב עיצוב

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
