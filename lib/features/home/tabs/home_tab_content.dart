import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../app/config/app_strings.dart';
import '../../../providers/shopping_provider.dart';
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
    final pendingCount = ref.watch(totalPendingItemsCountProvider(householdId));
    final upcoming = ref.watch(upcomingShoppingDatesProvider(householdId));

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _Tile(
          module: tiles[0],
          color: AppColors.itemPurchased,
          badgeCount: pendingCount > 0 ? pendingCount : null,
          onTap: () => onSelectTab(1),
        ),
        _Tile(
          module: tiles[1],
          color: AppColors.primary,
          badgeCount: upcoming.isNotEmpty ? upcoming.length : null,
          onTap: () => onSelectTab(2),
        ),
        _Tile(
          module: tiles[2],
          color: AppColors.itemNewBadge,
          onTap: () => onSelectTab(3),
        ),
        _Tile(module: tiles[3], color: AppColors.itemNotFound, onTap: null),
      ],
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

