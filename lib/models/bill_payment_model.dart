import 'package:cloud_firestore/cloud_firestore.dart';

/// קטגוריית חשבון. כרגע רק ועד-בית פעיל בפועל; חשמל ומים+ארנונה
/// שמורים לעתיד (אותו מודל, "בקרוב" ב-UI).
enum BillCategory { vaadBayit, electricity, waterAndTax, water, tax }

String billCategoryToString(BillCategory c) => c.name;

/// שם עברי קצר לתצוגה (למשל בלוח השנה) - לא ל-Firestore.
String billCategoryDisplayName(BillCategory c) {
  switch (c) {
    case BillCategory.vaadBayit:
      return 'ועד בית';
    case BillCategory.electricity:
      return 'חשמל';
    case BillCategory.waterAndTax:
      return 'מים וארנונה';
    case BillCategory.water:
      return 'מים';
    case BillCategory.tax:
      return 'ארנונה';
  }
}

BillCategory billCategoryFromString(String s) {
  return BillCategory.values.firstWhere(
    (c) => c.name == s,
    orElse: () => BillCategory.vaadBayit,
  );
}

/// רשומת תשלום עבור תקופה אחת. חודש אחד לועד-בית, חודשיים
/// לחשמל/מים+ארנונה - המזהה של המסמך כבר מקודד את התקופה,
/// למשל "vaadBayit_2026_9" או "waterAndTax_2026_9" (חודש הראשון
/// בזוג).
class BillPayment {
  final String id;
  final BillCategory category;
  final int year;
  final int periodStartMonth; // 1-12
  final double? amount;
  final String? paymentMethod;
  final DateTime? paidAt;
  final bool paidManually;
  final DateTime? reminderAt;
  final bool reminderShown;

  const BillPayment({
    required this.id,
    required this.category,
    required this.year,
    required this.periodStartMonth,
    this.amount,
    this.paymentMethod,
    this.paidAt,
    this.paidManually = false,
    this.reminderAt,
    this.reminderShown = false,
  });

  /// "שולם" = סומן ידנית (בשמירה, או עד שמבטלים דרך החלקה על השורה).
  bool get isPaid => paidManually;

  factory BillPayment.fromFirestore(String id, Map<String, dynamic> data) {
    return BillPayment(
      id: id,
      category: billCategoryFromString(data['category'] as String? ?? 'vaadBayit'),
      year: (data['year'] as num?)?.toInt() ?? DateTime.now().year,
      periodStartMonth: (data['periodStartMonth'] as num?)?.toInt() ?? 1,
      amount: (data['amount'] as num?)?.toDouble(),
      paymentMethod: data['paymentMethod'] as String?,
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      paidManually: data['paidManually'] as bool? ?? false,
      reminderAt: (data['reminderAt'] as Timestamp?)?.toDate(),
      reminderShown: data['reminderShown'] as bool? ?? false,
    );
  }
}

