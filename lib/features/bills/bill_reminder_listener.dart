import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../providers/bills_provider.dart';
import '../../providers/notification_provider.dart';

/// עוטף את האפליקציה (בדומה ל-ShoppingNotificationsListener) כדי
/// לבדוק ברקע, כל דקה, אם הגיע זמנה של תזכורת תשלום שהוגדרה.
///
/// מגבלה מודעת: זה עובד רק כל עוד האפליקציה פתוחה (אותה מגבלה
/// כמו התראות הקניות) - אין שרת שמריץ את זה כשהאפליקציה סגורה.
class BillReminderListener extends ConsumerStatefulWidget {
  final String householdId;
  final Widget child;

  const BillReminderListener({super.key, required this.householdId, required this.child});

  @override
  ConsumerState<BillReminderListener> createState() => _BillReminderListenerState();
}

class _BillReminderListenerState extends ConsumerState<BillReminderListener> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _checkReminders());
    // בדיקה גם מיד עם הפתיחה, לא רק אחרי דקה ראשונה.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminders());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkReminders() {
    final reminders = ref.read(allBillRemindersProvider(widget.householdId)).value ?? [];
    final now = DateTime.now();

    for (final bill in reminders) {
      if (bill.reminderAt != null && !bill.reminderAt!.isAfter(now)) {
        ref.read(browserNotificationServiceProvider).show(
              title: AppStrings.billReminderTitle,
              body: AppStrings.billReminderBody,
            );
        ref.read(billsRepositoryProvider).markReminderShown(
              householdId: widget.householdId,
              billDocId: bill.id,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // שומרים על ה-provider "חי" (מאזין) כל הזמן, לא רק כש-Timer קורא לו.
    ref.watch(allBillRemindersProvider(widget.householdId));
    return widget.child;
  }
}

