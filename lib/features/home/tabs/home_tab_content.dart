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

  /// פותח את מסך המודול (אם יש לו screenBuilder זמין) - זה מה שקודם
  /// היה מקובע כ-null עבור אריח הרכבים, בלי קשר לזמינות האמיתית
  /// שמוגדרת ב-home_modules.dart.
  void _openModule(BuildContext context, HomeModule module) {
    if (module.screenBuilder == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: module.screenBuilder!),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.9,
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
            _Tile(
              module: tiles[3],
              color: AppColors.itemNotFound,
              onTap: tiles[3].screenBuilder != null
                  ? () => _openModule(context, tiles[3])
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.billsSectionTitle, style: AppTextStyles.heading2.copyWith(fontSize: 13)),
          const SizedBox(height: 8),
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 4),
              Text(label, style: AppTextStyles.body.copyWith(fontSize: 11), textAlign: TextAlign.center),
              if (!available)
                Text(AppStrings.comingSoon,
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 9)),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(module.icon, color: color, size: 19),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title, style: AppTextStyles.heading2.copyWith(fontSize: 13)),
                      const SizedBox(height: 1),
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
