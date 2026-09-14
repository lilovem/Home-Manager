#!/bin/bash
set -e
cat > 'lib/models/shopping_item_model.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/product_categorizer.dart';

/// סטטוס של מוצר ברשימת הקניות.
enum ItemStatus { pending, purchased, notFound }

ItemStatus _statusFromString(String? value) {
  switch (value) {
    case 'purchased':
      return ItemStatus.purchased;
    case 'notFound':
      return ItemStatus.notFound;setup_notes_fix.sh flutter run
    default:
      return ItemStatus.pending;
  }
}

String _statusToString(ItemStatus status) {
  switch (status) {
    case ItemStatus.purchased:
      return 'purchased';
    case ItemStatus.notFound:
      return 'notFound';
    case ItemStatus.pending:
      return 'pending';
  }
}

/// מודל של מוצר ברשימת קניות.
///
/// `addedDuringShopping` כבר כלול כאן מראש (ברירת מחדל false) כדי
/// שהמבנה יהיה מוכן לשלב 7 (Active Shopping) בלי צורך במיגרציה.
class ShoppingItem {
  final String id;
  final String name;
  final double quantity;
  final String? unit;
  final ItemStatus status;
  final String addedBy;
  final String addedByName;
  final DateTime? addedAt;
  final bool addedDuringShopping;
  final DateTime? purchasedAt;
  final DateTime? notFoundAt;
  final String? note;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit,
    required this.status,
    required this.addedBy,
    required this.addedByName,
    required this.addedAt,
    this.addedDuringShopping = false,
    this.purchasedAt,
    this.notFoundAt,
    this.note,
  });

  /// הקטגוריה מחושבת תמיד מחדש משם המוצר - לא נשמרת ב-Firestore,
  /// כך שעריכת שם מוצר מעדכנת אוטומטית גם את הקטגוריה שלו.
  ProductCategory get category => ProductCategorizer.categorize(name);

  factory ShoppingItem.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingItem(
      id: id,
      name: data['name'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1,
      unit: data['unit'] as String?,
      status: _statusFromString(data['status'] as String?),
      addedBy: data['addedBy'] as String? ?? '',
      addedByName: data['addedByName'] as String? ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
      addedDuringShopping: data['addedDuringShopping'] as bool? ?? false,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
      notFoundAt: (data['notFoundAt'] as Timestamp?)?.toDate(),
      note: data['note'] as String?,
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required String name,
    required double quantity,
    String? unit,
    required String addedBy,
    required String addedByName,
    bool addedDuringShopping = false,
    String? note,
  }) {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'status': _statusToString(ItemStatus.pending),
      'addedBy': addedBy,
      'addedByName': addedByName,
      'addedAt': FieldValue.serverTimestamp(),
      'addedDuringShopping': addedDuringShopping,
      'purchasedAt': null,
      'notFoundAt': null,
      'note': note,
    };
  }

  Map<String, dynamic> toFirestoreForUpdate({
    String? name,
    double? quantity,
    String? unit,
    String? note,
  }) {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (quantity != null) map['quantity'] = quantity;
    if (unit != null) map['unit'] = unit;
    if (note != null) map['note'] = note;
    return map;
  }

  static Map<String, dynamic> statusUpdate(ItemStatus newStatus) {
    final map = <String, dynamic>{'status': _statusToString(newStatus)};
    switch (newStatus) {
      case ItemStatus.purchased:
        map['purchasedAt'] = FieldValue.serverTimestamp();
        map['notFoundAt'] = null;
        break;
      case ItemStatus.notFound:
        map['notFoundAt'] = FieldValue.serverTimestamp();
        map['purchasedAt'] = null;
        break;
      case ItemStatus.pending:
        map['purchasedAt'] = null;
        map['notFoundAt'] = null;
        break;
    }
    return map;
  }
}

