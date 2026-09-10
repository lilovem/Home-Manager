import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/product_categorizer.dart';

/// סטטוס של מוצר ברשימת הקניות.
enum ItemStatus { pending, purchased, notFound }

ItemStatus _statusFromString(String? value) {
  switch (value) {
    case 'purchased':
      return ItemStatus.purchased;
    case 'notFound':
      return ItemStatus.notFound;
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
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required String name,
    required double quantity,
    String? unit,
    required String addedBy,
    required String addedByName,
    bool addedDuringShopping = false,
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
    };
  }

  Map<String, dynamic> toFirestoreForUpdate({
    String? name,
    double? quantity,
    String? unit,
  }) {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (quantity != null) map['quantity'] = quantity;
    if (unit != null) map['unit'] = unit;
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

