import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../models/shopping_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/shopping_provider.dart';

/// עוטף את כל האפליקציה (אחרי שיש household) כדי שההאזנה להתראות
/// תפעל תמיד - לא משנה איזה מסך פתוח כרגע (Dashboard, רשימת קניות,
/// היסטוריה וכו'). בלי זה, ה-listener היה קיים רק כשמסך רשימת
/// הקניות עצמו היה על המסך, ולא היה מתריע אם המשתמש היה במקום אחר
/// באפליקציה.
///
/// לא מרנדר שום UI משלו - רק "יושב" בעץ הווידג'טים ומאזין.
class ShoppingNotificationsListener extends ConsumerWidget {
  final String householdId;
  final Widget child;

  const ShoppingNotificationsListener({
    super.key,
    required this.householdId,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeListId = ref.watch(activeSessionListIdProvider(householdId));
    final myUid = ref.watch(authStateChangesProvider).value?.uid;
    final notificationService = ref.watch(browserNotificationServiceProvider);

    // מוצר חדש שנוסף על ידי מישהו אחר בזמן קנייה פעילה - רק אם יש
    // כרגע רשימה כלשהי עם session פעיל (activeListId מחושב אוטומטית
    // מבין כל הרשימות של ה-household, ראה activeSessionListIdProvider).
    if (activeListId != null) {
      ref.listen(
        shoppingItemsProvider((householdId: householdId, listId: activeListId)),
        (previous, next) {
          if (previous == null) return;
          final prevIds = (previous.value ?? []).map((e) => e.id).toSet();
          for (final item in next.value ?? <ShoppingItem>[]) {
            if (!prevIds.contains(item.id) &&
                item.addedDuringShopping &&
                item.addedBy != myUid) {
              notificationService.show(
                title: AppStrings.newItemNotificationTitle,
                body: '${item.name} · ${AppStrings.addedByLabel} ${item.addedByName}',
              );
            }
          }
        },
      );
    }

    // קנייה שהסתיימה על ידי מישהו אחר - לא תלוי ברשימה ספציפית,
    // תמיד מאזין להיסטוריה הכללית של ה-household.
    ref.listen(
      shoppingHistoryProvider(householdId),
      (previous, next) {
        if (previous == null) return;
        final prevIds = (previous.value ?? []).map((e) => e.id).toSet();
        for (final entry in next.value ?? []) {
          if (!prevIds.contains(entry.id) && entry.completedBy != myUid) {
            final body = entry.notFoundItemNames.isEmpty
                ? null
                : '${AppStrings.notFoundNotificationBody}: ${entry.notFoundItemNames.join(", ")}';
            notificationService.show(
              title: AppStrings.shoppingDoneNotificationTitle,
              body: body,
            );
          }
        }
      },
    );

    return child;
  }
}

