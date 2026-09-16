#!/bin/bash
set -e
cat > 'lib/features/bills/bill_period_table_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../models/bill_payment_model.dart';
import '../../providers/bills_provider.dart';

/// פותח קישור בכרטיסייה חדשה, **סינכרונית** (לא async/await) - זה
/// קריטי: דפדפנים חוסמים חלונות קופצים אם יש "פער" (await) בין
/// הלחיצה לפתיחה בפועל. קריאה ישירה ל-dart:html אמינה הרבה יותר
/// מ-url_launcher לצורך הזה בדיוק.
///
/// גם דואגים ל-https:// אם המשתמש שכח להוסיף - בלי זה, הדפדפן
/// מפרש כתובת כמו "bitpay.co.il" כנתיב יחסי *בתוך* האתר שלנו
/// (מנווט בתוכו במקום לצאת החוצה) - בדיוק הבאג שדווח.
void openPaymentLink(String url) {
  final normalized =
      (url.startsWith('http://') || url.startsWith('https://')) ? url : 'https://$url';
  html.window.open(normalized, '_blank');
}

/// מסך טבלת תשלומים דו-חודשית גנרי - משמש לחשמל, מים, ארנונה
/// (בנפרד או ביחד). זהה במבנה ל-VaadBayitScreen, רק עם 6 תקופות
/// של חודשיים במקום 12 חודשים, ועם כפתור/י "שלם עכשיו" למעלה.
class BillPeriodTableScreen extends ConsumerWidget {
  final String householdId;
  final BillCategory category;
  final String title;
  final List<({String label, String url})> payButtons;
  final bool showPaymentMethod;
  final VoidCallback? onEditLink;

  const BillPeriodTableScreen({
    super.key,
    required this.householdId,
    required this.category,
    required this.title,
    required this.payButtons,
    this.showPaymentMethod = true,
    this.onEditLink,
  });

  static const _periodStartMonths = [1, 3, 5, 7, 9, 11];
  static final _monthNames = AppStrings.monthNames.split(',');

  String _periodLabel(int startMonth) {
    final endMonth = startMonth == 11 ? 1 : startMonth + 1;
    return '${_monthNames[startMonth - 1]}-${_monthNames[endMonth - 1]}';
  }

