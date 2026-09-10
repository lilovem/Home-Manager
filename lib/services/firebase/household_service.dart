import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/household_model.dart';

/// עטיפה דקה סביב קריאות Firestore הקשורות ל-Household.
/// שכבת Service - רק "מדברת" עם Firebase, בלי לוגיקה עסקית.
class HouseholdService {
  final FirebaseFirestore _firestore;

  HouseholdService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _households =>
      _firestore.collection('households');

  /// מאזין ל-household הראשון שהמשתמש חבר בו.
  /// (בשלב ה-MVP מניחים משתמש אחד = household אחד; הארכיטקטורה
  /// תומכת בעתיד בכמה households לפי אותה שאילתה בלי limit(1)).
  Stream<Household?> watchMyHousehold(String uid) {
    return _households
        .where('memberIds', arrayContains: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return Household.fromFirestore(doc.id, doc.data());
    });
  }

  Future<Household> createHousehold({
    required String name,
    required String creatorUid,
  }) async {
    final docRef = await _households.add(
      Household(
        id: '',
        name: name,
        createdBy: creatorUid,
        createdAt: null,
        memberIds: const [],
      ).toFirestoreForCreate(creatorUid),
    );

    await docRef.collection('members').doc(creatorUid).set({
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await docRef.get();
    return Household.fromFirestore(snapshot.id, snapshot.data()!);
  }

  Future<void> joinHousehold({
    required String householdId,
    required String uid,
  }) async {
    final docRef = _households.doc(householdId);

    await docRef.update({
      'memberIds': FieldValue.arrayUnion([uid]),
    });

    await docRef.collection('members').doc(uid).set({
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }
}

