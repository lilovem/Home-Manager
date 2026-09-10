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

/// מסך רשימת הקניות הראשי.
/// מציג את הפריטים בזמן אמת (StreamProvider), עם אפשרות
/// להוסיף/לערוך/למחוק/לשנות סטטוס - הכל מתעדכן מיידית אצל
/// כל חברי ה-household בזכות Firestore streams.
class ShoppingListScreen extends ConsumerWidget {
  final String householdId;

  const ShoppingListScreen({super.key, required this.householdId});

  Future<void> _openAddProduct(BuildContext context, WidgetRef ref, String listId) async {
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
    String listId,
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
    String listId,
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
    String listId,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listIdAsync = ref.watch(shoppingListIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.shoppingList)),
      body: listIdAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => const ErrorView(),
        data: (listId) {
          if (listId == null) return const LoadingIndicator();

          final itemsAsync = ref.watch(
            shoppingItemsProvider((householdId: householdId, listId: listId)),
          );

          return itemsAsync.when(
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
                                listId,
                                item,
                                item.status == ItemStatus.purchased
                                    ? ItemStatus.pending
                                    : ItemStatus.purchased,
                              ),
                              onMarkNotFound: () =>
                                  _setStatus(ref, listId, item, ItemStatus.notFound),
                              onBackToPending: () =>
                                  _setStatus(ref, listId, item, ItemStatus.pending),
                              onEdit: () => _openEditProduct(context, ref, listId, item),
                              onDelete: () => _confirmDelete(context, ref, listId, item),
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
          );
        },
      ),
      floatingActionButton: listIdAsync.maybeWhen(
        data: (listId) => listId == null
            ? null
            : FloatingActionButton(
                onPressed: () => _openAddProduct(context, ref, listId),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
        orElse: () => null,
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
      title: Text(
        item.name,
        style: AppTextStyles.body.copyWith(
          color: _statusColor,
          decoration:
              item.status == ItemStatus.purchased ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '$quantityText$unitText · ${AppStrings.addedByLabel} ${item.addedByName} · '
        '${DateFormatter.short(item.addedAt)}'
        '${item.status == ItemStatus.notFound ? ' · ${AppStrings.statusNotFound}' : ''}',
        style: AppTextStyles.bodySecondary,
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

