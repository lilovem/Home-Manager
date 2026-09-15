import 'package:flutter/material.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/config/app_text_styles.dart';

/// תוכן טאב "משימות" - עדיין אין נתונים אמיתיים, "בקרוב" בלבד.
class TasksTabContent extends StatelessWidget {
  const TasksTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checklist_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(AppStrings.tabTasks, style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              AppStrings.tasksComingSoonBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}

