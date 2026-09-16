import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_history_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../repositories/shopping_repository.dart';
import '../services/firebase/shopping_service.dart';
import 'household_provider.dart';

final shoppingServiceProvider = Provider<ShoppingService>((ref) {
  return ShoppingService(ref.watch(firestoreProvider));
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(shoppingServiceProvider));
});

/// כל רשימות הקניות של household מסוים.
final shoppingListsProvider =
    StreamProvider.family<List<ShoppingList>, String>((ref, householdId) {
  return ref.watch(shoppingRepositoryProvider).watchLists(householdId);
});

/// מזהה הרשימה שיש לה כרגע session פעיל (אם יש) - בין כל הרשימות
/// של ה-household. משמש להאזנת התראות גלובלית (ShoppingNotificationsListener)
/// בלי לדעת מראש איזו רשימה ספציפית פעילה.
final activeSessionListIdProvider =
    Provider.family<String?, String>((ref, householdId) {
  final lists = ref.watch(shoppingListsProvider(householdId)).value ?? [];
  for (final list in lists) {
    if (list.activeSessionId != null) return list.id;
  }
  return null;
});

/// סך כל הפריטים ה"ממתינים" (עוד לא נקנו) בכל רשימות ה-household
/// יחד - משמש לתג המספר בכרטיסיית "קניות" ב-Dashboard.
final totalPendingItemsCountProvider = Provider.family<int, String>((ref, householdId) {
  final lists = ref.watch(shoppingListsProvider(householdId)).value ?? [];
  var count = 0;
  for (final list in lists) {
    final items =
        ref.watch(shoppingItemsProvider((householdId: householdId, listId: list.id))).value ??
            const [];
    count += items.where((i) => i.status == ItemStatus.pending).length;
  }
  return count;
});

/// רשימות קניות עם תאריך עתידי (או היום) **שיש בהן בפועל מוצרים**,
/// ממוינות מהקרוב לרחוק - משמש לתג המספר בכרטיסיית "לוח שנה"
/// ב-Dashboard ולכרטיס לוח השנה. רשימות ריקות (למשל שאריות
/// מבדיקות ישנות) לא נספרות/מוצגות.
final upcomingShoppingDatesProvider =
    Provider.family<List<ShoppingList>, String>((ref, householdId) {
  final lists = ref.watch(shoppingListsProvider(householdId)).value ?? [];
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);

  final upcoming = lists.where((l) {
    if (l.date == null || l.date!.isBefore(todayStart)) return false;
    final items =
        ref.watch(shoppingItemsProvider((householdId: householdId, listId: l.id))).value ??
            const [];
    return items.isNotEmpty;
  }).toList();

  upcoming.sort((a, b) => a.date!.compareTo(b.date!));
  return upcoming;
});

/// פרמטרים ל-watch של פריטי רשימה מסוימת.
typedef ShoppingItemsArgs = ({String householdId, String listId});

final shoppingItemsProvider =
    StreamProvider.family<List<ShoppingItem>, ShoppingItemsArgs>((ref, args) {
  return ref
      .watch(shoppingRepositoryProvider)
      .watchItems(args.householdId, args.listId);
});

/// היסטוריית קניות של household מסוים.
final shoppingHistoryProvider =
    StreamProvider.family<List<ShoppingHistoryEntry>, String>((ref, householdId) {
  return ref.watch(shoppingRepositoryProvider).watchHistory(householdId);
});

/// מידע חי על הרשימה עצמה (כולל activeSessionId) - כדי שכל
/// חברי ה-household יראו מיידית כשקנייה פעילה מתחילה/מסתיימת.
final shoppingListMetaProvider =
    StreamProvider.family<ShoppingList, ShoppingItemsArgs>((ref, args) {
  return ref
      .watch(shoppingRepositoryProvider)
      .watchListMeta(args.householdId, args.listId);
});

