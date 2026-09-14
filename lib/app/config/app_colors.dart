import 'package:flutter/material.dart';

/// פלטת הצבעים המרכזית של האפליקציה.
///
/// אף widget לא אמור להשתמש בצבע "קשיח" (כמו Colors.blue ישירות).
/// במקום זאת, תמיד יש להשתמש בקבועים מהמחלקה הזו.
/// כך שינוי "צבע המותג" בעתיד יהיה שינוי במקום אחד בלבד.
class AppColors {
  AppColors._();

  // צבעי בסיס - עודכן לכחול לפי הלוגו (Smart Home) שנבחר.
  static const Color primary = Color(0xFF00A3DA); // כחול ראשי
  static const Color primaryDark = Color(0xFF0075AA); // כחול כהה - לגרדיאנטים
  static const Color primaryLight = Color(0xFFE1F5FB);
  static const Color background = Color(0xFFFFFFFF); // לבן
  static const Color surface = Color(0xFFF5F5F5); // אפור בהיר

  // טקסט
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  // סטטוסים של מוצרים ברשימת הקניות - אלה צבעים סמנטיים (משמעות
  // קבועה: הצלחה/אזהרה), לא צבעי מותג - נשארים גם אחרי שינוי הצבע הראשי.
  static const Color itemPurchased = Color(0xFF2E7D5B); // ירוק - נקנה
  static const Color itemNotFound = Color(0xFFE65100); // כתום - לא נמצא
  static const Color itemNewBadge = Color(0xFF7B1FA2); // סגול - "חדש" (שונה מהכחול הראשי כדי לא להתבלבל)

  // מצבי שגיאה/אזהרה
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);

  // גבולות וחלוקות
  static const Color divider = Color(0xFFE0E0E0);
}

