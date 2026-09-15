import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/shopping_provider.dart';
import 'shopping_list_screen.dart';

/// מסך "קנייה חדשה" - לוח שנה אמיתי של החודש הנוכחי, בחירת תאריך
/// ואישור יוצרים רשימת קניות חדשה לתאריך שנבחר.
class NewShoppingCalendarScreen extends ConsumerStatefulWidget {
  final String householdId;

  const NewShoppingCalendarScreen({super.key, required this.householdId});

  @override
  ConsumerState<NewShoppingCalendarScreen> createState() =>
      _NewShoppingCalendarScreenState();
}

class _NewShoppingCalendarScreenState extends ConsumerState<NewShoppingCalendarScreen> {
  late final DateTime _month;
  DateTime? _selectedDate;
  bool _isLoading = false;

  static const List<String> _weekdayLabels = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  Future<void> _confirm() async {
    final date = _selectedDate;
    if (date == null) return;

    setState(() => _isLoading = true);

    try {
      final newList = await ref.read(shoppingRepositoryProvider).createList(
            householdId: widget.householdId,
            name: DateFormatter.dateOnly(date),
            date: date,
          );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ShoppingListScreen(
              householdId: widget.householdId,
              listId: newList.id,
            ),
          ),
        );
      }
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // יישור כך שראשון (Sunday) יהיה העמודה הראשונה: DateTime.weekday
    // מחזיר שני=1...ראשון=7, אז %7 הופך את ראשון ל-0.
    final leadingEmptyCells = _month.weekday % 7;
    final monthLabel = '${_month.month}/${_month.year}';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.newShoppingOption)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                AppStrings.selectDateForNewList,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(monthLabel, style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Row(
                children: _weekdayLabels
                    .map((label) => Expanded(
                          child: Center(
                            child: Text(
                              label,
                              style: AppTextStyles.bodySecondary.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: leadingEmptyCells + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < leadingEmptyCells) {
                      return const SizedBox.shrink();
                    }
                    final day = index - leadingEmptyCells + 1;
                    final date = DateTime(_month.year, _month.month, day);
                    final isSelected =
                        _selectedDate != null && _isSameDay(_selectedDate!, date);
                    final isToday = _isSameDay(date, DateTime.now());

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday && !isSelected
                              ? Border.all(color: AppColors.primary, width: 1.4)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: AppTextStyles.body.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedDate == null || _isLoading ? null : _confirm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(AppStrings.confirmDateButton, style: AppTextStyles.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

