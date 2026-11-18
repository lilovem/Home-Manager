import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// פתק אחד (דף) בהערות של משק הבית.
class NotePage {
  final String id;
  final String text;
  final int color;
  final DateTime? updatedAt;

  const NotePage({
    required this.id,
    required this.text,
    required this.color,
    required this.updatedAt,
  });

  factory NotePage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['updatedAt'];
    return NotePage(
      id: doc.id,
      text: (data['text'] as String?) ?? '',
      color: (data['color'] as int?) ?? 0,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

CollectionReference<Map<String, dynamic>> notesCollection(String householdId) {
  return FirebaseFirestore.instance
      .collection('households')
      .doc(householdId)
      .collection('notes');
}

/// כל הפתקים של משק הבית, החדשים ביותר ראשונים.
final notePagesProvider =
    StreamProvider.family<List<NotePage>, String>((ref, householdId) {
  return notesCollection(householdId).snapshots().map((snap) {
    final list = snap.docs.map(NotePage.fromDoc).toList();
    final now = DateTime.now();
    list.sort((a, b) => (b.updatedAt ?? now).compareTo(a.updatedAt ?? now));
    return list;
  });
});
