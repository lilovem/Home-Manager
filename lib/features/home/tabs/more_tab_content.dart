import 'package:flutter/material.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/config/app_text_styles.dart';
import '../home_module.dart';

/// תוכן טאב "עוד" - רשת שאר המודולים העתידיים (רכבים, ביטוחים,
/// רישיונות, חוגים, חשבונות, מסמכים) - כולם "בקרוב".
class MoreTabContent extends StatelessWidget {
  final List<HomeModule> modules;

  const MoreTabContent({super.key, required this.modules});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) => _ModuleTile(module: modules[index]),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final HomeModule module;

  const _ModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Opacity(
        opacity: 0.5,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Icon(module.icon, color: AppColors.textSecondary, size: 24),
                ),
                const SizedBox(height: 12),
                Text(module.title, style: AppTextStyles.heading2.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  module.subtitle,
                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  AppStrings.comingSoon,
                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