HMEOF
cat > 'lib/services/firebase/shopping_service.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/household_model.dart';
import '../../models/shopping_history_model.dart';
import '../../models/shopping_item_model.dart';
import '../../models/shopping_list_model.dart';
import '../../models/shopping_session_model.dart';

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

  CollectionReference<Map<String, dynamic>> _sessionsCollection(
    String householdId,
    String listId,
  ) =>
      _listsCollection(householdId).doc(listId).collection('sessions');

  /// מאזין למידע של הרשימה עצמה (כולל activeSessionId) בזמן אמת -
  /// כך שכל חברי ה-household רואים מיידית אם קנייה פעילה החלה/הסתיימה.
  Stream<ShoppingList> watchListMeta(String householdId, String listId) {
    return _listsCollection(householdId).doc(listId).snapshots().map(
          (doc) => ShoppingList.fromFirestore(doc.id, doc.data() ?? {}),
        );
  }

  Future<void> startShoppingSession({
    required String householdId,
    required String listId,
    required String startedBy,
    required String startedByName,
  }) async {
    final sessionRef = _sessionsCollection(householdId, listId).doc();
    await sessionRef.set(
      ShoppingSession.toFirestoreForStart(
        startedBy: startedBy,
        startedByName: startedByName,
      ),
    );
    await _listsCollection(householdId).doc(listId).update({
      'activeSessionId': sessionRef.id,
    });
  }

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
    bool addedDuringShopping = false,
    String? note,
  }) {
    return _itemsCollection(householdId, listId).add(
      ShoppingItem.toFirestoreForCreate(
        name: name,
        quantity: quantity,
        unit: unit,
        addedBy: addedBy,
        addedByName: addedByName,
        addedDuringShopping: addedDuringShopping,
        note: note,
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
    String? note,
  }) {
    final data = ShoppingItem(
      id: itemId,
      name: '',
      quantity: 0,
      status: ItemStatus.pending,
      addedBy: '',
      addedByName: '',
      addedAt: null,
    ).toFirestoreForUpdate(name: name, quantity: quantity, unit: unit, note: note);

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
    required String completedBy,
    required String completedByName,
    String? activeSessionId,
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
      batch.update(itemsRef.doc(item.id), {
        ...ShoppingItem.statusUpdate(ItemStatus.pending),
        // מוצר שהועבר לקנייה הבאה כבר לא "חדש" - הוא לא נוסף
        // בזמן קנייה פעילה נוכחית, אלא הגיע מסבב קודם.
        'addedDuringShopping': false,
      });
    }

    // אם הייתה קנייה פעילה - סוגרים אותה כחלק מאותה פעולה אטומית.
    if (activeSessionId != null) {
      batch.update(
        _sessionsCollection(householdId, listId).doc(activeSessionId),
        ShoppingSession.toFirestoreForEnd(),
      );
      batch.update(_listsCollection(householdId).doc(listId), {
        'activeSessionId': null,
      });
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
        completedBy: completedBy,
        completedByName: completedByName,
        purchasedItemNames: purchasedItems.map((e) => e.name).toList(),
        carriedOverItemNames: notFoundItemsToCarryOver.map((e) => e.name).toList(),
        droppedItemNames: notFoundItemsToDrop.map((e) => e.name).toList(),
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

HMEOF
cat > 'lib/repositories/shopping_repository.dart' << 'HMEOF'
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

HMEOF
cat > 'lib/features/shopping/add_edit_product_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../models/shopping_item_model.dart';

/// תוצאת הטופס - שם, כמות ויחידת מידה (אופציונלי).
class ProductFormResult {
  final String name;
  final double quantity;
  final String? unit;
  final String? note;

  const ProductFormResult({
    required this.name,
    required this.quantity,
    this.unit,
    this.note,
  });
}

/// מסך הוספה/עריכה של מוצר. משמש גם ליצירה (existingItem == null)
/// וגם לעריכה (existingItem != null), כדי לא לשכפל קוד טופס.
class AddEditProductScreen extends StatefulWidget {
  final ShoppingItem? existingItem;

  const AddEditProductScreen({super.key, this.existingItem});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _noteController;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    _quantityController = TextEditingController(
      text: (widget.existingItem?.quantity ?? 1).toString(),
    );
    _unitController = TextEditingController(text: widget.existingItem?.unit ?? '');
    _noteController = TextEditingController(text: widget.existingItem?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      ProductFormResult(
        name: _nameController.text.trim(),
        quantity: double.parse(_quantityController.text),
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
        note: _noteController.text.trim().isEmpty ? '' : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editProduct : AppStrings.addProduct),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  decoration: const InputDecoration(labelText: AppStrings.productName),
                  validator: (value) =>
                      Validators.requiredText(value, fieldName: AppStrings.productName),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: AppStrings.quantity),
                  validator: Validators.positiveNumber,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: AppStrings.unit),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: AppStrings.noteLabel),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(AppStrings.save, style: AppTextStyles.button),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

HMEOF
cat > 'lib/features/shopping/shopping_list_screen.dart' << 'HMEOF'
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
import '../../models/shopping_list_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_provider.dart';
import 'add_edit_product_screen.dart';
import 'shopping_history_screen.dart';
import 'shopping_summary_screen.dart';

/// מסך רשימת הקניות הראשי.
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

  const ShoppingListScreen({super.key, required this.householdId});

  Future<void> _openAddProduct(
    BuildContext context,
    WidgetRef ref,
    String listId,
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

  Future<void> _startShopping(BuildContext context, WidgetRef ref, String listId) async {
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
    String listId,
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
    final listIdAsync = ref.watch(shoppingListIdProvider);
    final listId = listIdAsync.value;

    final itemsAsync = listId == null
        ? const AsyncValue<List<ShoppingItem>>.loading()
        : ref.watch(shoppingItemsProvider((householdId: householdId, listId: listId)));
    final currentItems = itemsAsync.value;

    final listMetaAsync = listId == null
        ? const AsyncValue<ShoppingList>.loading()
        : ref.watch(shoppingListMetaProvider((householdId: householdId, listId: listId)));
    final activeSessionId = listMetaAsync.value?.activeSessionId;
    final isSessionActive = activeSessionId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.shoppingList),
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
            onPressed: listId == null || currentItems == null
                ? null
                : () => _openFinishShopping(
                      context,
                      ref,
                      listId,
                      currentItems,
                      activeSessionId,
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          // באנר קנייה פעילה / כפתור התחלת קנייה.
          if (listId != null)
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
                      onPressed: () => _startShopping(context, ref, listId),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(AppStrings.startShopping),
                    ),
                  ),
          Expanded(
            child: listIdAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, st) => const ErrorView(),
              data: (listId) {
                if (listId == null) return const LoadingIndicator();

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
          ),
        ],
      ),
      floatingActionButton: listIdAsync.maybeWhen(
        data: (listId) => listId == null
            ? null
            : FloatingActionButton(
                onPressed: () => _openAddProduct(context, ref, listId, isSessionActive),
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
      title: Row(
        children: [
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

HMEOF
echo 'DONE - item notes files fully synced!'
