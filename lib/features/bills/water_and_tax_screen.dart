import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../models/bill_payment_model.dart';
import '../../providers/bills_provider.dart';
import 'bill_period_table_screen.dart';

/// מסך מים+ארנונה - בפעם הראשונה שואל רק שאלה מבנית אחת (ביחד
/// או בנפרד - קובעת אם יש טבלה אחת משותפת או שתיים נפרדות).
/// אחרי זה, תמיד הולך ישר לטבלה/ות - בחירת אמצעי תשלום (סריקת
/// ברקוד/קישור לאתר) נעשית בכל פעם מחדש בתוך חלונית כל תקופה.
class WaterAndTaxScreen extends ConsumerWidget {
  final String householdId;

  const WaterAndTaxScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(billLinkSettingsProvider(householdId));

    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => const Scaffold(body: Center(child: Text('שגיאה בטעינה'))),
      data: (settings) {
        if (!settings.isWaterTaxConfigured) {
          return _CombinedOrSeparateChoiceScreen(householdId: householdId);
        }

        if (settings.waterAndTaxCombined == true) {
          return BillPeriodTableScreen(
            householdId: householdId,
            category: BillCategory.waterAndTax,
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.waterAndTaxTitle)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _CategoryLink(
                icon: Icons.water_drop_outlined,
                label: 'מים',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        BillPeriodTableScreen(householdId: householdId, category: BillCategory.water),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _CategoryLink(
                icon: Icons.account_balance_outlined,
                label: 'ארנונה',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        BillPeriodTableScreen(householdId: householdId, category: BillCategory.tax),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppTextStyles.heading2.copyWith(fontSize: 15))),
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// שאלה מבנית חד-פעמית: מים וארנונה משולמים ביחד או בנפרד. בלי
/// שום שאלה על קישורי תשלום - זה נשאל בהמשך, בתוך כל תקופה.
class _CombinedOrSeparateChoiceScreen extends ConsumerWidget {
  final String householdId;

  const _CombinedOrSeparateChoiceScreen({required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.waterAndTaxTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.waterTaxCombinedQuestion, style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(billsRepositoryProvider)
                    .saveCombinedWaterTaxUrl(householdId, '');
              },
              child: const Text(AppStrings.combinedOption, style: AppTextStyles.button),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await ref
                    .read(billsRepositoryProvider)
                    .saveSeparateWaterTaxUrls(householdId, '', '');
              },
              child: const Text(AppStrings.separateOption),
            ),
          ],
        ),
      ),
    );
  }
}

