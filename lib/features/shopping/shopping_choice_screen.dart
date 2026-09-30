import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_provider.dart';
import 'existing_shopping_lists_screen.dart';
import 'import_shopping_list_screen.dart';
import 'new_shopping_calendar_screen.dart';
import 'shopping_list_screen.dart';

/// מסך הכניסה לרשימות קניות.
///
/// "קנייה נוכחית" (בחירה מתוך קיימות) מוצג רק אם יש בפועל לפחות
/// רשימה אחת עם מוצרים - אם אין שום קנייה נוכחית, לא מציגים בכלל
/// את האפשרות הזו (כדי לא להוביל למסך ריק ומבלבל). "קנייה חדשה"
/// (בחירת תאריך מלוח שנה) מוצג תמיד. בנוסף, כפתור בסרגל העליון
/// מאפשר ליצור רשימה חדשה ישירות מטקסט מודבק (למשל מוואטסאפ),
/// בלי לעבור דרך לוח השנה.
class ShoppingChoiceScreen extends ConsumerWidget {
  final String householdId;

  const ShoppingChoiceScreen({super.key, required this.householdId});

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
    final lists = ref.watch(shoppingListsProvider(householdId)).value ?? const [];
    // "יש קנייה נוכחית" - לפחות רשימה אחת עם בפועל לפחות מוצר אחד
    // (אותו תנאי בדיוק כמו הסינון במסך ExistingShoppingListsScreen,
    // כדי ששתי הבדיקות תמיד יתאימו זו לזו).
    final hasNonEmptyList = lists.any((list) {
      final items = ref
              .watch(shoppingItemsProvider((householdId: householdId, listId: list.id)))
              .value ??
          const [];
      return items.isNotEmpty;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.shoppingList),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste_go),
            tooltip: AppStrings.importNewListTooltip,
            onPressed: () => _openImportNewList(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasNonEmptyList) ...[
              _ChoiceCard(
                icon: Icons.shopping_cart,
                title: AppStrings.currentShoppingOption,
                subtitle: AppStrings.currentShoppingSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExistingShoppingListsScreen(householdId: householdId),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _ChoiceCard(
              icon: Icons.calendar_month,
              title: AppStrings.newShoppingOption,
              subtitle: AppStrings.newShoppingSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewShoppingCalendarScreen(householdId: householdId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading2),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

