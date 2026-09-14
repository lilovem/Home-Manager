import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/household_member_model.dart';
import '../models/household_model.dart';
import '../repositories/household_repository.dart';
import '../services/firebase/household_service.dart';
import 'auth_provider.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final householdServiceProvider = Provider<HouseholdService>((ref) {
  return HouseholdService(ref.watch(firestoreProvider));
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(ref.watch(householdServiceProvider));
});

/// ה-Household של המשתמש המחובר כרגע - null אם עוד אין לו אחד.
///
/// תלוי ב-authStateChangesProvider: אם המשתמש מתנתק, ה-stream הזה
/// מפסיק אוטומטית להאזין ל-household של המשתמש הקודם.
/// הערה: מחזיר רק household אחד (הראשון) - לרשימה מלאה של כל
/// ה-households שהמשתמש חבר בהם, ראה myHouseholdsProvider למטה.
final myHouseholdProvider = StreamProvider<Household?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(null);
  }

  return ref.watch(householdRepositoryProvider).watchMyHousehold(user.uid);
});

/// כל ה-households שהמשתמש המחובר חבר בהם (לא רק אחד) - תומך
/// בתרחיש של משתמש שחבר בכמה בתים (למשל: הבית שלו, ובית של הורה).
final myHouseholdsProvider = StreamProvider<List<Household>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(<Household>[]);
  }

  return ref.watch(householdRepositoryProvider).watchMyHouseholds(user.uid);
});

/// מזהה ה-household שנבחר כ"פעיל" כרגע - נשמר רק בזיכרון (לא נשמר
/// בין sessions). null = עדיין לא נבחר במפורש, אז currentHouseholdProvider
/// ייפול חזרה לראשון ברשימה.
final selectedHouseholdIdProvider = StateProvider<String?>((ref) => null);

/// ה-household הפעיל בפועל - זה שנבחר במפורש, או הראשון ברשימה כברירת
/// מחדל. זהו ה-provider שרוב המסכים (Home, Shopping List וכו') אמורים
/// להשתמש בו במקום myHouseholdProvider הישן.
final currentHouseholdProvider = Provider<Household?>((ref) {
  final households = ref.watch(myHouseholdsProvider).value ?? const <Household>[];
  if (households.isEmpty) return null;

  final selectedId = ref.watch(selectedHouseholdIdProvider);
  final match = households.where((h) => h.id == selectedId);
  return match.isNotEmpty ? match.first : households.first;
});

/// רשימת החברים בפועל של household מסוים.
final householdMembersProvider =
    StreamProvider.family<List<HouseholdMember>, String>((ref, householdId) {
  return ref.watch(householdRepositoryProvider).watchMembers(householdId);
});

