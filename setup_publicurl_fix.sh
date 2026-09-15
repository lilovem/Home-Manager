#!/bin/bash
set -e
cat > 'lib/app/config/app_config.dart' << 'HMEOF'
/// כל ההגדרות הכלליות של האפליקציה מרוכזות כאן.
///
/// זהו המקום היחיד ששם המותג, הגדרות ברירת המחדל וכדומה מוגדרים בו.
/// אם בעתיד נרצה לשנות את שם האפליקציה (למשל ל-"Domira"),
/// צריך לשנות רק את הקובץ הזה — לא לחפש בכל הפרויקט.
class AppConfig {
  AppConfig._(); // מונע יצירת מופע של המחלקה - זו מחלקת קבועים בלבד

  /// שם האפליקציה כפי שהוא מוצג למשתמש
  static const String appName = 'LeeHome';

  /// טאגליין קצר - מוצג לצד השם במסכי כניסה
  static const String appTagline = 'ניהול הבית שלכם';

  /// גרסת האפליקציה (מוצגת במסך הגדרות)
  static const String appVersion = '0.1.0';

  /// גודל ברירת מחדל של רשימת קניות חדשה
  static const String defaultShoppingListName = 'קניות שבועיות';

  /// כמה זמן (בימים) לשמור מוצרים ב"רשימת להשלים" לפני שמנקים אוטומטית
  /// (לא בשימוש עדיין - מוכן לעתיד)
  static const int missingItemsRetentionDays = 30;

  /// הכתובת הקבועה של האפליקציה (Firebase Hosting) - זו שמשתפים
  /// עם אנשים אחרים, לא כתובת הפיתוח הזמנית של ה-Codespace.
  static const String publicUrl = 'https://leehome-app.web.app';
}

HMEOF
echo 'DONE - share link now points to leehome-app.web.app!'
