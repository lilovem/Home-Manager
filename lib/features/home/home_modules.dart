import 'package:flutter/material.dart';
import 'home_module.dart';
import '../shopping/shopping_list_screen.dart';

/// רשימת כל מודולי האפליקציה שמוצגים במסך הבית (Dashboard).
///
/// כדי להוסיף מודול חדש בעתיד (למשל מימוש בפועל של "חוגים"):
/// 1. בונים את המסך שלו תחת lib/features/<module_name>/
/// 2. מוסיפים כאן HomeModule עם isAvailable: true ו-screenBuilder מתאים
///
/// מודולים עם isAvailable: false (ברירת המחדל) מוצגים כ"בקרוב" -
/// כך אפשר להראות כבר עכשיו את כל התוכנית העתידית של האפליקציה
/// למשתמש, בלי לממש את הלוגיקה בפועל.
List<HomeModule> buildHomeModules({required String householdId}) {
  return [
    HomeModule(
      title: 'רשימת קניות',
      subtitle: 'קניות משותפות בזמן אמת',
      icon: Icons.shopping_cart_outlined,
      isAvailable: true,
      screenBuilder: (_) => ShoppingListScreen(householdId: householdId),
    ),
    const HomeModule(
      title: 'רכבים',
      subtitle: 'טסטים, טיפולים וקילומטראז\'',
      icon: Icons.directions_car_outlined,
    ),
    const HomeModule(
      title: 'ביטוחים',
      subtitle: 'פוליסות ותאריכי חידוש',
      icon: Icons.shield_outlined,
    ),
    const HomeModule(
      title: 'רישיונות',
      subtitle: 'תעודות ומסמכים בעלי תוקף',
      icon: Icons.badge_outlined,
    ),
    const HomeModule(
      title: 'חוגים',
      subtitle: 'פעילויות ולוחות זמנים',
      icon: Icons.sports_soccer_outlined,
    ),
    const HomeModule(
      title: 'חשבונות',
      subtitle: 'חשמל, מים, ארנונה ומנויים',
      icon: Icons.receipt_long_outlined,
    ),
    const HomeModule(
      title: 'מסמכים',
      subtitle: 'קבצים ותעודות חשובות',
      icon: Icons.folder_outlined,
    ),
    const HomeModule(
      title: 'משימות ותזכורות',
      subtitle: 'ניהול משק הבית היומיומי',
      icon: Icons.checklist_outlined,
    ),
  ];
}
