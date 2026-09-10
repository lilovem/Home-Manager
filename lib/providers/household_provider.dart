import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
final myHouseholdProvider = StreamProvider<Household?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(null);
  }

  return ref.watch(householdRepositoryProvider).watchMyHousehold(user.uid);
});

