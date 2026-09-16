import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../models/bill_payment_model.dart';
import '../../providers/bills_provider.dart';
import 'bill_period_table_screen.dart';

/// מסך "ועד בית" - טבלת 12 החודשים של שנה נתונה (ניתן לדפדף בין
/// שנים עם החצים ב-AppBar - לא נשארים תקועים רק על השנה הנוכחית).
/// כל שורה ניתנת **להחלקה** (משמאל לימין) כדי לבטל תשלום קיים.
class VaadBayitScreen extends ConsumerStatefulWidget {
  final String householdId;

  const VaadBayitScreen({super.key, required this.householdId});

  @override
  ConsumerState<VaadBayitScreen> createState() => _VaadBayitScreenState();
}

class _VaadBayitScreenState extends ConsumerState<VaadBayitScreen> {
  late int _year;

  static final List<String> _monthNames = AppStrings.monthNames.split(',');

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    maybeShowSwipeHintAfterDelay(context);
  }

  Future<void> _openMonthSheet(BuildContext context, WidgetRef ref, int month) async {
    final billsAsync = ref.read(billsForYearProvider(
      (householdId: widget.householdId, category: BillCategory.vaadBayit, year: _year),
    ));
    final existing = (billsAsync.value ?? []).where((b) => b.periodStartMonth == month);
    final bill = existing.isNotEmpty ? existing.first : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BillPeriodEditSheet(
        householdId: widget.householdId,
        category: BillCategory.vaadBayit,
        year: _year,
        periodStartMonth: month,
        periodLabel: _monthNames[month - 1],
        existing: bill,
        showPaymentMethod: true,
      ),
    );
  }

  Future<void> _cancelPayment(WidgetRef ref, int month) {
    return ref.read(billsRepositoryProvider).cancelPayment(
          householdId: widget.householdId,
          category: BillCategory.vaadBayit,
          year: _year,
          periodStartMonth: month,
        );
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsForYearProvider(
      (householdId: widget.householdId, category: BillCategory.vaadBayit, year: _year),
    ));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _year--),
            ),
            Text('${AppStrings.vaadBayitTitle} · $_year', style: AppTextStyles.categoryTitle()),
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
            itemCount: 12,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final month = index + 1;
              final bill = byMonth[month];
              final isPaid = bill?.isPaid ?? false;

              return Dismissible(
                key: ValueKey('vaad-$_year-$month-$isPaid'),
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
                  await _cancelPayment(ref, month);
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
                      Text(_monthNames[index]),
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
                  onTap: () => _openMonthSheet(context, ref, month),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

