import 'package:flutter/material.dart';

/// מודל של "אריח" מודול במסך הבית.
///
/// כל תחום באפליקציה (קניות, רכבים, ביטוחים, חוגים וכו') מיוצג
/// ע"י HomeModule אחד. הוספת מודול חדש בעתיד דורשת רק להוסיף
/// ערך חדש ב-`home_modules.dart` - לא צריך לגעת ב-home_screen.dart.
///
/// אם `screenBuilder` הוא null (או `isAvailable` הוא false), האריח
/// מוצג "מעומעם" עם תווית "בקרוב" ולא מגיב ללחיצה - כך אפשר
/// "להכריז" מראש על מודולים עתידיים בממשק, עוד לפני שהם ממומשים.
class HomeModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAvailable;
  final WidgetBuilder? screenBuilder;

  const HomeModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isAvailable = false,
    this.screenBuilder,
  });
}

