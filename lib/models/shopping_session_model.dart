import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל "קנייה פעילה" - נוצר כשמישהו לוחץ "התחל קנייה",
/// ונסגר כשלוחצים "סיום קנייה".
class ShoppingSession {
  final String id;
  final DateTime? startedAt;
  final String startedBy;
  final String startedByName;
  final DateTime? endedAt;
  final String status; // 'active' | 'completed'

  const ShoppingSession({
    required this.id,
    required this.startedAt,
    required this.startedBy,
    required this.startedByName,
    this.endedAt,
    required this.status,
  });

  factory ShoppingSession.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingSession(
      id: id,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      startedBy: data['startedBy'] as String? ?? '',
      startedByName: data['startedByName'] as String? ?? '',
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      status: data['status'] as String? ?? 'active',
    );
  }

  static Map<String, dynamic> toFirestoreForStart({
    required String startedBy,
    required String startedByName,
  }) {
    return {
      'startedAt': FieldValue.serverTimestamp(),
      'startedBy': startedBy,
      'startedByName': startedByName,
      'endedAt': null,
      'status': 'active',
    };
  }

  static Map<String, dynamic> toFirestoreForEnd() {
    return {
      'endedAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    };
  }
}

