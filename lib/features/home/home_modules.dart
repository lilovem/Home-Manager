import 'package:flutter/material.dart';
import 'home_module.dart';
import '../shopping/shopping_choice_screen.dart';
import '../vehicles/vehicles_list_screen.dart';

/// 4 המודולים ה"מומלצים" שמוצגים בכרטיסיות סטטיסטיקה צבעוניות
/// בראש מסך הבית (בהשראת עיצוב שהמשתמש שלח) - קניות (פעיל), ואז
/// משימות/רכבים/לוח שנה כ"בקרוב" (לוח שנה כן מציג נתון אמיתי,
/// המבוסס על תאריכי רשימות קניות קיימים - ראה home_screen.dart).
List<HomeModule> buildFeaturedModules({required String householdId}) {
  return [
    HomeModule(
      title: 'קניות',
      subtitle: 'פריטים ברשימה',
      icon: Icons.shopping_cart_outlined,
      isAvailable: true,
      screenBuilder: (_) => ShoppingChoiceScreen(householdId: householdId),
    ),
    const HomeModule(
      title: 'לוח שנה',
      subtitle: 'אירועים קרובים',
      icon: Icons.calendar_month_outlined,
    ),
    const HomeModule(
      title: 'משימות',
      subtitle: 'ניהול משק הבית היומיומי',
      icon: Icons.checklist_outlined,
    ),
    HomeModule(
      title: 'רכבים',
      subtitle: 'טסטים, טיפולים וקילומטראז\'',
      icon: Icons.directions_car_outlined,
      isAvailable: true,
      screenBuilder: (_) => VehiclesListScreen(householdId: householdId),
    ),
  ];
}

/// שאר מודולי העתיד - מוצגים ברשת הרגילה מתחת לכרטיסיות המומלצות,
/// כולם עדיין "בקרוב". "חשבונות" הוסר מכאן - יש כבר מודול חשבונות
/// מלא ופעיל במסך הבית, אז אריח כפול כאן רק מבלבל.
///
/// כדי להוסיף מודול חדש בעתיד:
/// 1. בונים את המסך שלו תחת lib/features/<module_name>/
/// 2. מוסיפים כאן HomeModule עם isAvailable: true ו-screenBuilder מתאים
List<HomeModule> buildHomeModules({required String householdId}) {
  return const [
    HomeModule(
      title: 'ביטוחים',
      subtitle: 'פוליסות ותאריכי חידוש',
      icon: Icons.shield_outlined,
    ),
    HomeModule(
      title: 'רישיונות',
      subtitle: 'תעודות ומסמכים בעלי תוקף',
      icon: Icons.badge_outlined,
    ),
    HomeModule(
      title: 'חוגים',
      subtitle: 'פעילויות ולוחות זמנים',
      icon: Icons.sports_soccer_outlined,
    ),
    HomeModule(
      title: 'מסמכים',
      subtitle: 'קבצים ותעודות חשובות',
      icon: Icons.folder_outlined,
    ),
  ];
}
