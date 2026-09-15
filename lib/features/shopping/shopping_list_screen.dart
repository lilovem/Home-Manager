import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/product_categorizer.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../models/shopping_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_provider.dart';
import 'add_edit_product_screen.dart';
import 'shopping_history_screen.dart';
import 'shopping_summary_screen.dart';

/// מסך רשימת קניות ספציפית (יש כמה רשימות אפשריות ל-household,
/// זו מציגה תמיד רשימה אחת מסוימת לפי listId).
///
/// מציג את הפריטים בזמן אמת (StreamProvider), עם אפשרות
/// להוסיף/לערוך/למחוק/לשנות סטטוס - הכל מתעדכן מיידית אצל
/// כל חברי ה-household בזכות Firestore streams.
///
/// כולל גם מצב "קנייה פעילה": כשמישהו לוחץ "התחל קנייה", מוצג
/// באנר לכל חברי ה-household, וכל מוצר שנוסף בזמן הזה מסומן
/// "חדש" (addedDuringShopping). "סיום קנייה" סוגר את ה-session.
class ShoppingListScreen extends ConsumerWidget {
  final String householdId;
  final String listId;

  const ShoppingListScreen({
    super.key,
    required this.householdId,
    required this.listId,
  });

  Future<void> _openAddProduct(
    BuildContext context,
    WidgetRef ref,
    bool isSessionActive,
  ) async {
    final result = await Navigator.of(context).push<ProductFormResult>(
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    );
    if (result == null) return;

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    try {
      await ref.read(shoppingRepositoryProvider).addItem(
            householdId: householdId,
            listId: listId,
            name: result.name,
            quantity: result.quantity,
            unit: result.unit,
            addedBy: user.uid,
            addedByName: user.email ?? '',
            addedDuringShopping: isSessionActive,
            note: result.note,
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openEditProduct(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item,
  ) async {
    final result = await Navigator.of(context).push<ProductFormResult>(
      MaterialPageRoute(builder: (_) => AddEditProductScreen(existingItem: item)),
    );
    if (result == null) return;

    try {
      await ref.read(shoppingRepositoryProvider).updateItem(
            householdId: householdId,
            listId: listId,
            itemId: item.id,
            name: result.name,
            quantity: result.quantity,
            unit: result.unit,
            note: result.note,
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.confirmDeleteTitle),
        content: Text('"${item.name}" - ${AppStrings.confirmDeleteMessage}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(shoppingRepositoryProvider).deleteItem(
          householdId: householdId,
          listId: listId,
          itemId: item.id,
        );
  }

  Future<void> _setStatus(
    WidgetRef ref,
    ShoppingItem item,
    ItemStatus status,
  ) {
    return ref.read(shoppingRepositoryProvider).updateStatus(
          householdId: householdId,
          listId: listId,
          itemId: item.id,
          status: status,
        );
  }

  Future<void> _startShopping(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    try {
      await ref.read(shoppingRepositoryProvider).startShoppingSession(
            householdId: householdId,
            listId: listId,
            startedBy: user.uid,
            startedByName: user.email ?? '',
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openFinishShopping(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingItem> items,
    String? activeSessionId,
  ) async {
    final purchasedItems = items.where((i) => i.status == ItemStatus.purchased).toList();
    final notFoundItems = items.where((i) => i.status == ItemStatus.notFound).toList();

    if (purchasedItems.isEmpty && notFoundItems.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.nothingToFinish)));
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingSummaryScreen(
          householdId: householdId,
          listId: listId,
          purchasedItems: purchasedItems,
          notFoundItems: notFoundItems,
          totalItemsCount: items.length,
          activeSessionId: activeSessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingItemsProvider((householdId: householdId, listId: listId)));
    final currentItems = itemsAsync.value;

    final listMetaAsync =
        ref.watch(shoppingListMetaProvider((householdId: householdId, listId: listId)));
    final activeSessionId = listMetaAsync.value?.activeSessionId;
    final isSessionActive = activeSessionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(listMetaAsync.value?.name ?? AppStrings.shoppingList),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppStrings.shoppingHistory,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoppingHistoryScreen(householdId: householdId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: AppStrings.finishShopping,
            onPressed: currentItems == null
                ? null
                : () => _openFinishShopping(context, ref, currentItems, activeSessionId),
          ),
        ],
      ),
      body: Column(
        children: [
          // באנר קנייה פעילה / כפתור התחלת קנייה.
          isSessionActive
              ? Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.activeShoppingBanner,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: OutlinedButton.icon(
                    onPressed: () => _startShopping(context, ref),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(AppStrings.startShopping),
                  ),
                ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, st) => const ErrorView(),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    message: AppStrings.noItemsYet,
                    icon: Icons.shopping_cart_outlined,
                  );
                }

                // קיבוץ הפריטים לפי קטגוריה, בסדר תצוגה קבוע.
                // קטגוריה מוצגת רק אם יש בה לפחות פריט אחד.
                final itemsByCategory = <ProductCategory, List<ShoppingItem>>{};
                for (final item in items) {
                  itemsByCategory.putIfAbsent(item.category, () => []).add(item);
                }
                final categoriesToShow = ProductCategorizer.displayOrder
                    .where((category) => itemsByCategory.containsKey(category))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: categoriesToShow.length,
                  itemBuilder: (context, categoryIndex) {
                    final category = categoriesToShow[categoryIndex];
                    final categoryItems = itemsByCategory[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryHeader(category: category),
                        ...categoryItems.map(
                          (item) => Column(
                            children: [
                              _ShoppingItemTile(
                                item: item,
                                onTogglePurchased: () => _setStatus(
                                  ref,
                                  item,
                                  item.status == ItemStatus.purchased
                                      ? ItemStatus.pending
                                      : ItemStatus.purchased,
                                ),
                                onMarkNotFound: () =>
                                    _setStatus(ref, item, ItemStatus.notFound),
                                onBackToPending: () =>
                                    _setStatus(ref, item, ItemStatus.pending),
                                onEdit: () => _openEditProduct(context, ref, item),
                                onDelete: () => _confirmDelete(context, ref, item),
                              ),
                              const Divider(height: 1),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddProduct(context, ref, isSessionActive),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final ProductCategory category;

  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        ProductCategorizer.categoryNames[category] ?? '',
        style: AppTextStyles.heading2.copyWith(fontSize: 14, color: AppColors.primary),
      ),
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onTogglePurchased;
  final VoidCallback onMarkNotFound;
  final VoidCallback onBackToPending;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShoppingItemTile({
    required this.item,
    required this.onTogglePurchased,
    required this.onMarkNotFound,
    required this.onBackToPending,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (item.status) {
      case ItemStatus.purchased:
        return AppColors.itemPurchased;
      case ItemStatus.notFound:
        return AppColors.itemNotFound;
      case ItemStatus.pending:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantityText = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.round().toString()
        : item.quantity.toString();
    final unitText = item.unit != null ? ' ${item.unit}' : '';

    return ListTile(
      leading: Checkbox(
        value: item.status == ItemStatus.purchased,
        activeColor: AppColors.itemPurchased,
        onChanged: (_) => onTogglePurchased(),
      ),
      title: Row(
        children: [
          Icon(
            ProductCategorizer.categoryIcons[item.category],
            size: 18,
            color: _statusColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              item.name,
              style: AppTextStyles.body.copyWith(
                color: _statusColor,
                decoration:
                    item.status == ItemStatus.purchased ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (item.addedDuringShopping && item.status == ItemStatus.pending) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.itemNewBadge,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppStrings.newBadge,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$quantityText$unitText · ${AppStrings.addedByLabel} ${item.addedByName} · '
            '${DateFormatter.short(item.addedAt)}'
            '${item.status == ItemStatus.notFound ? ' · ${AppStrings.statusNotFound}' : ''}',
            style: AppTextStyles.bodySecondary,
          ),
          if (item.note != null && item.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.note!,
                style: AppTextStyles.bodySecondary.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'notFound':
              onMarkNotFound();
              break;
            case 'backToPending':
              onBackToPending();
              break;
            case 'edit':
              onEdit();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          if (item.status != ItemStatus.notFound)
            const PopupMenuItem(value: 'notFound', child: Text(AppStrings.markNotFound)),
          if (item.status != ItemStatus.pending)
            const PopupMenuItem(value: 'backToPending', child: Text(AppStrings.backToPending)),
          const PopupMenuItem(value: 'edit', child: Text(AppStrings.edit)),
          const PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
        ],
      ),
    );
  }
}

