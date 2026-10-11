import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/shopping_provider.dart';
import 'shopping_list_screen.dart';

/// מסך "קנייה חדשה" - בחירת תאריך בעזרת בורר גלגלים קטן וקומפקטי
/// (יום | חודש | שנה): מחליקים למעלה ולמטה על כל גלגל כדי לבחור,
/// במקום לוח שנה חודשי שלם שתופס את כל המסך. התאריך של היום נבחר
/// כברירת מחדל, ואישור יוצר רשימת קניות חדשה לתאריך שנבחר.
class NewShoppingCalendarScreen extends ConsumerStatefulWidget {
  final String householdId;

  const NewShoppingCalendarScreen({super.key, required this.householdId});

  @override
  ConsumerState<NewShoppingCalendarScreen> createState() =>
      _NewShoppingCalendarScreenState();
}

class _NewShoppingCalendarScreenState extends ConsumerState<NewShoppingCalendarScreen> {
  static const List<String> _monthNames = [
    'ינואר',
    'פברואר',
    'מרץ',
    'אפריל',
    'מאי',
    'יוני',
    'יולי',
    'אוגוסט',
    'ספטמבר',
    'אוקטובר',
    'נובמבר',
    'דצמבר',
  ];

  // DateTime.weekday: שני=1 ... ראשון=7.
  static const Map<int, String> _weekdayNames = {
    1: 'יום שני',
    2: 'יום שלישי',
    3: 'יום רביעי',
    4: 'יום חמישי',
    5: 'יום שישי',
    6: 'שבת',
    7: 'יום ראשון',
  };

  late final int _firstYear;
  late final int _yearCount;
  late int _day;
  late int _month;
  late int _year;

  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _firstYear = now.year - 1;
    _yearCount = 8;
    _day = now.day;
    _month = now.month;
    _year = now.year;
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(initialItem: _year - _firstYear);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _daysIn(int year, int month) => DateTime(year, month + 1, 0).day;

  DateTime get _selectedDate => DateTime(_year, _month, _day);

  /// אחרי שינוי חודש/שנה - אם היום שנבחר לא קיים בחודש החדש (למשל
  /// 31 בפברואר), מצמצמים אותו ליום האחרון של החודש ומזיזים את גלגל
  /// הימים בהתאם.
  void _clampDay() {
    final maxDay = _daysIn(_year, _month);
    if (_day > maxDay) {
      _day = maxDay;
      _dayController.jumpToItem(_day - 1);
    }
  }

  Future<void> _confirm() async {
    final date = _selectedDate;

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

  @override
  Widget build(BuildContext context) {
    final date = _selectedDate;
    final summary = '${_weekdayNames[date.weekday]}, ${date.day} ב${_monthNames[date.month - 1]} ${date.year}';
    final daysInMonth = _daysIn(_year, _month);

    return Scaffold(
      backgroundColor: AppColors.surface,
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 150,
                  child: ScrollConfiguration(
                    // מאפשר גרירה גם בעכבר/טראקפד (באתר במחשב), לא רק במגע.
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // פס הדגשה מאחורי השורה שנבחרה (במרכז).
                        IgnorePointer(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _Wheel(
                                controller: _dayController,
                                labels: List.generate(daysInMonth, (i) => '${i + 1}'),
                                onSelected: (i) => setState(() => _day = i + 1),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: _Wheel(
                                controller: _monthController,
                                labels: _monthNames,
                                onSelected: (i) => setState(() {
                                  _month = i + 1;
                                  _clampDay();
                                }),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: _Wheel(
                                controller: _yearController,
                                labels: List.generate(_yearCount, (i) => '${_firstYear + i}'),
                                onSelected: (i) => setState(() {
                                  _year = _firstYear + i;
                                  _clampDay();
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                summary,
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(AppStrings.confirmDateButton, style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// גלגל גלילה אנכי בודד (יום / חודש / שנה).
class _Wheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  const _Wheel({
    super.key,
    required this.controller,
    required this.labels,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      diameterRatio: 1.6,
      perspective: 0.003,
      overAndUnderCenterOpacity: 0.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildListDelegate(
        children: labels
            .map(
              (label) => Center(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
