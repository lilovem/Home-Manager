#!/bin/bash
set -e
cat > 'lib/services/firebase/bills_service.dart' << 'HMEOF'
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
  /// שומר סכום+אמצעי תשלום. מסמן "שולם" (paidManually) **רק אם**
  /// הוזן סכום בפועל - שמירה בלי סכום (למשל רק כדי לשמור תזכורת)
  /// לא אמורה לסמן וי ירוק.
  Future<void> saveBillDetails({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
    double? amount,
    String? paymentMethod,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    final data = <String, dynamic>{
      'category': billCategoryToString(category),
      'year': year,
      'periodStartMonth': periodStartMonth,
      if (amount != null) 'amount': amount,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };
    if (amount != null) {
      data['paidManually'] = true;
      data['paidAt'] = FieldValue.serverTimestamp();
    }
    await _billsCollection(householdId).doc(id).set(data, SetOptions(merge: true));
  }

  /// מבטל תשלום שכבר סומן - מחזיר את התקופה למצב "לא שולם" (ה-חוג
  /// הירוק נעלם), מנקה את הסכום ואמצעי התשלום, **וגם מבטל תזכורת**
  /// אם הייתה מוגדרת - איפוס מלא ושלם של התקופה.
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
      'reminderAt': null,
      'reminderShown': false,
    });
  }

  /// שומר תזכורת לתאריך+שעה עתידיים לתקופה מסוימת.
  Future<void> saveReminder({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
    required DateTime reminderAt,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    await _billsCollection(householdId).doc(id).set({
      'category': billCategoryToString(category),
      'year': year,
      'periodStartMonth': periodStartMonth,
      'reminderAt': Timestamp.fromDate(reminderAt),
      'reminderShown': false,
    }, SetOptions(merge: true));
  }

  Future<void> clearReminder({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    await _billsCollection(householdId).doc(id).update({
      'reminderAt': null,
      'reminderShown': false,
    });
  }

  Future<void> markReminderShown({
    required String householdId,
    required String billDocId,
  }) async {
    await _billsCollection(householdId).doc(billDocId).update({'reminderShown': true});
  }

  /// כמו watchAllReminders, אבל **בלי** לסנן reminderShown - משמש
  /// לתצוגה בלוח השנה (רוצים להראות תזכורות גם אחרי שכבר "צלצלו").
  Stream<List<BillPayment>> watchAllScheduledReminders(String householdId) {
    return _billsCollection(householdId)
        .where('reminderAt', isNull: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BillPayment.fromFirestore(doc.id, doc.data())).toList());
  }

  /// מאזין לכל התזכורות שהוגדרו ב-household (בכל הקטגוריות יחד) -
  /// משמש כדי לבדוק ברקע אילו תזכורות "הגיע זמנן". הסינון של
  /// reminderShown נעשה בצד הלקוח (לא בשאילתה) כדי להימנע מהצורך
  /// ב-composite index ב-Firestore.
  Stream<List<BillPayment>> watchAllReminders(String householdId) {
    return _billsCollection(householdId)
        .where('reminderAt', isNull: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BillPayment.fromFirestore(doc.id, doc.data()))
            .where((bill) => !bill.reminderShown)
            .toList());
  }

  String billDocId(BillCategory category, int year, int periodStartMonth) =>
      _docId(category, year, periodStartMonth);
}

HMEOF
echo 'DONE - canceling a payment now also clears any reminder!'
