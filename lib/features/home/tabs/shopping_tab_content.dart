import 'package:flutter/material.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/config/app_text_styles.dart';
import '../../shopping/existing_shopping_lists_screen.dart';
import '../../shopping/new_shopping_calendar_screen.dart';

/// תוכן טאב "קניות" - זהה למה שהיה ב-ShoppingChoiceScreen, רק
/// מוטמע ישירות כתוכן טאב (בלי Scaffold/AppBar משלו, כי הכותרת
/// הקבועה של ה-shell כבר מספקת את זה).
/// "קנייה חדשה" למעלה ו"קנייה נוכחית" אחריה; הכרטיסים קטנים יותר.
class ShoppingTabContent extends StatelessWidget {
  final String householdId;

  const ShoppingTabContent({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
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
          const SizedBox(height: 10),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading2.copyWith(fontSize: 15)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
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
