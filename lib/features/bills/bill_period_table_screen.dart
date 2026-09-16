import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/bill_link_settings_model.dart';
import '../../models/bill_payment_model.dart';
import '../../providers/bills_provider.dart';
import 'barcode_scan_screen.dart';
import 'modern_time_picker.dart';

/// פותח קישור בכרטיסייה חדשה, **סינכרונית** (לא async/await) - זה
/// קריטי: דפדפנים חוסמים חלונות קופצים אם יש "פער" (await) בין
/// הלחיצה לפתיחה בפועל. קריאה ישירה ל-dart:html אמינה הרבה יותר
/// מ-url_launcher לצורך הזה בדיוק.
///
/// גם דואגים ל-https:// אם המשתמש שכח להוסיף - בלי זה, הדפדפן
/// מפרש כתובת כמו "bitpay.co.il" כנתיב יחסי *בתוך* האתר שלנו.
void openPaymentLink(String url) {
  final normalized =
      (url.startsWith('http://') || url.startsWith('https://')) ? url : 'https://$url';
  html.window.open(normalized, '_blank');
}

/// מציג "טיפ" חד-פעמי (פעם אחת בכל דפדפן, לא בכל כניסה) אחרי 5
/// שניות, על האפשרות להחליק ולבטל תשלום. נשמר ב-localStorage כדי
/// שלא יחזור על עצמו לאחר הפעם הראשונה.
void maybeShowSwipeHintAfterDelay(BuildContext context) {
  Future.delayed(const Duration(seconds: 5), () {
    if (!context.mounted) return;
    if (html.window.localStorage['seenBillSwipeHint'] == 'true') return;
    html.window.localStorage['seenBillSwipeHint'] = 'true';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.swipeHintMessage),
        duration: Duration(seconds: 5),
      ),
    );
  });
}

/// שולף מתוך ההגדרות את הקישור השמור עבור קטגוריה נתונה (חשמל/
/// מים/ארנונה/מים+ארנונה-ביחד). ריק/null = עדיין לא הוגדר.
String? _currentUrlForCategory(BillLinkSettings settings, BillCategory category) {
  switch (category) {
    case BillCategory.electricity:
      return settings.electricityUrl;
    case BillCategory.waterAndTax:
      return settings.combinedWaterTaxUrl;
    case BillCategory.water:
      return settings.waterUrl;
    case BillCategory.tax:
      return settings.taxUrl;
    case BillCategory.vaadBayit:
      return null;
  }
}

/// מסך טבלת תשלומים דו-חודשית - משמש לחשמל, מים, ארנונה (בנפרד
/// או ביחד). ניתן לדפדף בין שנים עם החצים ב-AppBar. כל שורה
/// ניתנת **להחלקה** (משמאל לימין) כדי לבטל תשלום קיים. בכל כניסה
/// לתקופה, חלונית העריכה מציעה מחדש "שלם עכשיו" (סריקת ברקוד או
/// קישור לאתר) - אין יותר מסך הגדרה כפוי מראש.
class BillPeriodTableScreen extends ConsumerStatefulWidget {
  final String householdId;
  final BillCategory category;

  const BillPeriodTableScreen({
    super.key,
    required this.householdId,
    required this.category,
  });

  @override
  ConsumerState<BillPeriodTableScreen> createState() => _BillPeriodTableScreenState();
}

class _BillPeriodTableScreenState extends ConsumerState<BillPeriodTableScreen> {
  late int _year;

