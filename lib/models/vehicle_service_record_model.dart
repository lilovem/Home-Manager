import 'package:cloud_firestore/cloud_firestore.dart';

/// תיעוד טיפול בודד שבוצע ברכב - תחת
/// households/{id}/vehicles/{vehicleId}/serviceRecords/{recordId}.
/// serviceType הוא בדרך כלל אחד המפתחות מ-kMaintenanceTemplateNames
/// (וכך מחשבים "מתי הטיפול הבא" לפי הרשומה האחרונה מאותו סוג),
/// אבל יכול להיות גם טקסט חופשי ("אחר") לטיפול שלא ברשימה.
class VehicleServiceRecord {
  final String id;
  final String serviceType;
  final DateTime performedAt;
  final int mileageAtService;
  final double? cost;
  final String? notes;
  final DateTime? createdAt;

  const VehicleServiceRecord({
    required this.id,
    required this.serviceType,
    required this.performedAt,
    required this.mileageAtService,
    this.cost,
    this.notes,
    required this.createdAt,
  });

  factory VehicleServiceRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return VehicleServiceRecord(
      id: id,
      serviceType: data['serviceType'] as String? ?? '',
      performedAt: (data['performedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mileageAtService: (data['mileageAtService'] as num?)?.toInt() ?? 0,
      cost: (data['cost'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required String serviceType,
    required DateTime performedAt,
    required int mileageAtService,
    double? cost,
    String? notes,
  }) {
    return {
      'serviceType': serviceType,
      'performedAt': Timestamp.fromDate(performedAt),
      'mileageAtService': mileageAtService,
      if (cost != null) 'cost': cost,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// עדכון רשומה קיימת - cost/notes מוחלפים תמיד (גם ל-null, כדי
  /// שאפשר יהיה למחוק ערך שהוזן בטעות), בדיוק כמו התיקון שעשינו
  /// פעם לחשבונות (saveBillDetails) עם אותה בעיה בדיוק.
  static Map<String, dynamic> toFirestoreForUpdate({
    required String serviceType,
    required DateTime performedAt,
    required int mileageAtService,
    double? cost,
    String? notes,
  }) {
    return {
      'serviceType': serviceType,
      'performedAt': Timestamp.fromDate(performedAt),
      'mileageAtService': mileageAtService,
      'cost': cost,
      'notes': (notes != null && notes.isNotEmpty) ? notes : null,
    };
  }
}
