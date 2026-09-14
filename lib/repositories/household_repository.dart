import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failures.dart';
import '../models/household_member_model.dart';
import '../models/household_model.dart';
import '../services/firebase/household_service.dart';

/// השכבה שה-UI קורא לה בפועל ליצירה/הצטרפות/ניהול חברי Household.
class HouseholdRepository {
  final HouseholdService _service;

  HouseholdRepository(this._service);

  Stream<Household?> watchMyHousehold(String uid) {
    return _service.watchMyHousehold(uid);
  }

  Stream<List<Household>> watchMyHouseholds(String uid) {
    return _service.watchMyHouseholds(uid);
  }

  Future<Household> createHousehold({
    required String name,
    required String creatorUid,
    required String creatorEmail,
  }) async {
    try {
      return await _service.createHousehold(
        name: name,
        creatorUid: creatorUid,
        creatorEmail: creatorEmail,
      );
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> joinHousehold({
    required String householdId,
    required String uid,
    required String email,
  }) async {
    try {
      await _service.joinHousehold(
        householdId: householdId.trim(),
        uid: uid,
        email: email,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw const PermissionFailure('קוד ההזמנה לא נמצא, בדקו שהעתקתם אותו נכון');
      }
      throw _mapError(e);
    }
  }

  Future<void> deleteHousehold(String householdId) async {
    try {
      await _service.deleteHousehold(householdId);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה במחיקת משק הבית');
    }
  }

  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return _service.watchMembers(householdId);
  }

  Future<void> ensureMemberEmail({
    required String householdId,
    required String uid,
    required String email,
  }) async {
    try {
      await _service.ensureMemberEmail(householdId: householdId, uid: uid, email: email);
    } on FirebaseException {
      // שגיאה בתיקון רקע לא קריטית - לא מציגים למשתמש.
    }
  }

  Future<void> removeMember({
    required String householdId,
    required String memberUid,
  }) async {
    try {
      await _service.removeMember(householdId: householdId, memberUid: memberUid);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בהסרת החבר');
    }
  }

  Failure _mapError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return const PermissionFailure();
    }
    return const UnknownFailure();
  }
}