  Future<void> _openPeriodSheet(BuildContext context, WidgetRef ref, int startMonth) async {
    final year = DateTime.now().year;
    final billsAsync = ref.read(billsForYearProvider(
      (householdId: householdId, category: category, year: year),
    ));
    final existing =
        (billsAsync.value ?? []).where((b) => b.periodStartMonth == startMonth);
    final bill = existing.isNotEmpty ? existing.first : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BillPeriodEditSheet(
        householdId: householdId,
        category: category,
        year: year,
        periodStartMonth: startMonth,
        periodLabel: _periodLabel(startMonth),
        existing: bill,
        showPaymentMethod: showPaymentMethod,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final billsAsync = ref.watch(billsForYearProvider(
      (householdId: householdId, category: category, year: year),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text('$title · $year'),
        actions: onEditLink != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editLinkButton,
                  onPressed: onEditLink,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          if (payButtons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: payButtons
                    .map((btn) => ElevatedButton.icon(
                          onPressed: () => openPaymentLink(btn.url),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text(btn.label),
                        ))
                    .toList(),
              ),
            ),
          Expanded(
            child: billsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(child: Text('שגיאה בטעינה')),
              data: (bills) {
                final byMonth = {for (final b in bills) b.periodStartMonth: b};

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _periodStartMonths.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final startMonth = _periodStartMonths[index];
                    final bill = byMonth[startMonth];
                    final isPaid = bill?.isPaid ?? false;

                    return ListTile(
                      leading: Icon(
                        isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isPaid ? AppColors.itemPurchased : AppColors.textSecondary,
                      ),
                      title: Text(_periodLabel(startMonth)),
                      subtitle: bill?.amount != null ? Text('₪${bill!.amount}') : null,
                      trailing: Text(
                        isPaid ? AppStrings.paidStatus : AppStrings.notPaidStatus,
                        style: TextStyle(
                          color: isPaid ? AppColors.itemPurchased : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _openPeriodSheet(context, ref, startMonth),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// חלונית עריכה לתקופה אחת - זהה ל-_MonthEditSheet הפנימי של
/// VaadBayitScreen, רק public כדי שהמסך הגנרי יוכל להשתמש בה.
class BillPeriodEditSheet extends ConsumerStatefulWidget {
  final String householdId;
  final BillCategory category;
  final int year;
  final int periodStartMonth;
  final String periodLabel;
  final BillPayment? existing;
  final bool showPaymentMethod;

  const BillPeriodEditSheet({
    super.key,
    required this.householdId,
    required this.category,
    required this.year,
    required this.periodStartMonth,
    required this.periodLabel,
    required this.existing,
    this.showPaymentMethod = true,
  });

  @override
  ConsumerState<BillPeriodEditSheet> createState() => _BillPeriodEditSheetState();
}

class _BillPeriodEditSheetState extends ConsumerState<BillPeriodEditSheet> {
  late final TextEditingController _amountController;
  String? _paymentMethod;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.existing?.amount?.toString() ?? '');
    _paymentMethod = widget.existing?.paymentMethod;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _showPayNowChooser() async {
    final settings = ref.read(billLinkSettingsProvider(widget.householdId)).value;

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
              title: const Text(AppStrings.paymentMethodBit),
              trailing: (settings?.bitUrl != null && settings!.bitUrl!.isNotEmpty)
                  ? IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: AppStrings.editLinkButton,
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        final url = await _promptForAppUrl(AppStrings.paymentMethodBit);
                        if (url != null) {
                          await ref
                              .read(billsRepositoryProvider)
                              .saveBitUrl(widget.householdId, url);
                        }
                      },
                    )
                  : null,
              onTap: () {
                if (settings?.bitUrl != null && settings!.bitUrl!.isNotEmpty) {
                  openPaymentLink(settings.bitUrl!);
                }
                Navigator.of(sheetContext).pop(AppStrings.paymentMethodBit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
              title: const Text(AppStrings.paymentMethodPaybox),
              trailing: (settings?.payboxUrl != null && settings!.payboxUrl!.isNotEmpty)
                  ? IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: AppStrings.editLinkButton,
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        final url = await _promptForAppUrl(AppStrings.paymentMethodPaybox);
                        if (url != null) {
                          await ref
                              .read(billsRepositoryProvider)
                              .savePayboxUrl(widget.householdId, url);
                        }
                      },
                    )
                  : null,
              onTap: () {
                if (settings?.payboxUrl != null && settings!.payboxUrl!.isNotEmpty) {
                  openPaymentLink(settings.payboxUrl!);
                }
                Navigator.of(sheetContext).pop(AppStrings.paymentMethodPaybox);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined, color: AppColors.primary),
              title: const Text(AppStrings.paymentMethodCash),
              onTap: () => Navigator.of(sheetContext).pop(AppStrings.paymentMethodCash),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;
    setState(() => _paymentMethod = choice);

    // אם הקישור עדיין לא הוגדר בכלל (פעם ראשונה) - רק עכשיו שואלים
    // ושומרים; הפתיחה בפעם הבאה תהיה תמיד סינכרונית כמו למעלה.
    final isBit = choice == AppStrings.paymentMethodBit;
    final isPaybox = choice == AppStrings.paymentMethodPaybox;
    if (isBit && (settings?.bitUrl == null || settings!.bitUrl!.isEmpty)) {
      final url = await _promptForAppUrl(AppStrings.paymentMethodBit);
      if (url != null && url.isNotEmpty) {
        await ref.read(billsRepositoryProvider).saveBitUrl(widget.householdId, url);
      }
    } else if (isPaybox && (settings?.payboxUrl == null || settings!.payboxUrl!.isEmpty)) {
      final url = await _promptForAppUrl(AppStrings.paymentMethodPaybox);
      if (url != null && url.isNotEmpty) {
        await ref.read(billsRepositoryProvider).savePayboxUrl(widget.householdId, url);
      }
    }
  }

  Future<String?> _promptForAppUrl(String appName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${AppStrings.enterAppLinkTitlePrefix} $appName'),
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
            child: const Text(AppStrings.saveAndContinue),
          ),
        ],
      ),
    );
  }

  void _viewReceipt() {
    final receiptData = widget.existing?.receiptData;
    final mimeType = widget.existing?.receiptMimeType ?? '';
    if (receiptData == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mimeType.startsWith('image/'))
                Flexible(
                  child: InteractiveViewer(
                    child: Image.memory(base64Decode(receiptData)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, size: 48, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(widget.existing?.receiptFileName ?? ''),
                      const SizedBox(height: 4),
                      const Text(AppStrings.pdfPreviewUnavailable, style: AppTextStyles.bodySecondary),
                    ],
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(AppStrings.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteReceipt() async {
    setState(() => _isDeleting = true);
    try {
      await ref.read(billsRepositoryProvider).deleteReceipt(
            householdId: widget.householdId,
            category: widget.category,
            year: widget.year,
            periodStartMonth: widget.periodStartMonth,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('שגיאה במחיקת הקבלה')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final amount = double.tryParse(_amountController.text.trim());
      await ref.read(billsRepositoryProvider).saveBillDetails(
            householdId: widget.householdId,
            category: widget.category,
            year: widget.year,
            periodStartMonth: widget.periodStartMonth,
            amount: amount,
            paymentMethod: _paymentMethod,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('שגיאה בשמירה')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadReceipt() async {
    final file = await ref.read(filePickerServiceProvider).pickReceiptFile();
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      await ref.read(billsRepositoryProvider).uploadReceiptAndMarkPaid(
            householdId: widget.householdId,
            category: widget.category,
            year: widget.year,
            periodStartMonth: widget.periodStartMonth,
            file: file,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(AppStrings.receiptUploadedSuccess)));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('שגיאה בהעלאה')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.existing?.isPaid ?? false;
    // חשוב: זה חייב להיות watch (לא רק read מאוחר יותר) - כדי
    // שה-Firestore listener יהיה כבר פעיל ברגע שהחלונית נפתחת,
    // ולא "יתפוס" ערך ריק אם המשתמש לוחץ על "שלם עכשיו" מהר מדי
    // אחרי הפתיחה.
    ref.watch(billLinkSettingsProvider(widget.householdId));

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.periodLabel, style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: AppStrings.amountLabel),
          ),
          const SizedBox(height: 12),
          if (widget.showPaymentMethod) ...[
            ElevatedButton.icon(
              onPressed: _showPayNowChooser,
              icon: const Icon(Icons.payments_outlined),
              label: const Text(AppStrings.payNowButton),
            ),
            if (_paymentMethod != null) ...[
              const SizedBox(height: 6),
              Text(
                '${AppStrings.paymentMethodLabel}: $_paymentMethod',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(AppStrings.saveButton, style: AppTextStyles.button),
          ),
          const SizedBox(height: 12),
          if (isPaid) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.itemPurchased, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${AppStrings.receiptUploadedLabel}: ${widget.existing?.receiptFileName ?? ''}',
                    style: AppTextStyles.bodySecondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _viewReceipt,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text(AppStrings.viewReceiptButton),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _isDeleting ? null : _deleteReceipt,
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  label: const Text(
                    AppStrings.deleteReceiptButton,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _uploadReceipt,
              icon: _isUploading
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              label: Text(
                  _isUploading ? AppStrings.uploadingReceipt : AppStrings.uploadReceiptButton),
            ),
        ],
      ),
    );
  }
}

HMEOF
echo 'DONE - URLs without https:// are now auto-fixed!'
