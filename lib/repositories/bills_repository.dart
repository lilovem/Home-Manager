import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failures.dart';
import '../models/bill_link_settings_model.dart';
import '../models/bill_payment_model.dart';
import '../services/firebase/bill_settings_service.dart';
import '../services/firebase/bills_service.dart';

class BillsRepository {
  final BillsService _billsService;
  final BillSettingsService _settingsService;

  BillsRepository(this._billsService, this._settingsService);

  Stream<BillLinkSettings> watchSettings(String householdId) {
    return _settingsService.watchSettings(householdId);
  }

  Future<void> saveBitUrl(String householdId, String url) async {
    try {
      await _settingsService.saveBitUrl(householdId, url);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בשמירת הקישור');
    }
  }

  Future<void> savePayboxUrl(String householdId, String url) async {
    try {
      await _settingsService.savePayboxUrl(householdId, url);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בשמירת הקישור');
    }
  }

  Future<void> saveElectricityUrl(String householdId, String url) async {
    try {
      await _settingsService.saveElectricityUrl(householdId, url);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בשמירת הקישור');
    }
  }

  Future<void> saveCombinedWaterTaxUrl(String householdId, String url) async {
    try {
      await _settingsService.saveCombinedWaterTaxUrl(householdId, url);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בשמירת הקישור');
    }
  }

  Future<void> saveSeparateWaterTaxUrls(
      String householdId, String waterUrl, String taxUrl) async {
    try {
      await _settingsService.saveSeparateWaterTaxUrls(householdId, waterUrl, taxUrl);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בשמירת הקישורים');
    }
  }

  Future<void> resetWaterTaxChoice(String householdId) async {
    try {
      await _settingsService.resetWaterTaxChoice(householdId);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה באיפוס ההגדרה');
    }
  }

  Future<void> clearWaterTaxPayments(String householdId) async {
    try {
      await _billsService.clearWaterTaxPayments(householdId);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה במחיקת התשלומים');
    }
  }

  Stream<List<BillPayment>> watchBills({
    required String householdId,
    required BillCategory category,
    required int year,
  }) {
    return _billsService.watchBills(householdId: householdId, category: category, year: year);
  }

  Future<void> saveBillDetails({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
    double? amount,
    String? paymentMethod,
    required bool markPaid,
  }) async {
    try {
      await _billsService.saveBillDetails(
        householdId: householdId,
        category: category,
        year: year,
        periodStartMonth: periodStartMonth,
        amount: amount,
        paymentMethod: paymentMethod,
        markPaid: markPaid,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בשמירת הפרטים');
    }
  }

  Future<void> saveReminder({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
    required DateTime reminderAt,
  }) async {
    try {
      await _billsService.saveReminder(
        householdId: householdId,
        category: category,
        year: year,
        periodStartMonth: periodStartMonth,
        reminderAt: reminderAt,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בשמירת התזכורת');
    }
  }

  Future<void> clearReminder({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
  }) async {
    try {
      await _billsService.clearReminder(
        householdId: householdId,
        category: category,
        year: year,
        periodStartMonth: periodStartMonth,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בביטול התזכורת');
    }
  }

  Future<void> markReminderShown({required String householdId, required String billDocId}) {
    return _billsService.markReminderShown(householdId: householdId, billDocId: billDocId);
  }

  Stream<List<BillPayment>> watchAllReminders(String householdId) {
    return _billsService.watchAllReminders(householdId);
  }

  Stream<List<BillPayment>> watchAllScheduledReminders(String householdId) {
    return _billsService.watchAllScheduledReminders(householdId);
  }

  Future<void> cancelPayment({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
  }) async {
    try {
      await _billsService.cancelPayment(
        householdId: householdId,
        category: category,
        year: year,
        periodStartMonth: periodStartMonth,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בביטול התשלום');
    }
  }
}

