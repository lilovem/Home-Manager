import 'package:flutter/material.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/config/app_text_styles.dart';
import '../../shopping/existing_shopping_lists_screen.dart';
import '../../shopping/new_shopping_calendar_screen.dart';

/// תוכן טאב "קניות" - זהה למה שהיה ב-ShoppingChoiceScreen, רק
/// מוטמע ישירות כתוכן טאב (בלי Scaffold/AppBar משלו, כי הכותרת
/// הקבועה של ה-shell כבר מספקת את זה).
class ShoppingTabContent extends StatelessWidget {
  final String householdId;

  const ShoppingTabContent({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ChoiceCard(
            icon: Icons.shopping_cart,
            title: AppStrings.currentShoppingOption,
            subtitle: AppStrings.currentShoppingSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExistingShoppingListsScreen(householdId: householdId),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ChoiceCard(
            icon: Icons.calendar_month,
            title: AppStrings.newShoppingOption,
            subtitle: AppStrings.newShoppingSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NewShoppingCalendarScreen(householdId: householdId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading2),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

