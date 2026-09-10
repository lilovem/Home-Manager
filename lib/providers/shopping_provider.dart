import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_item_model.dart';
import '../repositories/shopping_repository.dart';
import '../services/firebase/shopping_service.dart';
import 'household_provider.dart';

final shoppingServiceProvider = Provider<ShoppingService>((ref) {
  return ShoppingService(ref.watch(firestoreProvider));
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(shoppingServiceProvider));
});

/// מזהה רשימת הקניות של ה-household הנוכחי - נוצר אוטומטית אם עדיין
/// לא קיים (households שנוצרו לפני שהרשימה נתמכה).
final shoppingListIdProvider = FutureProvider<String?>((ref) async {
  final household = ref.watch(myHouseholdProvider).value;
  if (household == null) return null;
  return ref.watch(shoppingRepositoryProvider).getOrCreateDefaultListId(household);
});

/// פרמטרים ל-watch של פריטי רשימה מסוימת.
typedef ShoppingItemsArgs = ({String householdId, String listId});

final shoppingItemsProvider =
    StreamProvider.family<List<ShoppingItem>, ShoppingItemsArgs>((ref, args) {
  return ref
      .watch(shoppingRepositoryProvider)
      .watchItems(args.householdId, args.listId);
});

