import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל של Household - "משק בית" (למשל "משפחת כהן").
///
/// memberIds נשמר גם כשדה ישיר על המסמך (ולא רק כ-subcollection)
/// כדי לאפשר שאילתה מהירה: "מצא את כל ה-households שאני חבר בהם"
/// (households.where('memberIds', arrayContains: myUid)).
class Household {
  final String id;
  final String name;
  final String createdBy;
  final DateTime? createdAt;
  final List<String> memberIds;

  const Household({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.memberIds,
  });

  factory Household.fromFirestore(String id, Map<String, dynamic> data) {
    return Household(
      id: id,
      name: data['name'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestoreForCreate(String creatorUid) {
    return {
      'name': name,
      'createdBy': creatorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'memberIds': [creatorUid],
    };
  }
}

