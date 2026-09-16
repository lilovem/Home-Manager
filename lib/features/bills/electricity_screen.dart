import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../models/bill_payment_model.dart';
import '../../providers/bills_provider.dart';
import 'bill_period_table_screen.dart';

/// מסך חשמל - אם עדיין לא הוגדר קישור תשלום, מציג טופס הגדרה
/// חד-פעמי. אחרי ההגדרה, תמיד מציג ישר את טבלת התשלומים
/// עם כפתור "שלם עכשיו" + אפשרות עריכה של הקישור. אין כאן
/// בחירת "אמצעי תשלום" (זה תמיד דרך אתר החברה, לא ביט/פייבוקס).
class ElectricityScreen extends ConsumerWidget {
  final String householdId;

  const ElectricityScreen({super.key, required this.householdId});

  Future<void> _showEditUrlDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUrl,
  ) async {
    final controller = TextEditingController(text: currentUrl);
    final newUrl = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.enterPaymentUrlTitle),
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
    await ref.read(billsRepositoryProvider).saveElectricityUrl(householdId, newUrl);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(billLinkSettingsProvider(householdId));

    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => const Scaffold(body: Center(child: Text('שגיאה בטעינה'))),
      data: (settings) {
        if (!settings.isElectricityConfigured) {
          return _UrlSetupScreen(
            title: AppStrings.electricityTitle,
            onSave: (url) => ref.read(billsRepositoryProvider).saveElectricityUrl(householdId, url),
          );
        }

        return BillPeriodTableScreen(
          householdId: householdId,
          category: BillCategory.electricity,
          title: AppStrings.electricityTitle,
          showPaymentMethod: false,
          showBarcodeScan: true,
          payButtons: [(label: AppStrings.payNowButton, url: settings.electricityUrl!)],
          onEditLink: () => _showEditUrlDialog(context, ref, settings.electricityUrl!),
        );
      },
    );
  }
}

/// טופס פשוט להזנת כתובת אתר תשלום, בשימוש חוזר לחשמל/מים/ארנונה.
class _UrlSetupScreen extends StatefulWidget {
  final String title;
  final Future<void> Function(String url) onSave;

  const _UrlSetupScreen({required this.title, required this.onSave});

  @override
  State<_UrlSetupScreen> createState() => _UrlSetupScreenState();
}

class _UrlSetupScreenState extends State<_UrlSetupScreen> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(url);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.enterPaymentUrlTitle, style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            const Text(AppStrings.enterPaymentUrlBody, style: AppTextStyles.bodySecondary),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: AppStrings.paymentUrlLabel),
            ),
            const SizedBox(height: 16),
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

