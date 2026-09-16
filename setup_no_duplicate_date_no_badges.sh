#!/bin/bash
set -e
mkdir -p lib/features/shopping lib/features/home/tabs
cat > 'lib/features/shopping/existing_shopping_lists_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../providers/shopping_provider.dart';
import 'shopping_list_screen.dart';

/// מסך "קנייה נוכחית" - רשימת כל הקניות הקיימות של ה-household,
/// לבחירה. יצירת קנייה חדשה נעשית דרך המסך השני (NewShoppingCalendarScreen),
/// לא כאן.
class ExistingShoppingListsScreen extends ConsumerWidget {
  final String householdId;

  const ExistingShoppingListsScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(shoppingListsProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.currentShoppingOption)),
      body: listsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => const ErrorView(),
        data: (lists) {
          // מציגים רק רשימות שיש בהן בפועל לפחות מוצר אחד - רשימות
          // ריקות (למשל שאריות ישנות מבדיקות) לא מבלבלות את הבחירה.
          final nonEmptyLists = lists.where((list) {
            final itemsAsync = ref.watch(
              shoppingItemsProvider((householdId: householdId, listId: list.id)),
            );
            return (itemsAsync.value ?? const []).isNotEmpty;
          }).toList();

          if (nonEmptyLists.isEmpty) {
            return const EmptyState(
              message: AppStrings.noListsYet,
              icon: Icons.shopping_cart_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: nonEmptyLists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final list = nonEmptyLists[index];
              final isActive = list.activeSessionId != null;

              return ListTile(
                leading: Icon(
                  Icons.shopping_cart,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(list.name),
                subtitle: (list.date != null &&
                        list.name != DateFormatter.dateOnly(list.date))
                    ? Text(DateFormatter.dateOnly(list.date), style: AppTextStyles.bodySecondary)
                    : null,
                trailing: isActive
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          AppStrings.activeSessionBadge,
                          style: TextStyle(color: AppColors.primary, fontSize: 11),
                        ),
                      )
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShoppingListScreen(householdId: householdId, listId: list.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

HMEOF
cat > 'lib/features/home/tabs/home_tab_content.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../app/config/app_strings.dart';
import '../../bills/electricity_screen.dart';
import '../../bills/vaad_bayit_screen.dart';
import '../../bills/water_and_tax_screen.dart';
import '../home_module.dart';

/// תוכן טאב "בית" - רשת 4 חלונות: קניות, לוח שנה, משימות, רכבים.
/// קניות ולוח שנה זמינים גם כטאבים משלהם בסרגל התחתון - זה כאן
/// בעצם קיצור דרך נוסף שנשאר מהעיצוב המקורי.
class HomeTabContent extends ConsumerWidget {
  final String householdId;
  final List<HomeModule> tiles;
  final ValueChanged<int> onSelectTab;

  const HomeTabContent({
    super.key,
    required this.householdId,
    required this.tiles,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _Tile(
              module: tiles[0],
              color: AppColors.itemPurchased,
              onTap: () => onSelectTab(1),
            ),
            _Tile(
              module: tiles[1],
              color: AppColors.primary,
              onTap: () => onSelectTab(2),
            ),
            _Tile(
              module: tiles[2],
              color: AppColors.itemNewBadge,
              onTap: () => onSelectTab(3),
            ),
            _Tile(module: tiles[3], color: AppColors.itemNotFound, onTap: null),
          ],
        ),
        const SizedBox(height: 16),
        _BillsSection(householdId: householdId),
      ],
    );
  }
}

/// כרטיס רחב עם 3 עמודות: ועד בית (פעיל), חשמל ומים+ארנונה
/// (בקרוב - עדיין אין להם מסכים אמיתיים).
class _BillsSection extends StatelessWidget {
  final String householdId;

  const _BillsSection({required this.householdId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.billsSectionTitle, style: AppTextStyles.heading2.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BillColumn(
                  icon: Icons.apartment_outlined,
                  label: AppStrings.vaadBayitTitle,
                  available: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VaadBayitScreen(householdId: householdId),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _BillColumn(
                  icon: Icons.bolt_outlined,
                  label: AppStrings.electricityTitle,
                  available: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ElectricityScreen(householdId: householdId),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _BillColumn(
                  icon: Icons.water_drop_outlined,
                  label: AppStrings.waterAndTaxTitle,
                  available: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WaterAndTaxScreen(householdId: householdId),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool available;
  final VoidCallback? onTap;

  const _BillColumn({
    required this.icon,
    required this.label,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Opacity(
        opacity: available ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.body.copyWith(fontSize: 12), textAlign: TextAlign.center),
              if (!available)
                Text(AppStrings.comingSoon,
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final HomeModule module;
  final Color color;
  final int? badgeCount;
  final VoidCallback? onTap;

  const _Tile({required this.module, required this.color, this.badgeCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool available = onTap != null;

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: available ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(module.icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title, style: AppTextStyles.heading2.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      if (badgeCount != null)
                        Text('$badgeCount', style: AppTextStyles.heading1.copyWith(fontSize: 20))
                      else if (!available)
                        Text(AppStrings.comingSoon,
                            style: AppTextStyles.bodySecondary.copyWith(fontSize: 11))
                      else
                        Text(module.subtitle,
                            style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

HMEOF
echo 'DONE - removed duplicate date and number badges from home tiles!'
