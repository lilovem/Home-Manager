import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
import 'import_shopping_list_screen.dart';
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
///
/// הוספת מוצרים אפשרית בשתי דרכים: הוספה ידנית (מוצר אחד בכל
/// פעם, טופס מלא) או ייבוא רשימה שלמה מטקסט מודבק (למשל מוואטסאפ) -
/// שתיהן נפתחות מאותו כפתור הוספה (FAB), דרך חלונית בחירה קטנה.
///
/// כל קטגוריה שכל הפריטים בה כבר טופלו (נקנו או סומנו כלא נמצאו)
/// מקבלת וי ירוק ומתכווצת אוטומטית לשורת כותרת בלבד - אפשר ללחוץ
/// עליה כדי לפתוח מחדש ולהציץ. זה מצב תצוגה בלבד (לא נשמר ב-
/// Firestore), ולכן ConsumerStatefulWidget ולא ConsumerWidget.
class ShoppingListScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String listId;

  const ShoppingListScreen({
    super.key,
    required this.householdId,
    required this.listId,
  });

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  /// קטגוריות "שלמות" (וי ירוק) שהמשתמש/ת בחרו לפתוח מחדש כדי
  /// להציץ. בלי זה, קטגוריה שלמה תמיד מכווצת אוטומטית. קטגוריה
  /// שעדיין לא שלמה (יש בה פריט ממתין) תמיד מוצגת פתוחה.
  final Set<ProductCategory> _expandedOverride = {};

  Future<void> _confirmDeleteList(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.confirmDeleteListTitle),
        content: const Text(AppStrings.confirmDeleteListMessage),
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

    try {
      await ref.read(shoppingRepositoryProvider).deleteList(
            householdId: widget.householdId,
            listId: widget.listId,
          );
      if (context.mounted) Navigator.of(context).pop();
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

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
            householdId: widget.householdId,
            listId: widget.listId,
            name: result.name,
            quantity: result.quantity,
            unit: result.unit,
            addedBy: user.uid,
            addedByName: user.displayName ?? user.email ?? '',
            addedDuringShopping: isSessionActive,
            note: result.note,
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openImportList(
    BuildContext context,
    WidgetRef ref,
    bool isSessionActive,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportShoppingListScreen(
          title: AppStrings.importScreenTitle,
          onConfirm: (importContext, drafts) async {
            final user = ref.read(authStateChangesProvider).value;
            if (user == null) return;

            await ref.read(shoppingRepositoryProvider).addItemsBatch(
                  householdId: widget.householdId,
                  listId: widget.listId,
                  items: drafts,
                  addedBy: user.uid,
                  addedByName: user.displayName ?? user.email ?? '',
                  addedDuringShopping: isSessionActive,
                );

            if (importContext.mounted) Navigator.of(importContext).pop();
          },
        ),
      ),
    );
  }

  void _showAddOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    bool isSessionActive,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.primary),
              title: const Text(AppStrings.addManuallyAction),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openAddProduct(context, ref, isSessionActive);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste_go, color: AppColors.primary),
              title: const Text(AppStrings.importFromTextAction),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openImportList(context, ref, isSessionActive);
              },
            ),
          ],
        ),
      ),
    );
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
            householdId: widget.householdId,
            listId: widget.listId,
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
          householdId: widget.householdId,
          listId: widget.listId,
          itemId: item.id,
        );
  }

  Future<void> _setStatus(
    WidgetRef ref,
    ShoppingItem item,
    ItemStatus status,
  ) {
    return ref.read(shoppingRepositoryProvider).updateStatus(
          householdId: widget.householdId,
          listId: widget.listId,
          itemId: item.id,
          status: status,
        );
  }

  Future<void> _startShopping(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    try {
      await ref.read(shoppingRepositoryProvider).startShoppingSession(
            householdId: widget.householdId,
            listId: widget.listId,
            startedBy: user.uid,
            startedByName: user.displayName ?? user.email ?? '',
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
          householdId: widget.householdId,
          listId: widget.listId,
          purchasedItems: purchasedItems,
          notFoundItems: notFoundItems,
          totalItemsCount: items.length,
          activeSessionId: activeSessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync =
        ref.watch(shoppingItemsProvider((householdId: widget.householdId, listId: widget.listId)));
    final currentItems = itemsAsync.value;

    final listMetaAsync = ref
        .watch(shoppingListMetaProvider((householdId: widget.householdId, listId: widget.listId)));
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
                builder: (_) => ShoppingHistoryScreen(householdId: widget.householdId),
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: AppStrings.deleteListTooltip,
            onPressed: () => _confirmDeleteList(context, ref),
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

                // מנקים "פתיחות מחדש" של קטגוריות שכבר לא שלמות (נוסף
                // להן מוצר חדש שממתין, למשל מייבוא) - כך שבפעם הבאה
                // שהן יושלמו הן יתכווצו מחדש אוטומטית, בלי להישאר
                // פתוחות בטעות בגלל מצב ישן.
                _expandedOverride.removeWhere((category) {
                  final categoryItems = itemsByCategory[category];
                  return categoryItems == null ||
                      categoryItems.any((item) => item.status == ItemStatus.pending);
                });

                // SlidableAutoCloseBehavior דואג שכשמחליקים פריט אחד ונפתחות
                // הפעולות שלו (מחיקה/עריכה/סימון כלא נמצא), כל פריט אחר
                // שהיה פתוח נסגר אוטומטית - אף פעם לא שני פריטים פתוחים
                // בו-זמנית.
                return SlidableAutoCloseBehavior(
                  child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: categoriesToShow.length,
                  itemBuilder: (context, categoryIndex) {
                    final category = categoriesToShow[categoryIndex];
                    final categoryItems = itemsByCategory[category]!;
                    final isComplete =
                        categoryItems.every((item) => item.status != ItemStatus.pending);
                    final isCollapsed = isComplete && !_expandedOverride.contains(category);
                    final categoryColor =
                        ProductCategorizer.categoryColors[category] ?? AppColors.primary;

                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CategoryHeader(
                            category: category,
                            categoryColor: categoryColor,
                            isComplete: isComplete,
                            isCollapsed: isCollapsed,
                            onTap: isComplete
                                ? () => setState(() {
                                      if (_expandedOverride.contains(category)) {
                                        _expandedOverride.remove(category);
                                      } else {
                                        _expandedOverride.add(category);
                                      }
                                    })
                                : null,
                          ),
                          if (!isCollapsed)
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptionsSheet(context, ref, isSessionActive),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final ProductCategory category;
  final Color categoryColor;
  final bool isComplete;
  final bool isCollapsed;
  final VoidCallback? onTap;

  const _CategoryHeader({
    required this.category,
    required this.categoryColor,
    required this.isComplete,
    required this.isCollapsed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // כל כותרת הקטגוריה (לרוחב מלא של המסך) צבועה בצבע הקטגוריה
    // עצמה, אותו צבע כמו העיגול הקטן ליד כל מוצר - כדי שההפרדה בין
    // קטגוריה לקטגוריה תהיה בולטת וברורה, לא רק קו דק.
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: categoryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ProductCategorizer.categoryNames[category] ?? '',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isComplete) ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              Icon(
                isCollapsed ? Icons.expand_more : Icons.expand_less,
                color: Colors.white,
                size: 20,
              ),
            ],
          ],
        ),
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

    // פעולת "לא נמצא"/"החזר לממתין" מתחלפת לפי הסטטוס הנוכחי - רק
    // אחת מהן רלוונטית בכל רגע נתון (בדיוק כמו בתפריט הישן). flex
    // גבוה יותר כי הטקסט שלה ("לא נמצא" / "החזר לממתין") ארוך יותר
    // מ"עריכה"/"מחיקה".
    final statusAction = item.status == ItemStatus.pending
        ? _SwipeAction(
            flex: 2,
            onPressed: onMarkNotFound,
            backgroundColor: AppColors.itemNotFound,
            icon: Icons.search_off,
            label: AppStrings.markNotFound,
          )
        : _SwipeAction(
            flex: 2,
            onPressed: onBackToPending,
            backgroundColor: AppColors.primary,
            icon: Icons.undo,
            label: AppStrings.backToPending,
          );

    return Slidable(
      key: ValueKey(item.id),
      // "end" מתאים אוטומטית לכיוון RTL - בעברית זה נחשף מצד שמאל.
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.85,
        children: [
          statusAction,
          _SwipeAction(
            onPressed: onEdit,
            backgroundColor: AppColors.primary,
            icon: Icons.edit,
            label: AppStrings.edit,
          ),
          _SwipeAction(
            onPressed: onDelete,
            backgroundColor: AppColors.error,
            icon: Icons.delete,
            label: AppStrings.delete,
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(
          value: item.status == ItemStatus.purchased,
          activeColor: AppColors.itemPurchased,
          onChanged: (_) => onTogglePurchased(),
        ),
        title: Row(
          children: [
            Builder(builder: (context) {
              final emoji = ProductCategorizer.productEmoji(item.name);
              if (emoji != null) {
                return Text(emoji, style: const TextStyle(fontSize: 20));
              }
              return Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: ProductCategorizer.categoryColors[item.category],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ProductCategorizer.categoryIcons[item.category],
                  size: 15,
                  color: Colors.white,
                ),
              );
            }),
            const SizedBox(width: 8),
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
      ),
    );
  }
}

/// כפתור פעולת החלקה בודד - בנוי ידנית (CustomSlidableAction) ולא
/// עם SlidableAction הרגיל, כדי שהטקסט המלא ("לא נמצא", "החזר
/// לממתין" וכו') תמיד יוצג במלואו ולא ייחתך - אם אין מספיק רוחב,
/// הטקסט עובר לשורה שנייה במקום להיקטע.
class _SwipeAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final int flex;

  const _SwipeAction({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      flex: flex,
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      onPressed: (_) => onPressed(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.white, height: 1.1),
          ),
        ],
      ),
    );
  }
}
