import 'package:cloud_firestore/cloud_firestore.dart';

/// רשומת היסטוריה של קנייה שהושלמה - סיכום, לא הפריטים המלאים.
class ShoppingHistoryEntry {
  final String id;
  final DateTime? date;
  final int totalItems;
  final int purchasedCount;
  final int notFoundCount;
  final List<String> notFoundItemNames;

  const ShoppingHistoryEntry({
    required this.id,
    required this.date,
    required this.totalItems,
    required this.purchasedCount,
    required this.notFoundCount,
    required this.notFoundItemNames,
  });

  factory ShoppingHistoryEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingHistoryEntry(
      id: id,
      date: (data['date'] as Timestamp?)?.toDate(),
      totalItems: (data['totalItems'] as num?)?.toInt() ?? 0,
      purchasedCount: (data['purchasedCount'] as num?)?.toInt() ?? 0,
      notFoundCount: (data['notFoundCount'] as num?)?.toInt() ?? 0,
      notFoundItemNames: List<String>.from(data['notFoundItemNames'] as List? ?? []),
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required int totalItems,
    required int purchasedCount,
    required int notFoundCount,
    required List<String> notFoundItemNames,
  }) {
    return {
      'date': FieldValue.serverTimestamp(),
      'totalItems': totalItems,
      'purchasedCount': purchasedCount,
      'notFoundCount': notFoundCount,
      'notFoundItemNames': notFoundItemNames,
    };
  }
}

