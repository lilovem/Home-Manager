import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל של רשימת קניות. ב-MVP לכל household יש רשימה אחת בלבד
/// (ה-id שלה נשמר על מסמך ה-household עצמו כ-shoppingListId).
class ShoppingList {
  final String id;
  final String name;
  final DateTime? createdAt;
  final String? activeSessionId;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.activeSessionId,
  });

  factory ShoppingList.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingList(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      activeSessionId: data['activeSessionId'] as String?,
    );
  }

  static Map<String, dynamic> toFirestoreForCreate(String name) {
    return {
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

