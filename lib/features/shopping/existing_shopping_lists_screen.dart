import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_provider.dart';
import 'import_shopping_list_screen.dart';
import 'shopping_list_screen.dart';

/// מסך "קנייה נוכחית" - רשימת כל הקניות הקיימות של ה-household,
/// לבחירה. יצירת קנייה חדשה "ריקה" נעשית דרך המסך השני
/// (NewShoppingCalendarScreen), ויצירת רשימה חדשה **מייבוא טקסט
/// מודבק** (למשל מוואטסאפ) אפשרית ישירות מכאן, דרך כפתור בסרגל
/// העליון.
class ExistingShoppingListsScreen extends ConsumerWidget {
  final String householdId;

  const ExistingShoppingListsScreen({super.key, required this.householdId});

  Future<void> _openImportNewList(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportShoppingListScreen(
          title: AppStrings.importScreenTitle,
          onConfirm: (importContext, drafts) async {
            final user = ref.read(authStateChangesProvider).value;
            if (user == null) return;

            final newList = await ref.read(shoppingRepositoryProvider).createList(
                  householdId: householdId,
                  name: DateFormatter.dateOnly(DateTime.now()),
                );

            await ref.read(shoppingRepositoryProvider).addItemsBatch(
                  householdId: householdId,
                  listId: newList.id,
                  items: drafts,
                  addedBy: user.uid,
                  addedByName: user.email ?? '',
                );

            if (importContext.mounted) {
              Navigator.of(importContext).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ShoppingListScreen(
                    householdId: householdId,
                    listId: newList.id,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(shoppingListsProvider(householdId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.currentShoppingOption),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste_go),
            tooltip: AppStrings.importNewListTooltip,
            onPressed: () => _openImportNewList(context, ref),
          ),
        ],
      ),
      body: listsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => const ErrorView(),
        data: (lists) {
          // מציגים רק רשימות שיש בהן בפועל לפחות מוצר אחד - רשימות
          // ריקות (למשל שאריות ישנות מבדיקות) לא מבלבלות את הבחירה.
          final nonEmptyLists = lists.where((list) {
            final itemsAsync = ref.watch(
              shoppingItemsProvider((householdId: householdId, listId: list.id)),
            );
            return (itemsAsync.value ?? const []).isNotEmpty;
          }).toList();

          if (nonEmptyLists.isEmpty) {
            return const EmptyState(
              message: AppStrings.noListsYet,
              icon: Icons.shopping_cart_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: nonEmptyLists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final list = nonEmptyLists[index];
              final isActive = list.activeSessionId != null;

              return ListTile(
                leading: Icon(
                  Icons.shopping_cart,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(list.name),
                subtitle: (list.date != null &&
                        list.name != DateFormatter.dateOnly(list.date))
                    ? Text(DateFormatter.dateOnly(list.date), style: AppTextStyles.bodySecondary)
                    : null,
                trailing: isActive
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          AppStrings.activeSessionBadge,
                          style: TextStyle(color: AppColors.primary, fontSize: 11),
                        ),
                      )
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShoppingListScreen(householdId: householdId, listId: list.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

