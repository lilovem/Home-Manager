import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל של רשימת קניות. household יכול להכיל כמה רשימות שונות
/// (למשל: "קניות שבועיות", "קניות לשבת", "רשימה לחג") - לא רק אחת.
/// `date` אופציונלי - מיועד לתכנון קנייה לתאריך עתידי ספציפי.
class ShoppingList {
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? date;
  final String? activeSessionId;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.date,
    this.activeSessionId,
  });

  factory ShoppingList.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingList(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      date: (data['date'] as Timestamp?)?.toDate(),
      activeSessionId: data['activeSessionId'] as String?,
    );
  }

  static Map<String, dynamic> toFirestoreForCreate(String name, {DateTime? date}) {
    return {
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'date': date != null ? Timestamp.fromDate(date) : null,
      'activeSessionId': null,
    };
  }
}

