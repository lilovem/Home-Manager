import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failures.dart';
import '../models/household_model.dart';
import '../models/shopping_history_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../services/firebase/shopping_service.dart';

class ShoppingRepository {
  final ShoppingService _service;

  ShoppingRepository(this._service);

  Future<String> getOrCreateDefaultListId(Household household) {
    return _service.getOrCreateDefaultListId(household);
  }

  Future<void> deleteList({required String householdId, required String listId}) async {
    try {
      await _service.deleteList(householdId: householdId, listId: listId);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה במחיקת הרשימה');
    }
  }

  Stream<List<ShoppingList>> watchLists(String householdId) {
    return _service.watchLists(householdId);
  }

  Future<ShoppingList> createList({
    required String householdId,
    required String name,
    DateTime? date,
  }) async {
    try {
      return await _service.createList(householdId: householdId, name: name, date: date);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה ביצירת הרשימה');
    }
  }

  Stream<ShoppingList> watchListMeta(String householdId, String listId) {
    return _service.watchListMeta(householdId, listId);
  }

  Future<void> startShoppingSession({
    required String householdId,
    required String listId,
    required String startedBy,
    required String startedByName,
  }) async {
    try {
      await _service.startShoppingSession(
        householdId: householdId,
        listId: listId,
        startedBy: startedBy,
        startedByName: startedByName,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בהתחלת הקנייה');
    }
  }

  Stream<List<ShoppingItem>> watchItems(String householdId, String listId) {
    return _service.watchItems(householdId, listId);
  }

  Future<void> addItem({
    required String householdId,
    required String listId,
    required String name,
    required double quantity,
    String? unit,
    required String addedBy,
    required String addedByName,
    bool addedDuringShopping = false,
    String? note,
  }) async {
    try {
      await _service.addItem(
        householdId: householdId,
        listId: listId,
        name: name,
        quantity: quantity,
        unit: unit,
        addedBy: addedBy,
        addedByName: addedByName,
        addedDuringShopping: addedDuringShopping,
        note: note,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בהוספת המוצר');
    }
  }

  Future<void> updateItem({
    required String householdId,
    required String listId,
    required String itemId,
    String? name,
    double? quantity,
    String? unit,
    String? note,
  }) async {
    try {
      await _service.updateItem(
        householdId: householdId,
        listId: listId,
        itemId: itemId,
        name: name,
        quantity: quantity,
        unit: unit,
        note: note,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בעדכון המוצר');
    }
  }

  Future<void> updateStatus({
    required String householdId,
    required String listId,
    required String itemId,
    required ItemStatus status,
  }) async {
    try {
      await _service.updateStatus(
        householdId: householdId,
        listId: listId,
        itemId: itemId,
        status: status,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בעדכון הסטטוס');
    }
  }

  Future<void> deleteItem({
    required String householdId,
    required String listId,
    required String itemId,
  }) async {
    try {
      await _service.deleteItem(
        householdId: householdId,
        listId: listId,
        itemId: itemId,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה במחיקת המוצר');
    }
  }

  Future<void> finishShopping({
    required String householdId,
    required String listId,
    required List<ShoppingItem> purchasedItems,
    required List<ShoppingItem> notFoundItemsToCarryOver,
    required List<ShoppingItem> notFoundItemsToDrop,
    required int totalItemsCount,
    required String completedBy,
    required String completedByName,
    String? activeSessionId,
  }) async {
    try {
      await _service.finishShopping(
        householdId: householdId,
        listId: listId,
        purchasedItems: purchasedItems,
        notFoundItemsToCarryOver: notFoundItemsToCarryOver,
        notFoundItemsToDrop: notFoundItemsToDrop,
        totalItemsCount: totalItemsCount,
        completedBy: completedBy,
        completedByName: completedByName,
        activeSessionId: activeSessionId,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בסיום הקנייה');
    }
  }

  Stream<List<ShoppingHistoryEntry>> watchHistory(String householdId) {
    return _service.watchHistory(householdId);
  }
}

