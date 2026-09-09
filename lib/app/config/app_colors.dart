import 'package:flutter/material.dart';

/// פלטת הצבעים המרכזית של האפליקציה.
///
/// אף widget לא אמור להשתמש בצבע "קשיח" (כמו Colors.green ישירות).
/// במקום זאת, תמיד יש להשתמש בקבועים מהמחלקה הזו.
/// כך שינוי "צבע המותג" בעתיד יהיה שינוי במקום אחד בלבד.
class AppColors {
  AppColors._();

  // צבעי בסיס
  static const Color primary = Color(0xFF2E7D5B); // ירוק ראשי
  static const Color primaryLight = Color(0xFFE8F5EE);
  static const Color background = Color(0xFFFFFFFF); // לבן
  static const Color surface = Color(0xFFF5F5F5); // אפור בהיר

  // טקסט
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  // סטטוסים של מוצרים ברשימת הקניות
  static const Color itemPurchased = Color(0xFF2E7D5B); // ירוק - נקנה
  static const Color itemNotFound = Color(0xFFE65100); // כתום - לא נמצא
  static const Color itemNewBadge = Color(0xFF1976D2); // כחול - "חדש"

  // מצבי שגיאה/אזהרה
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);

  // גבולות וחלוקות
  static const Color divider = Color(0xFFE0E0E0);
}
