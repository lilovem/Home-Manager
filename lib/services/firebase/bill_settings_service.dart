import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bill_link_settings_model.dart';

/// שירות Firestore להגדרות קישורי תשלום (חד-פעמי, נערך לפי הצורך).
/// נשמר במסמך יחיד: households/{id}/settings/billLinks
class BillSettingsService {
  final FirebaseFirestore _firestore;

  BillSettingsService(this._firestore);

  DocumentReference<Map<String, dynamic>> _doc(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('settings')
        .doc('billLinks');
  }

  Stream<BillLinkSettings> watchSettings(String householdId) {
    return _doc(householdId)
        .snapshots()
        .map((snapshot) => BillLinkSettings.fromFirestore(snapshot.data()));
  }

  Future<void> saveBitUrl(String householdId, String url) {
    return _doc(householdId).set({'bitUrl': url}, SetOptions(merge: true));
  }

  Future<void> savePayboxUrl(String householdId, String url) {
    return _doc(householdId).set({'payboxUrl': url}, SetOptions(merge: true));
  }

  Future<void> saveElectricityUrl(String householdId, String url) {
    return _doc(householdId).set({'electricityUrl': url}, SetOptions(merge: true));
  }

  Future<void> saveCombinedWaterTaxUrl(String householdId, String url) {
    return _doc(householdId).set({
      'waterAndTaxCombined': true,
      'combinedWaterTaxUrl': url,
    }, SetOptions(merge: true));
  }

  Future<void> saveSeparateWaterTaxUrls(String householdId, String waterUrl, String taxUrl) {
    return _doc(householdId).set({
      'waterAndTaxCombined': false,
      'waterUrl': waterUrl,
      'taxUrl': taxUrl,
    }, SetOptions(merge: true));
  }
}

