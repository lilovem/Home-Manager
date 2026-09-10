import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/household_model.dart';
import '../../models/shopping_history_model.dart';
import '../../models/shopping_item_model.dart';
import '../../models/shopping_list_model.dart';

/// עטיפה דקה סביב קריאות Firestore הקשורות לרשימת קניות.
class ShoppingService {
  final FirebaseFirestore _firestore;

  ShoppingService(this._firestore);

  DocumentReference<Map<String, dynamic>> _householdDoc(String householdId) =>
      _firestore.collection('households').doc(householdId);

  CollectionReference<Map<String, dynamic>> _listsCollection(String householdId) =>
      _householdDoc(householdId).collection('shoppingLists');

  CollectionReference<Map<String, dynamic>> _itemsCollection(
    String householdId,
    String listId,
  ) =>
      _listsCollection(householdId).doc(listId).collection('items');

  CollectionReference<Map<String, dynamic>> _historyCollection(String householdId) =>
      _householdDoc(householdId).collection('shoppingHistory');

  /// מחזיר את מזהה רשימת הקניות של ה-household.
  /// אם עדיין אין לו רשימה (households שנוצרו לפני שלב זה), יוצר
  /// אחת חדשה ושומר את המזהה שלה על מסמך ה-household.
  Future<String> getOrCreateDefaultListId(Household household) async {
    if (household.shoppingListId != null) {
      return household.shoppingListId!;
    }

    final listRef = await _listsCollection(household.id).add(
      ShoppingList.toFirestoreForCreate('קניות שבועיות'),
    );

    await _householdDoc(household.id).update({
      'shoppingListId': listRef.id,
    });

    return listRef.id;
  }

  Stream<List<ShoppingItem>> watchItems(String householdId, String listId) {
    return _itemsCollection(householdId, listId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingItem.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> addItem({
    required String householdId,
    required String listId,
    required String name,
    required double quantity,
    String? unit,
    required String addedBy,
    required String addedByName,
  }) {
    return _itemsCollection(householdId, listId).add(
      ShoppingItem.toFirestoreForCreate(
        name: name,
        quantity: quantity,
        unit: unit,
        addedBy: addedBy,
        addedByName: addedByName,
      ),
    );
  }

  Future<void> updateItem({
    required String householdId,
    required String listId,
    required String itemId,
    String? name,
    double? quantity,
    String? unit,
  }) {
    final data = ShoppingItem(
      id: itemId,
      name: '',
      quantity: 0,
      status: ItemStatus.pending,
      addedBy: '',
      addedByName: '',
      addedAt: null,
    ).toFirestoreForUpdate(name: name, quantity: quantity, unit: unit);

    return _itemsCollection(householdId, listId).doc(itemId).update(data);
  }

  Future<void> updateStatus({
    required String householdId,
    required String listId,
    required String itemId,
    required ItemStatus status,
  }) {
    return _itemsCollection(householdId, listId)
        .doc(itemId)
        .update(ShoppingItem.statusUpdate(status));
  }

  Future<void> deleteItem({
    required String householdId,
    required String listId,
    required String itemId,
  }) {
    return _itemsCollection(householdId, listId).doc(itemId).delete();
  }

  /// מסיים קנייה: מוחק את כל הפריטים שנקנו, מטפל בפריטים שלא נמצאו
  /// (מעביר חזרה ל"ממתין" את אלה שנבחרו, מוחק את השאר), ושומר
  /// רשומת סיכום בהיסטוריה - הכל בפעולה אטומית אחת (WriteBatch).
  Future<void> finishShopping({
    required String householdId,
    required String listId,
    required List<ShoppingItem> purchasedItems,
    required List<ShoppingItem> notFoundItemsToCarryOver,
    required List<ShoppingItem> notFoundItemsToDrop,
    required int totalItemsCount,
  }) async {
    final batch = _firestore.batch();
    final itemsRef = _itemsCollection(householdId, listId);

    for (final item in purchasedItems) {
      batch.delete(itemsRef.doc(item.id));
    }
    for (final item in notFoundItemsToDrop) {
      batch.delete(itemsRef.doc(item.id));
    }
    for (final item in notFoundItemsToCarryOver) {
      batch.update(itemsRef.doc(item.id), ShoppingItem.statusUpdate(ItemStatus.pending));
    }

    final historyRef = _historyCollection(householdId).doc();
    batch.set(
      historyRef,
      ShoppingHistoryEntry.toFirestoreForCreate(
        totalItems: totalItemsCount,
        purchasedCount: purchasedItems.length,
        notFoundCount: notFoundItemsToCarryOver.length + notFoundItemsToDrop.length,
        notFoundItemNames: [
          ...notFoundItemsToCarryOver.map((e) => e.name),
          ...notFoundItemsToDrop.map((e) => e.name),
        ],
      ),
    );

    await batch.commit();
  }

  Stream<List<ShoppingHistoryEntry>> watchHistory(String householdId) {
    return _historyCollection(householdId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingHistoryEntry.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}

