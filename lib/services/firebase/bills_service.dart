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
  /// שומר סכום+אמצעי תשלום+תזכורת. `markPaid` קובע במפורש את
  /// סטטוס "שולם" - **לא** אוטומטי לפי נוכחות סכום; זה נשלט רק
  /// ע"י כפתור "שולם" הייעודי בחלונית העריכה.
  Future<void> saveBillDetails({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
    double? amount,
    String? paymentMethod,
    required bool markPaid,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    final data = <String, dynamic>{
      'category': billCategoryToString(category),
      'year': year,
      'periodStartMonth': periodStartMonth,
      if (amount != null) 'amount': amount,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'paidManually': markPaid,
    };
    if (markPaid) {
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
  /// מוחק את **כל** רשומות התשלום של מים/ארנונה (כל הצורות - ביחד
  /// ובנפרד, כל השנים) - קורה כשמאפסים את בחירת "ביחד/בנפרד",
  /// כי מעבר בין המבנים "מאבד" גישה לרשומות הישנות (הן נשמרות תחת
  /// שם קטגוריה שונה ב-Firestore) - עדיף למחוק בפועל מאשר להשאיר
  /// נתונים יתומים שאף מסך לא יראה יותר.
  Future<void> clearWaterTaxPayments(String householdId) async {
    const categories = ['waterAndTax', 'water', 'tax'];
    final batch = _firestore.batch();
    for (final cat in categories) {
      final snapshot =
          await _billsCollection(householdId).where('category', isEqualTo: cat).get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

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

