import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/bill_payment_model.dart';
import '../../../models/shopping_list_model.dart';
import '../../../providers/bills_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../shopping/shopping_list_screen.dart';

/// תוכן טאב "לוח שנה" - לוח חודשי אמיתי עם גלילה בין חודשים,
/// לחיצה על יום מציגה מה מתוכנן בו, ולמטה "אירועים קרובים" ל-3
/// ימים קדימה. מבוסס על שני מקורות אמיתיים: תאריכי רשימות קניות,
/// **וגם** תזכורות תשלום שהוגדרו (ר' bill_reminder_listener.dart
/// להתראה בפועל - זה כאן רק התצוגה החזותית בלוח).
class CalendarTabContent extends ConsumerStatefulWidget {
  final String householdId;

  const CalendarTabContent({super.key, required this.householdId});

  @override
  ConsumerState<CalendarTabContent> createState() => _CalendarTabContentState();
}

class _CalendarTabContentState extends ConsumerState<CalendarTabContent> {
  late DateTime _month;
  DateTime? _selectedDay;

  static const _weekdayLabels = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _selectedDay = null;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(shoppingListsProvider(widget.householdId)).value ?? [];
    final reminders =
        ref.watch(allScheduledRemindersProvider(widget.householdId)).value ?? [];

    final datedListsWithItems = <ShoppingList>[];
    for (final list in lists) {
      if (list.date == null) continue;
      final items = ref
              .watch(shoppingItemsProvider((householdId: widget.householdId, listId: list.id)))
              .value ??
          const [];
      if (items.isNotEmpty) datedListsWithItems.add(list);
    }

    final billReminders = reminders.where((b) => b.reminderAt != null).toList();

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingEmptyCells = _month.weekday % 7;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final markedDaysFromLists = datedListsWithItems
        .where((l) => l.date!.year == _month.year && l.date!.month == _month.month)
        .map((l) => l.date!.day);
    final markedDaysFromReminders = billReminders
        .where((b) => b.reminderAt!.year == _month.year && b.reminderAt!.month == _month.month)
        .map((b) => b.reminderAt!.day);
    final markedDays = {...markedDaysFromLists, ...markedDaysFromReminders};

    final selectedDayLists = _selectedDay == null
        ? <ShoppingList>[]
        : datedListsWithItems.where((l) => _isSameDay(l.date!, _selectedDay!)).toList();
    final selectedDayReminders = _selectedDay == null
        ? <BillPayment>[]
        : billReminders.where((b) => _isSameDay(b.reminderAt!, _selectedDay!)).toList();

    final upcomingLists = datedListsWithItems
        .where((l) =>
            !l.date!.isBefore(todayStart) &&
            l.date!.isBefore(todayStart.add(const Duration(days: 3))))
        .toList();
    final upcomingReminders = billReminders
        .where((b) =>
            !b.reminderAt!.isBefore(todayStart) &&
            b.reminderAt!.isBefore(todayStart.add(const Duration(days: 3))))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1),
            ),
            Text('${_month.month}/${_month.year}', style: AppTextStyles.heading2),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        Row(
          children: _weekdayLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(l, style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: leadingEmptyCells + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingEmptyCells) return const SizedBox.shrink();
            final day = index - leadingEmptyCells + 1;
            final date = DateTime(_month.year, _month.month, day);
            final isMarked = markedDays.contains(day);
            final isToday = _isSameDay(date, now);
            final isSelected = _selectedDay != null && _isSameDay(_selectedDay!, date);

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedDay = date),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDark
                      : isMarked
                          ? AppColors.primary
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected && !isMarked
                      ? Border.all(color: AppColors.primary, width: 1.4)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected || isMarked ? Colors.white : AppColors.textPrimary,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
        if (_selectedDay != null) ...[
          const Divider(height: 28),
          Text(
            '${AppStrings.selectedDayDetailsTitle} · ${DateFormatter.dateOnly(_selectedDay)}',
            style: AppTextStyles.heading2.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (selectedDayLists.isEmpty && selectedDayReminders.isEmpty)
            Text(AppStrings.noEventOnThisDay, style: AppTextStyles.bodySecondary)
          else ...[
            ...selectedDayLists.map(
              (l) => Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_cart, color: Colors.blue, size: 26),
                  title: const Text(AppStrings.shoppingEventLabel),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ShoppingListScreen(householdId: widget.householdId, listId: l.id),
                    ),
                  ),
                ),
              ),
            ),
            ...selectedDayReminders.map(
              (b) => Card(
                child: ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.green, size: 26),
                  title: Text(billCategoryDisplayName(b.category)),
                  subtitle: Text(DateFormatter.short(b.reminderAt)),
                ),
              ),
            ),
          ],
        ],
        const Divider(height: 28),
        Text(AppStrings.upcomingEventsTitle, style: AppTextStyles.heading2.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        if (upcomingLists.isEmpty && upcomingReminders.isEmpty)
          Text(AppStrings.noUpcomingEvents, style: AppTextStyles.bodySecondary)
        else ...[
          ...upcomingLists.map(
            (l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 22, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(AppStrings.shoppingEventLabel, style: AppTextStyles.body)),
                  Text(DateFormatter.dateOnly(l.date), style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
          ),
          ...upcomingReminders.map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.alarm, size: 22, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(billCategoryDisplayName(b.category), style: AppTextStyles.body),
                  ),
                  Text(DateFormatter.short(b.reminderAt), style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

