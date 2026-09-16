import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../models/bill_payment_model.dart';
import '../../providers/bills_provider.dart';
import 'bill_period_table_screen.dart';

/// מסך מים+ארנונה - בפעם הראשונה שואל האם ביחד או בנפרד, לוקח
/// כתובת/ות תשלום, ואז תמיד מציג ישר את הטבלה/ות המתאימות.
class WaterAndTaxScreen extends ConsumerWidget {
  final String householdId;

  const WaterAndTaxScreen({super.key, required this.householdId});

  Future<void> _showEditUrlDialog(
    BuildContext context,
    WidgetRef ref,
    String label,
    String currentUrl,
    Future<void> Function(String url) onSave,
  ) async {
    final controller = TextEditingController(text: currentUrl);
    final newUrl = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: AppStrings.paymentUrlLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text(AppStrings.saveButton),
          ),
        ],
      ),
    );

    if (newUrl == null) return;
    await onSave(newUrl);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(billLinkSettingsProvider(householdId));

    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => const Scaffold(body: Center(child: Text('שגיאה בטעינה'))),
      data: (settings) {
        if (!settings.isWaterTaxConfigured) {
          return _WaterTaxSetupScreen(householdId: householdId);
        }

        if (settings.waterAndTaxCombined == true) {
          return BillPeriodTableScreen(
            householdId: householdId,
            category: BillCategory.waterAndTax,
            title: AppStrings.waterAndTaxTitle,
            showPaymentMethod: false,
            showBarcodeScan: true,
            payButtons: [(label: AppStrings.payNowButton, url: settings.combinedWaterTaxUrl!)],
            onEditLink: () => _showEditUrlDialog(
              context,
              ref,
              AppStrings.waterAndTaxTitle,
              settings.combinedWaterTaxUrl!,
              (url) => ref.read(billsRepositoryProvider).saveCombinedWaterTaxUrl(householdId, url),
            ),
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
                    builder: (_) => BillPeriodTableScreen(
                      householdId: householdId,
                      category: BillCategory.water,
                      title: 'מים',
                      showPaymentMethod: false,
                      showBarcodeScan: true,
                      payButtons: [(label: AppStrings.payWaterButton, url: settings.waterUrl!)],
                      onEditLink: () => _showEditUrlDialog(
                        context,
                        ref,
                        'מים',
                        settings.waterUrl!,
                        (url) => ref
                            .read(billsRepositoryProvider)
                            .saveSeparateWaterTaxUrls(householdId, url, settings.taxUrl!),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _CategoryLink(
                icon: Icons.account_balance_outlined,
                label: 'ארנונה',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BillPeriodTableScreen(
                      householdId: householdId,
                      category: BillCategory.tax,
                      title: 'ארנונה',
                      showPaymentMethod: false,
                      showBarcodeScan: true,
                      payButtons: [(label: AppStrings.payTaxButton, url: settings.taxUrl!)],
                      onEditLink: () => _showEditUrlDialog(
                        context,
                        ref,
                        'ארנונה',
                        settings.taxUrl!,
                        (url) => ref
                            .read(billsRepositoryProvider)
                            .saveSeparateWaterTaxUrls(householdId, settings.waterUrl!, url),
                      ),
                    ),
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

class _WaterTaxSetupScreen extends ConsumerStatefulWidget {
  final String householdId;

  const _WaterTaxSetupScreen({required this.householdId});

  @override
  ConsumerState<_WaterTaxSetupScreen> createState() => _WaterTaxSetupScreenState();
}

class _WaterTaxSetupScreenState extends ConsumerState<_WaterTaxSetupScreen> {
  bool? _combined;
  final _combinedUrlController = TextEditingController();
  final _waterUrlController = TextEditingController();
  final _taxUrlController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _combinedUrlController.dispose();
    _waterUrlController.dispose();
    _taxUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(billsRepositoryProvider);
      if (_combined == true) {
        final url = _combinedUrlController.text.trim();
        if (url.isEmpty) return;
        await repo.saveCombinedWaterTaxUrl(widget.householdId, url);
      } else {
        final waterUrl = _waterUrlController.text.trim();
        final taxUrl = _taxUrlController.text.trim();
        if (waterUrl.isEmpty || taxUrl.isEmpty) return;
        await repo.saveSeparateWaterTaxUrls(widget.householdId, waterUrl, taxUrl);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.waterAndTaxTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.waterTaxCombinedQuestion, style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text(AppStrings.combinedOption)),
                ButtonSegment(value: false, label: Text(AppStrings.separateOption)),
              ],
              selected: _combined == null ? {} : {_combined!},
              emptySelectionAllowed: true,
              onSelectionChanged: (s) => setState(() => _combined = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: 20),
            if (_combined == true)
              TextField(
                controller: _combinedUrlController,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: AppStrings.paymentUrlLabel),
              ),
            if (_combined == false) ...[
              TextField(
                controller: _waterUrlController,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: AppStrings.waterUrlLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taxUrlController,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: AppStrings.taxUrlLabel),
              ),
            ],
            const SizedBox(height: 20),
            if (_combined != null)
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(AppStrings.saveAndContinue, style: AppTextStyles.button),
              ),
          ],
        ),
      ),
    );
  }
}

