import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../models/shopping_item_model.dart';
import '../../providers/shopping_provider.dart';

/// מסך סיכום קנייה - מוצג כשלוחצים "סיום קנייה".
///
/// מציג מה נקנה (למידע בלבד) ומה לא נמצא (עם checkbox לכל פריט -
/// מסומן = יועבר לקנייה הבאה, לא מסומן = יימחק). באישור: כל
/// הפריטים שנקנו נמחקים, הלא-נמצאים מטופלים לפי הבחירה, ונשמרת
/// רשומת סיכום בהיסטוריה - הכל בפעולה אחת אטומית.
class ShoppingSummaryScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String listId;
  final List<ShoppingItem> purchasedItems;
  final List<ShoppingItem> notFoundItems;
  final int totalItemsCount;
  final String? activeSessionId;

  const ShoppingSummaryScreen({
    super.key,
    required this.householdId,
    required this.listId,
    required this.purchasedItems,
    required this.notFoundItems,
    required this.totalItemsCount,
    this.activeSessionId,
  });

  @override
  ConsumerState<ShoppingSummaryScreen> createState() => _ShoppingSummaryScreenState();
}

class _ShoppingSummaryScreenState extends ConsumerState<ShoppingSummaryScreen> {
  late final Map<String, bool> _carryOver;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ברירת מחדל: כל הפריטים שלא נמצאו מסומנים להעברה לקנייה הבאה.
    _carryOver = {for (final item in widget.notFoundItems) item.id: true};
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);

    final toCarryOver =
        widget.notFoundItems.where((item) => _carryOver[item.id] == true).toList();
    final toDrop =
        widget.notFoundItems.where((item) => _carryOver[item.id] != true).toList();

    try {
      await ref.read(shoppingRepositoryProvider).finishShopping(
            householdId: widget.householdId,
            listId: widget.listId,
            purchasedItems: widget.purchasedItems,
            notFoundItemsToCarryOver: toCarryOver,
            notFoundItemsToDrop: toDrop,
            totalItemsCount: widget.totalItemsCount,
            activeSessionId: widget.activeSessionId,
          );
      if (mounted) Navigator.of(context).pop();
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.shoppingSummary)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStat(
                          label: AppStrings.itemsCountLabel,
                          value: widget.totalItemsCount.toString(),
                        ),
                      ),
                      Expanded(
                        child: _SummaryStat(
                          label: AppStrings.purchasedItemsLabel,
                          value: widget.purchasedItems.length.toString(),
                          color: AppColors.itemPurchased,
                        ),
                      ),
                      Expanded(
                        child: _SummaryStat(
                          label: AppStrings.notFoundItemsLabel,
                          value: widget.notFoundItems.length.toString(),
                          color: AppColors.itemNotFound,
                        ),
                      ),
                    ],
                  ),
                  if (widget.notFoundItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.carryOverHint,
                          style: AppTextStyles.bodySecondary,
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(() {
                                for (final id in _carryOver.keys) {
                                  _carryOver[id] = true;
                                }
                              }),
                              child: const Text(AppStrings.selectAll),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                for (final id in _carryOver.keys) {
                                  _carryOver[id] = false;
                                }
                              }),
                              child: const Text(AppStrings.clearAll),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ...widget.notFoundItems.map(
                      (item) => CheckboxListTile(
                        value: _carryOver[item.id] ?? false,
                        onChanged: (value) =>
                            setState(() => _carryOver[item.id] = value ?? false),
                        title: Text(item.name),
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                  if (widget.purchasedItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      '${AppStrings.purchasedItemsLabel} (${widget.purchasedItems.length})',
                      style: AppTextStyles.heading2.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    ...widget.purchasedItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '• ${item.name}',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(AppStrings.confirmFinishShopping, style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading1.copyWith(color: color ?? AppColors.textPrimary),
        ),
        Text(label, style: AppTextStyles.bodySecondary),
      ],
    );
  }
}

