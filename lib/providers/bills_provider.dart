import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bill_link_settings_model.dart';
import '../models/bill_payment_model.dart';
import '../repositories/bills_repository.dart';
import '../services/firebase/bill_settings_service.dart';
import '../services/firebase/bills_service.dart';
import 'household_provider.dart';

final billsServiceProvider = Provider<BillsService>((ref) {
  return BillsService(ref.watch(firestoreProvider));
});

final billSettingsServiceProvider = Provider<BillSettingsService>((ref) {
  return BillSettingsService(ref.watch(firestoreProvider));
});

final billsRepositoryProvider = Provider<BillsRepository>((ref) {
  return BillsRepository(
    ref.watch(billsServiceProvider),
    ref.watch(billSettingsServiceProvider),
  );
});

/// כל התזכורות שעדיין לא הוצגו, בכל הקטגוריות של household.
final allBillRemindersProvider =
    StreamProvider.family<List<BillPayment>, String>((ref, householdId) {
  return ref.watch(billsRepositoryProvider).watchAllReminders(householdId);
});

/// כל התזכורות המתוזמנות (גם אם כבר הוצגו) - לתצוגה בלוח השנה.
final allScheduledRemindersProvider =
    StreamProvider.family<List<BillPayment>, String>((ref, householdId) {
  return ref.watch(billsRepositoryProvider).watchAllScheduledReminders(householdId);
});

/// כל רשומות התשלום של קטגוריה מסוימת, לשנה מסוימת.
final billsForYearProvider = StreamProvider.family<
    List<BillPayment>, ({String householdId, BillCategory category, int year})>((ref, args) {
  return ref.watch(billsRepositoryProvider).watchBills(
        householdId: args.householdId,
        category: args.category,
        year: args.year,
      );
});

/// הגדרות קישורי התשלום (חשמל/מים/ארנונה) של household.
final billLinkSettingsProvider =
    StreamProvider.family<BillLinkSettings, String>((ref, householdId) {
  return ref.watch(billsRepositoryProvider).watchSettings(householdId);
});

