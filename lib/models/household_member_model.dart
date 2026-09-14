import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל של חבר household - נשמר כמסמך נפרד בתוך members subcollection.
class HouseholdMember {
  final String uid;
  final String email;
  final String role; // 'owner' | 'member'
  final DateTime? joinedAt;

  const HouseholdMember({
    required this.uid,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory HouseholdMember.fromFirestore(String uid, Map<String, dynamic> data) {
    return HouseholdMember(
      uid: uid,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }
}

