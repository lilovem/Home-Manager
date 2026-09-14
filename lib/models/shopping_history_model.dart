import 'package:cloud_firestore/cloud_firestore.dart';

/// רשומת היסטוריה של קנייה שהושלמה - סיכום, לא הפריטים המלאים.
class ShoppingHistoryEntry {
  final String id;
  final DateTime? date;
  final int totalItems;
  final int purchasedCount;
  final int notFoundCount;
  final List<String> notFoundItemNames;
  final String completedBy;
  final String completedByName;
  final List<String> purchasedItemNames;
  final List<String> carriedOverItemNames;
  final List<String> droppedItemNames;

  const ShoppingHistoryEntry({
    required this.id,
    required this.date,
    required this.totalItems,
    required this.purchasedCount,
    required this.notFoundCount,
    required this.notFoundItemNames,
    required this.completedBy,
    required this.completedByName,
    this.purchasedItemNames = const [],
    this.carriedOverItemNames = const [],
    this.droppedItemNames = const [],
  });

  factory ShoppingHistoryEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingHistoryEntry(
      id: id,
      date: (data['date'] as Timestamp?)?.toDate(),
      totalItems: (data['totalItems'] as num?)?.toInt() ?? 0,
      purchasedCount: (data['purchasedCount'] as num?)?.toInt() ?? 0,
      notFoundCount: (data['notFoundCount'] as num?)?.toInt() ?? 0,
      notFoundItemNames: List<String>.from(data['notFoundItemNames'] as List? ?? []),
      completedBy: data['completedBy'] as String? ?? '',
      completedByName: data['completedByName'] as String? ?? '',
      purchasedItemNames: List<String>.from(data['purchasedItemNames'] as List? ?? []),
      carriedOverItemNames: List<String>.from(data['carriedOverItemNames'] as List? ?? []),
      droppedItemNames: List<String>.from(data['droppedItemNames'] as List? ?? []),
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required int totalItems,
    required int purchasedCount,
    required int notFoundCount,
    required List<String> notFoundItemNames,
    required String completedBy,
    required String completedByName,
    List<String> purchasedItemNames = const [],
    List<String> carriedOverItemNames = const [],
    List<String> droppedItemNames = const [],
  }) {
    return {
      'date': FieldValue.serverTimestamp(),
      'totalItems': totalItems,
      'purchasedCount': purchasedCount,
      'notFoundCount': notFoundCount,
      'notFoundItemNames': notFoundItemNames,
      'completedBy': completedBy,
      'completedByName': completedByName,
      'purchasedItemNames': purchasedItemNames,
      'carriedOverItemNames': carriedOverItemNames,
      'droppedItemNames': droppedItemNames,
    };
  }
}

