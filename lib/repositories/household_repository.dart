import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failures.dart';
import '../models/household_model.dart';
import '../services/firebase/household_service.dart';

/// השכבה שה-UI קורא לה בפועל ליצירה/הצטרפות ל-Household.
class HouseholdRepository {
  final HouseholdService _service;

  HouseholdRepository(this._service);

  Stream<Household?> watchMyHousehold(String uid) {
    return _service.watchMyHousehold(uid);
  }

  Future<Household> createHousehold({
    required String name,
    required String creatorUid,
  }) async {
    try {
      return await _service.createHousehold(name: name, creatorUid: creatorUid);
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> joinHousehold({
    required String householdId,
    required String uid,
  }) async {
    try {
      await _service.joinHousehold(householdId: householdId.trim(), uid: uid);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw const PermissionFailure('קוד ההזמנה לא נמצא, בדקו שהעתקתם אותו נכון');
      }
      throw _mapError(e);
    }
  }

  Failure _mapError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return const PermissionFailure();
    }
    return const UnknownFailure();
  }
}

