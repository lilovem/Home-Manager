import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/shopping_list_model.dart';
import '../../../providers/shopping_provider.dart';
import '../../shopping/shopping_list_screen.dart';

/// תוכן טאב "לוח שנה" - לוח חודשי אמיתי עם גלילה בין חודשים,
/// לחיצה על יום מציגה מה מתוכנן בו, ולמטה "אירועים קרובים" ל-3
/// ימים קדימה. מבוסס על תאריכי רשימות קניות (הנתון האמיתי היחיד
/// שקיים כרגע) - רק רשימות שיש בהן בפועל מוצרים נספרות/מסומנות.
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

    final datedListsWithItems = <ShoppingList>[];
    for (final list in lists) {
      if (list.date == null) continue;
      final items = ref
              .watch(shoppingItemsProvider((householdId: widget.householdId, listId: list.id)))
              .value ??
          const [];
      if (items.isNotEmpty) datedListsWithItems.add(list);
    }

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingEmptyCells = _month.weekday % 7;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final markedDays = datedListsWithItems
        .where((l) => l.date!.year == _month.year && l.date!.month == _month.month)
        .map((l) => l.date!.day)
        .toSet();

    final selectedDayLists = _selectedDay == null
        ? <ShoppingList>[]
        : datedListsWithItems.where((l) => _isSameDay(l.date!, _selectedDay!)).toList();

    final upcoming = datedListsWithItems
        .where((l) =>
            !l.date!.isBefore(todayStart) &&
            l.date!.isBefore(todayStart.add(const Duration(days: 3))))
        .toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(-1),
            ),
            Text('${_month.month}/${_month.year}', style: AppTextStyles.heading2),
            IconButton(
              icon: const Icon(Icons.chevron_left),
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
          if (selectedDayLists.isEmpty)
            Text(AppStrings.noEventOnThisDay, style: AppTextStyles.bodySecondary)
          else
            ...selectedDayLists.map(
              (l) => Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_cart, color: AppColors.primary),
                  title: Text(l.name),
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
        ],
        const Divider(height: 28),
        Text(AppStrings.upcomingEventsTitle, style: AppTextStyles.heading2.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          Text(AppStrings.noUpcomingEvents, style: AppTextStyles.bodySecondary)
        else
          ...upcoming.map(
            (l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.name, style: AppTextStyles.body)),
                  Text(DateFormatter.dateOnly(l.date), style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

