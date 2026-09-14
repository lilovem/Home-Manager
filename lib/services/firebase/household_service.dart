import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/household_member_model.dart';
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

  /// מאזין לכל ה-households שהמשתמש חבר בהם.
  Stream<List<Household>> watchMyHouseholds(String uid) {
    return _households.where('memberIds', arrayContains: uid).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Household.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<Household> createHousehold({
    required String name,
    required String creatorUid,
    required String creatorEmail,
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
      'email': creatorEmail,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await docRef.get();
    return Household.fromFirestore(snapshot.id, snapshot.data()!);
  }

  Future<void> joinHousehold({
    required String householdId,
    required String uid,
    required String email,
  }) async {
    final docRef = _households.doc(householdId);

    await docRef.update({
      'memberIds': FieldValue.arrayUnion([uid]),
    });

    await docRef.collection('members').doc(uid).set({
      'role': 'member',
      'email': email,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  /// מוחקת household לגמרי - כולל כל תת-האוספים שלו (members,
  /// shoppingLists + items + sessions, shoppingHistory). מיועד
  /// לשימוש רק ע"י הבעלים (createdBy) - נאכף גם ב-Security Rules.
  Future<void> deleteHousehold(String householdId) async {
    final docRef = _households.doc(householdId);

    // מוחקים את כל מסמכי members.
    final membersSnapshot = await docRef.collection('members').get();
    for (final doc in membersSnapshot.docs) {
      await doc.reference.delete();
    }

    // מוחקים כל shoppingList, כולל items ו-sessions שבתוכו.
    final listsSnapshot = await docRef.collection('shoppingLists').get();
    for (final listDoc in listsSnapshot.docs) {
      final itemsSnapshot = await listDoc.reference.collection('items').get();
      for (final item in itemsSnapshot.docs) {
        await item.reference.delete();
      }
      final sessionsSnapshot = await listDoc.reference.collection('sessions').get();
      for (final session in sessionsSnapshot.docs) {
        await session.reference.delete();
      }
      await listDoc.reference.delete();
    }

    // מוחקים את היסטוריית הקניות.
    final historySnapshot = await docRef.collection('shoppingHistory').get();
    for (final doc in historySnapshot.docs) {
      await doc.reference.delete();
    }

    // לבסוף, מוחקים את מסמך ה-household עצמו.
    await docRef.delete();
  }

  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return _households.doc(householdId).collection('members').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => HouseholdMember.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// משלים/מעדכן את שדה ה-email על מסמך החברות של המשתמש הנוכחי.
  /// נועד לתקן households ישנים שנוצרו לפני שהשדה הזה נוסף - כל
  /// משתמש "מתקן" את הרשומה של עצמו בפעם הבאה שהוא נכנס לאפליקציה.
  Future<void> ensureMemberEmail({
    required String householdId,
    required String uid,
    required String email,
  }) {
    return _households.doc(householdId).collection('members').doc(uid).set(
      {'email': email},
      SetOptions(merge: true),
    );
  }

  /// מסיר חבר מה-household: מוחק את מסמך החברות שלו, ומוציא אותו
  /// ממערך memberIds. myHouseholdProvider אצל המשתמש שהוסר יזהה
  /// את זה אוטומטית (השאילתה לא תחזיר יותר את ה-household הזה עבורו).
  Future<void> removeMember({
    required String householdId,
    required String memberUid,
  }) async {
    final batch = _firestore.batch();
    final docRef = _households.doc(householdId);

    batch.delete(docRef.collection('members').doc(memberUid));
    batch.update(docRef, {
      'memberIds': FieldValue.arrayRemove([memberUid]),
    });

    await batch.commit();
  }
}

