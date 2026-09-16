import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bill_payment_model.dart';

/// שירות Firestore לרשומות תשלום חשבונות (ועד בית/חשמל/מים+ארנונה).
/// כל רשומה מזוהה באמצעות מזהה קבוע (לא auto-id) - כך אפשר
/// לכתוב עליה מחדש (get-or-create) בלי לחפש קודם.
class BillsService {
  final FirebaseFirestore _firestore;

  BillsService(this._firestore);

  CollectionReference<Map<String, dynamic>> _billsCollection(String householdId) {
    return _firestore.collection('households').doc(householdId).collection('bills');
  }

  String _docId(BillCategory category, int year, int periodStartMonth) {
    return '${billCategoryToString(category)}_${year}_$periodStartMonth';
  }

  Stream<List<BillPayment>> watchBills({
    required String householdId,
    required BillCategory category,
    required int year,
  }) {
    return _billsCollection(householdId)
        .where('category', isEqualTo: billCategoryToString(category))
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BillPayment.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// שומר סכום+אמצעי תשלום, ותמיד מסמן את התקופה כ"שולם" (אין
  /// יותר מנגנון קבלות - השמירה עצמה היא אישור התשלום).
  Future<void> saveBillDetails({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
    double? amount,
    String? paymentMethod,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    await _billsCollection(householdId).doc(id).set({
      'category': billCategoryToString(category),
      'year': year,
      'periodStartMonth': periodStartMonth,
      if (amount != null) 'amount': amount,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'paidManually': true,
      'paidAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// מבטל תשלום שכבר סומן - מחזיר את התקופה למצב "לא שולם" (ה-חוג
  /// הירוק נעלם), **וגם מנקה את הסכום ואמצעי התשלום** (לא רק את
  /// סטטוס "שולם") - כך שהשורה חוזרת למראה "ריק לגמרי", לא רק
  /// "לא שולם עם סכום ישן שמור".
  Future<void> cancelPayment({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    await _billsCollection(householdId).doc(id).update({
      'paidManually': false,
      'paidAt': null,
      'amount': null,
      'paymentMethod': null,
    });
  }

  String billDocId(BillCategory category, int year, int periodStartMonth) =>
      _docId(category, year, periodStartMonth);
}

