import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  /// סגנון מעודן לטאגליין ("ניהול הבית שלכם") - גופן סריף עברי
  /// אלגנטי (Frank Ruhl Libre). הערה: אין גופני "כתב-יד" אמיתיים
  /// לעברית ב-Google Fonts כרגע - זו הקירוב הכי אלגנטי הזמין.
  static TextStyle tagline({Color color = AppColors.textSecondary, double fontSize = 13}) {
    return GoogleFonts.frankRuhlLibre(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );
  }

  /// כותרת קטגוריה+שנה (למשל "ועד בית · 2026") - אותו גופן סריף
  /// אלגנטי, קצת יותר גדול ובצבע ראשי, במקום כותרת AppBar יבשה.
  static TextStyle categoryTitle({double fontSize = 19}) {
    return GoogleFonts.frankRuhlLibre(
      fontSize: fontSize,
      color: AppColors.primaryDark,
      fontWeight: FontWeight.w600,
    );
  }
}

