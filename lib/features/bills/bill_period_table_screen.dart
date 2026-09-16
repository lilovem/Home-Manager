import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../models/bill_payment_model.dart';
import '../../providers/bills_provider.dart';
import 'barcode_scan_screen.dart';

/// ברירות מחדל לביט/פייבוקס - קישורי Google Play שתמיד עובדים
/// (אם האפליקציה כבר מותקנת, גוגל פליי יציג כפתור "פתח" ולא
/// "התקן"). אפשר לדרוס אותם דרך אייקון העריכה אם נמצא קישור טוב
/// יותר (deep link ישיר) בעתיד.
const String _kBitDefaultUrl =
    'https://play.google.com/store/apps/details?id=com.bnhp.payments.paymentsapp';
const String _kPayboxDefaultUrl =
    'https://play.google.com/store/apps/details?id=com.payboxapp';

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
///
/// כל שורה ניתנת **להחלקה** (swipe) כדי לבטל תשלום קיים - בלי
/// לפתוח את חלונית העריכה בכלל.
class BillPeriodTableScreen extends ConsumerWidget {
  final String householdId;
  final BillCategory category;
  final String title;
  final List<({String label, String url})> payButtons;
  final bool showPaymentMethod;
  final bool showBarcodeScan;
  final VoidCallback? onEditLink;

  const BillPeriodTableScreen({
    super.key,
    required this.householdId,
    required this.category,
    required this.title,
    required this.payButtons,
    this.showPaymentMethod = true,
    this.showBarcodeScan = false,
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
        showBarcodeScan: showBarcodeScan,
      ),
    );
  }

  Future<void> _cancelPayment(WidgetRef ref, int year, int startMonth) {
    return ref.read(billsRepositoryProvider).cancelPayment(
          householdId: householdId,
          category: category,
          year: year,
          periodStartMonth: startMonth,
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

                    return Dismissible(
                      key: ValueKey('$category-$startMonth-$isPaid'),
                      direction:
                          isPaid ? DismissDirection.startToEnd : DismissDirection.none,
                      background: Container(
                        color: AppColors.error,
                        alignment: AlignmentDirectional.centerStart,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Text(
                          AppStrings.cancelPaymentAction,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        await _cancelPayment(ref, year, startMonth);
                        return false; // השורה נשארת בטבלה, רק הסטטוס משתנה.
                      },
                      child: ListTile(
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
                      ),
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

/// חלונית עריכה לתקופה אחת - סכום, אמצעי תשלום (אם רלוונטי).
/// שמירה תמיד מסמנת "שולם" - אין יותר מנגנון קבלות; ביטול תשלום
/// נעשה בהחלקה על השורה בטבלה, לא כאן.
class BillPeriodEditSheet extends ConsumerStatefulWidget {
  final String householdId;
  final BillCategory category;
  final int year;
  final int periodStartMonth;
  final String periodLabel;
  final BillPayment? existing;
  final bool showPaymentMethod;
  final bool showBarcodeScan;

  const BillPeriodEditSheet({
    super.key,
    required this.householdId,
    required this.category,
    required this.year,
    required this.periodStartMonth,
    required this.periodLabel,
    required this.existing,
    this.showPaymentMethod = true,
    this.showBarcodeScan = false,
  });

  @override
  ConsumerState<BillPeriodEditSheet> createState() => _BillPeriodEditSheetState();
}

class _BillPeriodEditSheetState extends ConsumerState<BillPeriodEditSheet> {
  late final TextEditingController _amountController;
  String? _paymentMethod;
  bool _isSaving = false;

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

  Future<String?> _promptForAppUrl(String appName, String currentUrl) async {
    final controller = TextEditingController(text: currentUrl);
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

  Future<void> _showPayNowChooser() async {
    final settings = ref.read(billLinkSettingsProvider(widget.householdId)).value;
    final bitUrl = (settings?.bitUrl != null && settings!.bitUrl!.isNotEmpty)
        ? settings.bitUrl!
        : _kBitDefaultUrl;
    final payboxUrl = (settings?.payboxUrl != null && settings!.payboxUrl!.isNotEmpty)
        ? settings.payboxUrl!
        : _kPayboxDefaultUrl;

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
              title: const Text(AppStrings.paymentMethodBit),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: AppStrings.editLinkButton,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  final url = await _promptForAppUrl(AppStrings.paymentMethodBit, bitUrl);
                  if (url != null) {
                    await ref.read(billsRepositoryProvider).saveBitUrl(widget.householdId, url);
                  }
                },
              ),
              onTap: () {
                openPaymentLink(bitUrl);
                Navigator.of(sheetContext).pop(AppStrings.paymentMethodBit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
              title: const Text(AppStrings.paymentMethodPaybox),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: AppStrings.editLinkButton,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  final url = await _promptForAppUrl(AppStrings.paymentMethodPaybox, payboxUrl);
                  if (url != null) {
                    await ref.read(billsRepositoryProvider).savePayboxUrl(widget.householdId, url);
                  }
                },
              ),
              onTap: () {
                openPaymentLink(payboxUrl);
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
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
    if (result != null && mounted) {
      setState(() => _paymentMethod = AppStrings.paymentMethodBarcode);
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

  @override
  Widget build(BuildContext context) {
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
          if (widget.showPaymentMethod)
            ElevatedButton.icon(
              onPressed: _showPayNowChooser,
              icon: const Icon(Icons.payments_outlined),
              label: const Text(AppStrings.payNowButton),
            ),
          if (widget.showBarcodeScan) ...[
            if (widget.showPaymentMethod) const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text(AppStrings.scanBarcodeButton),
            ),
          ],
          if (_paymentMethod != null) ...[
            const SizedBox(height: 6),
            Text(
              '${AppStrings.paymentMethodLabel}: $_paymentMethod',
              style: AppTextStyles.bodySecondary,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(AppStrings.saveButton, style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