  static const _periodStartMonths = [1, 3, 5, 7, 9, 11];
  static final _monthNames = AppStrings.monthNames.split(',');

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    maybeShowSwipeHintAfterDelay(context);
  }

  String get _title {
    switch (widget.category) {
      case BillCategory.electricity:
        return AppStrings.electricityTitle;
      case BillCategory.waterAndTax:
        return AppStrings.waterAndTaxTitle;
      case BillCategory.water:
        return 'מים';
      case BillCategory.tax:
        return 'ארנונה';
      case BillCategory.vaadBayit:
        return AppStrings.vaadBayitTitle;
    }
  }

  String _periodLabel(int startMonth) {
    final endMonth = startMonth == 11 ? 1 : startMonth + 1;
    return '${_monthNames[startMonth - 1]}-${_monthNames[endMonth - 1]}';
  }

  Future<void> _openPeriodSheet(BuildContext context, int startMonth) async {
    final billsAsync = ref.read(billsForYearProvider(
      (householdId: widget.householdId, category: widget.category, year: _year),
    ));
    final existing =
        (billsAsync.value ?? []).where((b) => b.periodStartMonth == startMonth);
    final bill = existing.isNotEmpty ? existing.first : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BillPeriodEditSheet(
        householdId: widget.householdId,
        category: widget.category,
        year: _year,
        periodStartMonth: startMonth,
        periodLabel: _periodLabel(startMonth),
        existing: bill,
        showPaymentOptions: true,
      ),
    );
  }

  Future<void> _cancelPayment(int startMonth) {
    return ref.read(billsRepositoryProvider).cancelPayment(
          householdId: widget.householdId,
          category: widget.category,
          year: _year,
          periodStartMonth: startMonth,
        );
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsForYearProvider(
      (householdId: widget.householdId, category: widget.category, year: _year),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _year--),
            ),
            Text('$_title · $_year', style: AppTextStyles.categoryTitle()),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _year++),
            ),
          ],
        ),
      ),
      body: billsAsync.when(
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
                key: ValueKey('${widget.category}-$_year-$startMonth-$isPaid'),
                direction: isPaid ? DismissDirection.endToStart : DismissDirection.none,
                background: Container(
                  color: AppColors.error,
                  alignment: AlignmentDirectional.centerEnd,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    AppStrings.cancelPaymentAction,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                confirmDismiss: (direction) async {
                  await _cancelPayment(startMonth);
                  return false;
                },
                child: ListTile(
                  leading: Icon(
                    isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isPaid ? AppColors.itemPurchased : AppColors.textSecondary,
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_periodLabel(startMonth)),
                      if (bill?.reminderAt != null) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.alarm, size: 24, color: Colors.green),
                      ],
                    ],
                  ),
                  subtitle: bill?.amount != null ? Text('₪${bill!.amount}') : null,
                  trailing: Text(
                    isPaid ? AppStrings.paidStatus : AppStrings.notPaidStatus,
                    style: TextStyle(
                      color: isPaid ? AppColors.itemPurchased : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _openPeriodSheet(context, startMonth),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// חלונית עריכה לתקופה אחת. `showPaymentOptions` (חשמל/מים/ארנונה)
/// מציג כפתור "שלם עכשיו" עם בחירה בין סריקת ברקוד לתשלום
/// בקישור - זה נשאל **בכל כניסה מחדש**, לא רק בפעם הראשונה
/// (הקישור עצמו, לעומת זאת, נשמר ונשאר קבוע עד שעורכים אותו).
/// ועד בית (showPaymentMethod) ממשיך להשתמש בבחירת ביט/פייבוקס/מזומן.
class BillPeriodEditSheet extends ConsumerStatefulWidget {
  final String householdId;
  final BillCategory category;
  final int year;
  final int periodStartMonth;
  final String periodLabel;
  final BillPayment? existing;
  final bool showPaymentMethod;
  final bool showPaymentOptions;

  const BillPeriodEditSheet({
    super.key,
    required this.householdId,
    required this.category,
    required this.year,
    required this.periodStartMonth,
    required this.periodLabel,
    required this.existing,
    this.showPaymentMethod = false,
    this.showPaymentOptions = false,
  });

  @override
  ConsumerState<BillPeriodEditSheet> createState() => _BillPeriodEditSheetState();
}

class _BillPeriodEditSheetState extends ConsumerState<BillPeriodEditSheet> {
  late final TextEditingController _amountController;
  String? _paymentMethod;
  DateTime? _reminderAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.existing?.amount?.toString() ?? '');
    _paymentMethod = widget.existing?.paymentMethod;
    _reminderAt = widget.existing?.reminderAt;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<String?> _promptForUrl(String label, String currentUrl) async {
    final controller = TextEditingController(text: currentUrl);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${AppStrings.enterAppLinkTitlePrefix} $label'),
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

  Future<void> _saveUrlForCurrentCategory(String url) async {
    final repo = ref.read(billsRepositoryProvider);
    final settings = ref.read(billLinkSettingsProvider(widget.householdId)).value;

    switch (widget.category) {
      case BillCategory.electricity:
        await repo.saveElectricityUrl(widget.householdId, url);
        break;
      case BillCategory.waterAndTax:
        await repo.saveCombinedWaterTaxUrl(widget.householdId, url);
        break;
      case BillCategory.water:
        await repo.saveSeparateWaterTaxUrls(
            widget.householdId, url, settings?.taxUrl ?? '');
        break;
      case BillCategory.tax:
        await repo.saveSeparateWaterTaxUrls(
            widget.householdId, settings?.waterUrl ?? '', url);
        break;
      case BillCategory.vaadBayit:
        break;
    }
  }

  /// "שלם עכשיו" לחשמל/מים/ארנונה - בוחרים סריקת ברקוד או קישור.
  Future<void> _showPaymentOptionsChooser() async {
    final settings = ref.read(billLinkSettingsProvider(widget.householdId)).value;
    final currentUrl =
        settings != null ? _currentUrlForCategory(settings, widget.category) : null;
    final hasUrl = currentUrl != null && currentUrl.isNotEmpty;

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
              title: const Text(AppStrings.scanBarcodeButton),
              onTap: () => Navigator.of(sheetContext).pop('barcode'),
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: const Text(AppStrings.payByLinkButton),
              trailing: hasUrl
                  ? IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: AppStrings.editLinkButton,
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        final url = await _promptForUrl(_title, currentUrl);
                        if (url != null) await _saveUrlForCurrentCategory(url);
                      },
                    )
                  : null,
              onTap: () {
                if (hasUrl) {
                  openPaymentLink(currentUrl);
                  Navigator.of(sheetContext).pop('link');
                } else {
                  Navigator.of(sheetContext).pop('link_needs_url');
                }
              },
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'barcode') {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
      );
      if (result != null && mounted) {
        setState(() => _paymentMethod = AppStrings.paymentMethodBarcode);
      }
    } else if (choice == 'link') {
      if (mounted) setState(() => _paymentMethod = AppStrings.paymentMethodLink);
    } else if (choice == 'link_needs_url') {
      final url = await _promptForUrl(_title, '');
      if (url != null && url.isNotEmpty) {
        await _saveUrlForCurrentCategory(url);
        openPaymentLink(url);
        if (mounted) setState(() => _paymentMethod = AppStrings.paymentMethodLink);
      }
    }
  }

  String get _title {
    switch (widget.category) {
      case BillCategory.electricity:
        return AppStrings.electricityTitle;
      case BillCategory.waterAndTax:
        return AppStrings.waterAndTaxTitle;
      case BillCategory.water:
        return 'מים';
      case BillCategory.tax:
        return 'ארנונה';
      case BillCategory.vaadBayit:
        return AppStrings.vaadBayitTitle;
    }
  }

  /// "שלם עכשיו" לועד בית - ביט/פייבוקס/מזומן (ללא שינוי מהעבר).
  Future<void> _showPayNowChooserVaad() async {
    const kBitDefaultUrl =
        'https://play.google.com/store/apps/details?id=com.bnhp.payments.paymentsapp';
    const kPayboxDefaultUrl = 'https://play.google.com/store/apps/details?id=com.payboxapp';

    final settings = ref.read(billLinkSettingsProvider(widget.householdId)).value;
    final bitUrl = (settings?.bitUrl != null && settings!.bitUrl!.isNotEmpty)
        ? settings.bitUrl!
        : kBitDefaultUrl;
    final payboxUrl = (settings?.payboxUrl != null && settings!.payboxUrl!.isNotEmpty)
        ? settings.payboxUrl!
        : kPayboxDefaultUrl;

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
                  final url = await _promptForUrl(AppStrings.paymentMethodBit, bitUrl);
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
                  final url = await _promptForUrl(AppStrings.paymentMethodPaybox, payboxUrl);
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

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: AppStrings.pickReminderDateTitle,
    );
    if (date == null || !mounted) return;

    final time = await showModernTimePicker(context, TimeOfDay.now());
    if (time == null || !mounted) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (combined.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.reminderInPastError)));
      return;
    }

    // רק state מקומי - נשמר בפועל רק כשלוחצים "שמור" למטה.
    setState(() => _reminderAt = combined);
  }

  void _clearReminder() {
    setState(() => _reminderAt = null);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (_reminderAt != null && amount == null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(AppStrings.reminderNeedsAmountTitle),
          content: const Text(AppStrings.reminderNeedsAmountBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.close),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(billsRepositoryProvider).saveBillDetails(
            householdId: widget.householdId,
            category: widget.category,
            year: widget.year,
            periodStartMonth: widget.periodStartMonth,
            amount: amount,
            paymentMethod: _paymentMethod,
          );

      // תזכורת נשמרת/מתבטלת רק כאן, בלחיצת "שמור" - לא ברגע הבחירה.
      final hadReminder = widget.existing?.reminderAt != null;
      if (_reminderAt != null) {
        await ref.read(billsRepositoryProvider).saveReminder(
              householdId: widget.householdId,
              category: widget.category,
              year: widget.year,
              periodStartMonth: widget.periodStartMonth,
              reminderAt: _reminderAt!,
            );
      } else if (hadReminder) {
        await ref.read(billsRepositoryProvider).clearReminder(
              householdId: widget.householdId,
              category: widget.category,
              year: widget.year,
              periodStartMonth: widget.periodStartMonth,
            );
      }

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
              onPressed: _showPayNowChooserVaad,
              icon: const Icon(Icons.payments_outlined),
              label: const Text(AppStrings.payNowButton),
            ),
          if (widget.showPaymentOptions)
            ElevatedButton.icon(
              onPressed: _showPaymentOptionsChooser,
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
          const SizedBox(height: 12),
          if (_reminderAt == null)
            OutlinedButton.icon(
              onPressed: _pickReminder,
              icon: const Icon(Icons.alarm_add_outlined),
              label: const Text(AppStrings.reminderButton),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppStrings.reminderSetLabel} ${DateFormatter.short(_reminderAt)}',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
                TextButton(
                  onPressed: _pickReminder,
                  child: const Text(AppStrings.editReminderButton),
                ),
                TextButton(
                  onPressed: _clearReminder,
                  child: const Text(
                    AppStrings.clearReminderButton,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
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

