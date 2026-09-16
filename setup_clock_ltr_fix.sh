#!/bin/bash
set -e
cat > 'lib/features/bills/modern_time_picker.dart' << 'HMEOF'
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';

/// בורר שעה מודרני - שתי אפשרויות בכפתור אחד להחלפה:
/// 1. "גלגל" (Cupertino) - מחליקים למעלה/למטה על שעות/דקות
/// 2. הקלדה ידנית - שתי תיבות מספרים
/// תמיד בפורמט 24 שעות (לא AM/PM) - זה גם מה שפותר את הבאג שבו
/// showTimePicker הרגיל של Flutter דחה שעות אחרי 12 בטעות.
Future<TimeOfDay?> showModernTimePicker(BuildContext context, TimeOfDay initialTime) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _ModernTimePickerDialog(initialTime: initialTime),
  );
}

class _ModernTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _ModernTimePickerDialog({required this.initialTime});

  @override
  State<_ModernTimePickerDialog> createState() => _ModernTimePickerDialogState();
}

class _ModernTimePickerDialogState extends State<_ModernTimePickerDialog> {
  bool _manualMode = false;
  late DateTime _wheelValue;
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _wheelValue =
        DateTime(now.year, now.month, now.day, widget.initialTime.hour, widget.initialTime.minute);
    _hourController = TextEditingController(text: widget.initialTime.hour.toString().padLeft(2, '0'));
    _minuteController =
        TextEditingController(text: widget.initialTime.minute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _confirm() {
    TimeOfDay result;
    if (_manualMode) {
      final h = int.tryParse(_hourController.text.trim()) ?? 0;
      final m = int.tryParse(_minuteController.text.trim()) ?? 0;
      result = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    } else {
      result = TimeOfDay(hour: _wheelValue.hour, minute: _wheelValue.minute);
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppStrings.pickReminderTimeTitle, style: AppTextStyles.heading2.copyWith(fontSize: 16)),
          IconButton(
            icon: Icon(_manualMode ? Icons.swipe_vertical_outlined : Icons.keyboard_outlined),
            tooltip: _manualMode ? AppStrings.timeModeWheel : AppStrings.timeModeManual,
            onPressed: () => setState(() => _manualMode = !_manualMode),
          ),
        ],
      ),
      content: SizedBox(
        height: 180,
        width: 260,
        child: _manualMode
            ? Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _hourController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading1.copyWith(fontSize: 28),
                        decoration: const InputDecoration(labelText: 'שעה'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(':', style: TextStyle(fontSize: 28)),
                    ),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _minuteController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading1.copyWith(fontSize: 28),
                        decoration: const InputDecoration(labelText: 'דקה'),
                      ),
                    ),
                  ],
                ),
              )
            : CupertinoTheme(
                data: const CupertinoThemeData(primaryColor: AppColors.primary),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: _wheelValue,
                  onDateTimeChanged: (dt) => _wheelValue = dt,
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: _confirm,
          child: const Text(AppStrings.saveButton),
        ),
      ],
    );
  }
}

HMEOF
echo 'DONE - clock now reads left-to-right like a normal digital clock!'
