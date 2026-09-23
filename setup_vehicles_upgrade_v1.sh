#!/bin/bash
set -e
echo "=== משדרג את מודול הרכבים ==="

mkdir -p lib/models lib/services/firebase lib/repositories lib/features/vehicles

echo "כותב lib/models/vehicle_model.dart..."
cat > lib/models/vehicle_model.dart << 'VEHICLES_UPGRADE_EOF'
import 'package:cloud_firestore/cloud_firestore.dart';

/// רכב בודד ששייך ל-household. אפשר שיהיו כמה רכבים לאותו household -
/// כל רכב מקבל מסמך נפרד תחת households/{id}/vehicles/{vehicleId},
/// כך שיש הפרדה מלאה בין הרכבים (קילומטראז', רישיון, ביטוחים,
/// טיפולים - הכל פר-רכב, בלי שום ערבוב).
class Vehicle {
  final String id;
  final String manufacturer;
  final String model;
  final int? year;
  final String licensePlate;
  final int currentMileage;
  final DateTime? licenseExpiryDate;
  final DateTime? mandatoryInsuranceExpiryDate;
  final DateTime? comprehensiveInsuranceExpiryDate;

  /// מרווחי הטיפולים (בק"מ) לרכב הזה - מתחיל מברירות מחדל גנריות
  /// (ראה kDefaultMaintenanceIntervals), אבל ניתן לעריכה פר-רכב אם
  /// למשתמש יש נתונים מדויקים יותר מספר הרכב שלו.
  final Map<String, int> maintenanceIntervals;

  final DateTime? createdAt;

  const Vehicle({
    required this.id,
    required this.manufacturer,
    required this.model,
    this.year,
    required this.licensePlate,
    required this.currentMileage,
    this.licenseExpiryDate,
    this.mandatoryInsuranceExpiryDate,
    this.comprehensiveInsuranceExpiryDate,
    required this.maintenanceIntervals,
    required this.createdAt,
  });

  String get displayName => '$manufacturer $model';

  factory Vehicle.fromFirestore(String id, Map<String, dynamic> data) {
    final rawIntervals = data['maintenanceIntervals'] as Map<String, dynamic>?;
    return Vehicle(
      id: id,
      manufacturer: data['manufacturer'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: data['year'] as int?,
      licensePlate: data['licensePlate'] as String? ?? '',
      currentMileage: (data['currentMileage'] as num?)?.toInt() ?? 0,
      licenseExpiryDate: (data['licenseExpiryDate'] as Timestamp?)?.toDate(),
      mandatoryInsuranceExpiryDate:
          (data['mandatoryInsuranceExpiryDate'] as Timestamp?)?.toDate(),
      comprehensiveInsuranceExpiryDate:
          (data['comprehensiveInsuranceExpiryDate'] as Timestamp?)?.toDate(),
      maintenanceIntervals: rawIntervals != null
          ? rawIntervals.map((key, value) => MapEntry(key, (value as num).toInt()))
          : Map<String, int>.from(kDefaultMaintenanceIntervals),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required String manufacturer,
    required String model,
    int? year,
    required String licensePlate,
    required int currentMileage,
    DateTime? licenseExpiryDate,
    DateTime? mandatoryInsuranceExpiryDate,
    DateTime? comprehensiveInsuranceExpiryDate,
  }) {
    return {
      'manufacturer': manufacturer,
      'model': model,
      if (year != null) 'year': year,
      'licensePlate': licensePlate,
      'currentMileage': currentMileage,
      'licenseExpiryDate':
          licenseExpiryDate != null ? Timestamp.fromDate(licenseExpiryDate) : null,
      'mandatoryInsuranceExpiryDate': mandatoryInsuranceExpiryDate != null
          ? Timestamp.fromDate(mandatoryInsuranceExpiryDate)
          : null,
      'comprehensiveInsuranceExpiryDate': comprehensiveInsuranceExpiryDate != null
          ? Timestamp.fromDate(comprehensiveInsuranceExpiryDate)
          : null,
      'maintenanceIntervals': kDefaultMaintenanceIntervals,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestoreForUpdate({
    String? manufacturer,
    String? model,
    int? year,
    String? licensePlate,
    DateTime? licenseExpiryDate,
    DateTime? mandatoryInsuranceExpiryDate,
    DateTime? comprehensiveInsuranceExpiryDate,
  }) {
    return {
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null) 'licensePlate': licensePlate,
      'licenseExpiryDate':
          licenseExpiryDate != null ? Timestamp.fromDate(licenseExpiryDate) : null,
      'mandatoryInsuranceExpiryDate': mandatoryInsuranceExpiryDate != null
          ? Timestamp.fromDate(mandatoryInsuranceExpiryDate)
          : null,
      'comprehensiveInsuranceExpiryDate': comprehensiveInsuranceExpiryDate != null
          ? Timestamp.fromDate(comprehensiveInsuranceExpiryDate)
          : null,
    };
  }
}

/// מפתח קבוע -> (שם תצוגה, מרווח ק"מ ברירת מחדל). המרווחים מבוססים
/// על נהוג כללי בתעשייה - לא מדויק לכל יצרן/דגם ספציפי (אין מאגר
/// חינמי כזה), אבל נקודת פתיחה סבירה שאפשר לערוך פר-רכב.
const Map<String, int> kDefaultMaintenanceIntervals = {
  'oilChange': 10000,
  'majorService': 20000,
  'tires': 40000,
  'battery': 50000,
  'brakes': 20000,
};

const Map<String, String> kMaintenanceTemplateNames = {
  'oilChange': 'טיפול קטן (שמן ומסנן)',
  'majorService': 'טיפול גדול',
  'tires': 'החלפת צמיגים',
  'battery': 'החלפת מצבר',
  'brakes': 'בדיקת בלמים',
};

/// הסבר קצר לכל סוג טיפול - מוצג בלחיצה על אייקון ה"מידע" ליד כל
/// סוג טיפול במסך פרטי הרכב, כדי שמשתמש שלא בטוח מה זה בדיוק
/// יידע למה לצפות.
const Map<String, String> kMaintenanceTemplateDescriptions = {
  'oilChange':
      'החלפת שמן מנוע ומסנן שמן. לרוב כולל גם בדיקת נוזלים כלליים (בלמים, קירור, שמשות) ולחץ אוויר בצמיגים.',
  'majorService':
      'טיפול מקיף יותר - כולל את הטיפול הקטן, ובנוסף החלפת מסנני אוויר/דלק/מזגן, ובדיקה כללית של מערכות הרכב (בלמים, היגוי, מתלים).',
  'tires': 'בדיקת מצב הצמיגים והחלפתם כשהסימון (חריצים) נשחק או שיש נזק גלוי.',
  'battery':
      'בדיקת תפוקת המצבר והחלפתו כשהוא מתקשה להתניע את הרכב או שאורך חייו הסתיים (בדרך כלל 3-5 שנים).',
  'brakes':
      'בדיקת מצב רפידות ודיסקיות הבלמים, ולעיתים החלפתן כשהן נשחקות מתחת לעובי הבטיחותי.',
};

/// סוגי הטיפולים שנכנסים למעקב האוטומטי (חישוב "כמה ק"מ נשארו עד
/// הטיפול הבא") במסך פרטי הרכב. "החלפת צמיגים" הוצאה מכאן - היא לא
/// מתבצעת לפי מרווח ק"מ קבוע כמו שאר הטיפולים, אבל עדיין אפשר
/// לתעד אותה בהיסטוריה (מופיעה כאן, ב-kMaintenanceTemplateNames,
/// בבחירת סוג הטיפול במסך "הוסף תיעוד טיפול").
const List<String> kTrackedMaintenanceKeys = [
  'oilChange',
  'majorService',
  'battery',
  'brakes',
];
VEHICLES_UPGRADE_EOF

echo "כותב lib/models/vehicle_service_record_model.dart..."
cat > lib/models/vehicle_service_record_model.dart << 'VEHICLES_UPGRADE_EOF'
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
VEHICLES_UPGRADE_EOF

echo "כותב lib/services/firebase/vehicles_service.dart..."
cat > lib/services/firebase/vehicles_service.dart << 'VEHICLES_UPGRADE_EOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';

/// עטיפה דקה סביב קריאות Firestore הקשורות לרכבים.
class VehiclesService {
  final FirebaseFirestore _firestore;

  VehiclesService(this._firestore);

  CollectionReference<Map<String, dynamic>> _vehiclesCollection(String householdId) {
    return _firestore.collection('households').doc(householdId).collection('vehicles');
  }

  CollectionReference<Map<String, dynamic>> _serviceRecordsCollection(
    String householdId,
    String vehicleId,
  ) {
    return _vehiclesCollection(householdId).doc(vehicleId).collection('serviceRecords');
  }

  Stream<List<Vehicle>> watchVehicles(String householdId) {
    return _vehiclesCollection(householdId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Vehicle.fromFirestore(doc.id, doc.data())).toList());
  }

  Stream<Vehicle?> watchVehicle(String householdId, String vehicleId) {
    return _vehiclesCollection(householdId).doc(vehicleId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Vehicle.fromFirestore(doc.id, doc.data()!);
    });
  }

  Future<Vehicle> addVehicle({
    required String householdId,
    required String manufacturer,
    required String model,
    int? year,
    required String licensePlate,
    required int currentMileage,
    DateTime? licenseExpiryDate,
    DateTime? mandatoryInsuranceExpiryDate,
    DateTime? comprehensiveInsuranceExpiryDate,
  }) async {
    final docRef = await _vehiclesCollection(householdId).add(
      Vehicle.toFirestoreForCreate(
        manufacturer: manufacturer,
        model: model,
        year: year,
        licensePlate: licensePlate,
        currentMileage: currentMileage,
        licenseExpiryDate: licenseExpiryDate,
        mandatoryInsuranceExpiryDate: mandatoryInsuranceExpiryDate,
        comprehensiveInsuranceExpiryDate: comprehensiveInsuranceExpiryDate,
      ),
    );
    final snapshot = await docRef.get();
    return Vehicle.fromFirestore(snapshot.id, snapshot.data()!);
  }

  Future<void> updateVehicle({
    required String householdId,
    required String vehicleId,
    String? manufacturer,
    String? model,
    int? year,
    String? licensePlate,
    DateTime? licenseExpiryDate,
    DateTime? mandatoryInsuranceExpiryDate,
    DateTime? comprehensiveInsuranceExpiryDate,
  }) {
    final data = Vehicle(
      id: vehicleId,
      manufacturer: '',
      model: '',
      licensePlate: '',
      currentMileage: 0,
      maintenanceIntervals: const {},
      createdAt: null,
    ).toFirestoreForUpdate(
      manufacturer: manufacturer,
      model: model,
      year: year,
      licensePlate: licensePlate,
      licenseExpiryDate: licenseExpiryDate,
      mandatoryInsuranceExpiryDate: mandatoryInsuranceExpiryDate,
      comprehensiveInsuranceExpiryDate: comprehensiveInsuranceExpiryDate,
    );
    return _vehiclesCollection(householdId).doc(vehicleId).update(data);
  }

  Future<void> updateMileage({
    required String householdId,
    required String vehicleId,
    required int newMileage,
  }) {
    return _vehiclesCollection(householdId).doc(vehicleId).update({
      'currentMileage': newMileage,
    });
  }

  Future<void> updateMaintenanceInterval({
    required String householdId,
    required String vehicleId,
    required String templateKey,
    required int intervalKm,
  }) {
    return _vehiclesCollection(householdId).doc(vehicleId).update({
      'maintenanceIntervals.$templateKey': intervalKm,
    });
  }

  /// מוחק רכב לגמרי, כולל כל תיעודי הטיפולים שלו (מחיקה רקורסיבית,
  /// כמו שכבר עשינו ל-household ולרשימות קניות).
  Future<void> deleteVehicle({
    required String householdId,
    required String vehicleId,
  }) async {
    final recordsSnapshot =
        await _serviceRecordsCollection(householdId, vehicleId).get();

    final batch = _firestore.batch();
    for (final doc in recordsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_vehiclesCollection(householdId).doc(vehicleId));
    await batch.commit();
  }

  Stream<List<VehicleServiceRecord>> watchServiceRecords({
    required String householdId,
    required String vehicleId,
  }) {
    return _serviceRecordsCollection(householdId, vehicleId)
        .orderBy('performedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleServiceRecord.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// מוסיף רשומת טיפול, **ומעדכן את הקילומטראז' הנוכחי של הרכב**
  /// אם הטיפול בוצע בק"מ גבוה יותר ממה שהיה רשום - כך שאין צורך
  /// לעדכן קילומטראז' בנפרד אחרי כל טיפול.
  Future<void> addServiceRecord({
    required String householdId,
    required String vehicleId,
    required String serviceType,
    required DateTime performedAt,
    required int mileageAtService,
    double? cost,
    String? notes,
  }) async {
    final vehicleRef = _vehiclesCollection(householdId).doc(vehicleId);
    final vehicleSnapshot = await vehicleRef.get();
    final currentMileage =
        (vehicleSnapshot.data()?['currentMileage'] as num?)?.toInt() ?? 0;

    final batch = _firestore.batch();
    batch.set(
      _serviceRecordsCollection(householdId, vehicleId).doc(),
      VehicleServiceRecord.toFirestoreForCreate(
        serviceType: serviceType,
        performedAt: performedAt,
        mileageAtService: mileageAtService,
        cost: cost,
        notes: notes,
      ),
    );
    if (mileageAtService > currentMileage) {
      batch.update(vehicleRef, {'currentMileage': mileageAtService});
    }
    await batch.commit();
  }

  Future<void> deleteServiceRecord({
    required String householdId,
    required String vehicleId,
    required String recordId,
  }) {
    return _serviceRecordsCollection(householdId, vehicleId).doc(recordId).delete();
  }

  /// מעדכן רשומת טיפול קיימת. אם הק"מ שעודכן גבוה מהקילומטראז'
  /// הנוכחי הרשום לרכב - מעדכן גם אותו, באותה לוגיקה כמו בהוספה.
  Future<void> updateServiceRecord({
    required String householdId,
    required String vehicleId,
    required String recordId,
    required String serviceType,
    required DateTime performedAt,
    required int mileageAtService,
    double? cost,
    String? notes,
  }) async {
    final vehicleRef = _vehiclesCollection(householdId).doc(vehicleId);
    final vehicleSnapshot = await vehicleRef.get();
    final currentMileage =
        (vehicleSnapshot.data()?['currentMileage'] as num?)?.toInt() ?? 0;

    final batch = _firestore.batch();
    batch.update(
      _serviceRecordsCollection(householdId, vehicleId).doc(recordId),
      VehicleServiceRecord.toFirestoreForUpdate(
        serviceType: serviceType,
        performedAt: performedAt,
        mileageAtService: mileageAtService,
        cost: cost,
        notes: notes,
      ),
    );
    if (mileageAtService > currentMileage) {
      batch.update(vehicleRef, {'currentMileage': mileageAtService});
    }
    await batch.commit();
  }
}
VEHICLES_UPGRADE_EOF

echo "כותב lib/repositories/vehicles_repository.dart..."
cat > lib/repositories/vehicles_repository.dart << 'VEHICLES_UPGRADE_EOF'
import '../models/vehicle_model.dart';
import '../models/vehicle_service_record_model.dart';
import '../services/firebase/vehicles_service.dart';

/// שכבת ה-Repository לרכבים - כרגע עטיפה דקה מול VehiclesService
/// (אין תרגום שגיאות מיוחד כמו ב-Auth - שגיאות Firestore כאן
/// נדירות ולא דורשות הודעות ידידותיות מיוחדות).
class VehiclesRepository {
  final VehiclesService _service;

  VehiclesRepository(this._service);

  Stream<List<Vehicle>> watchVehicles(String householdId) =>
      _service.watchVehicles(householdId);

  Stream<Vehicle?> watchVehicle(String householdId, String vehicleId) =>
      _service.watchVehicle(householdId, vehicleId);

  Future<Vehicle> addVehicle({
    required String householdId,
    required String manufacturer,
    required String model,
    int? year,
    required String licensePlate,
    required int currentMileage,
    DateTime? licenseExpiryDate,
    DateTime? mandatoryInsuranceExpiryDate,
    DateTime? comprehensiveInsuranceExpiryDate,
  }) {
    return _service.addVehicle(
      householdId: householdId,
      manufacturer: manufacturer,
      model: model,
      year: year,
      licensePlate: licensePlate,
      currentMileage: currentMileage,
      licenseExpiryDate: licenseExpiryDate,
      mandatoryInsuranceExpiryDate: mandatoryInsuranceExpiryDate,
      comprehensiveInsuranceExpiryDate: comprehensiveInsuranceExpiryDate,
    );
  }

  Future<void> updateVehicle({
    required String householdId,
    required String vehicleId,
    String? manufacturer,
    String? model,
    int? year,
    String? licensePlate,
    DateTime? licenseExpiryDate,
    DateTime? mandatoryInsuranceExpiryDate,
    DateTime? comprehensiveInsuranceExpiryDate,
  }) {
    return _service.updateVehicle(
      householdId: householdId,
      vehicleId: vehicleId,
      manufacturer: manufacturer,
      model: model,
      year: year,
      licensePlate: licensePlate,
      licenseExpiryDate: licenseExpiryDate,
      mandatoryInsuranceExpiryDate: mandatoryInsuranceExpiryDate,
      comprehensiveInsuranceExpiryDate: comprehensiveInsuranceExpiryDate,
    );
  }

  Future<void> updateMileage({
    required String householdId,
    required String vehicleId,
    required int newMileage,
  }) {
    return _service.updateMileage(
      householdId: householdId,
      vehicleId: vehicleId,
      newMileage: newMileage,
    );
  }

  Future<void> updateMaintenanceInterval({
    required String householdId,
    required String vehicleId,
    required String templateKey,
    required int intervalKm,
  }) {
    return _service.updateMaintenanceInterval(
      householdId: householdId,
      vehicleId: vehicleId,
      templateKey: templateKey,
      intervalKm: intervalKm,
    );
  }

  Future<void> deleteVehicle({
    required String householdId,
    required String vehicleId,
  }) {
    return _service.deleteVehicle(householdId: householdId, vehicleId: vehicleId);
  }

  Stream<List<VehicleServiceRecord>> watchServiceRecords({
    required String householdId,
    required String vehicleId,
  }) {
    return _service.watchServiceRecords(householdId: householdId, vehicleId: vehicleId);
  }

  Future<void> addServiceRecord({
    required String householdId,
    required String vehicleId,
    required String serviceType,
    required DateTime performedAt,
    required int mileageAtService,
    double? cost,
    String? notes,
  }) {
    return _service.addServiceRecord(
      householdId: householdId,
      vehicleId: vehicleId,
      serviceType: serviceType,
      performedAt: performedAt,
      mileageAtService: mileageAtService,
      cost: cost,
      notes: notes,
    );
  }

  Future<void> deleteServiceRecord({
    required String householdId,
    required String vehicleId,
    required String recordId,
  }) {
    return _service.deleteServiceRecord(
      householdId: householdId,
      vehicleId: vehicleId,
      recordId: recordId,
    );
  }

  Future<void> updateServiceRecord({
    required String householdId,
    required String vehicleId,
    required String recordId,
    required String serviceType,
    required DateTime performedAt,
    required int mileageAtService,
    double? cost,
    String? notes,
  }) {
    return _service.updateServiceRecord(
      householdId: householdId,
      vehicleId: vehicleId,
      recordId: recordId,
      serviceType: serviceType,
      performedAt: performedAt,
      mileageAtService: mileageAtService,
      cost: cost,
      notes: notes,
    );
  }
}
VEHICLES_UPGRADE_EOF

echo "כותב lib/features/vehicles/vehicles_background_provider.dart..."
cat > lib/features/vehicles/vehicles_background_provider.dart << 'VEHICLES_UPGRADE_EOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// מנגנון בחירת "רקע" למסך רשימת הרכבים - שמור פר-household (לא
/// גלובלי לכל האפליקציה, בכוונה - זה שיך רק לקטגוריית רכבים).
/// כתיבה/קריאה ישירות מול Firestore בלי לגעת ב-household_model.dart
/// הקיים, כדי לא להסתכן בשבירת קוד household אחר - זה שדה נוסף
/// "רך" (soft) שמתעלמים ממנו בכל מקום אחר שקורא household.
///
/// כרגע יש כאן רשימת "רקעים" גנריים (גרדיאנטים) בתור ברירת מחדל -
/// כשיגיעו תמונות אמיתיות מהמשתמש, מחליפים את kVehiclesBackgrounds
/// לתמונות (assets) בלי לשנות שום דבר אחר במנגנון הבחירה עצמו.
class VehiclesBackgroundOption {
  final String id;
  final String label;
  final List<int> gradientColors; // ARGB ints, שני צבעים לגרדיאנט

  const VehiclesBackgroundOption({
    required this.id,
    required this.label,
    required this.gradientColors,
  });
}

const List<VehiclesBackgroundOption> kVehiclesBackgrounds = [
  VehiclesBackgroundOption(
    id: 'none',
    label: 'ללא רקע',
    gradientColors: [0xFFFFFFFF, 0xFFFFFFFF],
  ),
  VehiclesBackgroundOption(
    id: 'midnight',
    label: 'כחול לילה',
    gradientColors: [0xFF0F2027, 0xFF2C5364],
  ),
  VehiclesBackgroundOption(
    id: 'racing_red',
    label: 'אדום מרוץ',
    gradientColors: [0xFF3A1C1C, 0xFF8B0000],
  ),
  VehiclesBackgroundOption(
    id: 'carbon',
    label: 'אפור פחמן',
    gradientColors: [0xFF232526, 0xFF414345],
  ),
];

final _vehiclesFirestoreForBackgroundProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// מזהה הרקע הנבחר עבור household נתון - null/'none' = בלי רקע.
final vehiclesBackgroundIdProvider =
    StreamProvider.family<String, String>((ref, householdId) {
  final firestore = ref.watch(_vehiclesFirestoreForBackgroundProvider);
  return firestore.collection('households').doc(householdId).snapshots().map(
        (doc) => (doc.data()?['vehiclesBackgroundId'] as String?) ?? 'none',
      );
});

Future<void> setVehiclesBackgroundId(String householdId, String backgroundId) {
  return FirebaseFirestore.instance
      .collection('households')
      .doc(householdId)
      .update({'vehiclesBackgroundId': backgroundId});
}

VehiclesBackgroundOption backgroundOptionById(String id) {
  return kVehiclesBackgrounds.firstWhere(
    (o) => o.id == id,
    orElse: () => kVehiclesBackgrounds.first,
  );
}
VEHICLES_UPGRADE_EOF

echo "כותב lib/features/vehicles/vehicles_list_screen.dart..."
cat > lib/features/vehicles/vehicles_list_screen.dart << 'VEHICLES_UPGRADE_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicles_provider.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicles_background_provider.dart';

/// מסך "רכבים" - רשימת כל הרכבים של ה-household (יכול להיות אחד
/// או כמה), עם כרטיס לכל רכב שמראה תמצית: מספר רישוי, ותוקף
/// הרישיון/ביטוחים במבט מהיר. לכל רכב יש הפרדה מלאה - כל אחד
/// עם הקילומטראז', הטיפולים וההיסטוריה שלו בנפרד.
class VehiclesListScreen extends ConsumerWidget {
  final String householdId;

  const VehiclesListScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesListProvider(householdId));
    final backgroundId = ref.watch(vehiclesBackgroundIdProvider(householdId)).value ?? 'none';
    final background = backgroundOptionById(backgroundId);
    final hasBackground = background.id != 'none';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.vehiclesTitle),
        foregroundColor: hasBackground ? Colors.white : null,
        backgroundColor: hasBackground ? Colors.transparent : null,
        elevation: hasBackground ? 0 : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: AppStrings.chooseBackgroundTooltip,
            onPressed: () => _showBackgroundPicker(context, ref, backgroundId),
          ),
        ],
      ),
      extendBodyBehindAppBar: hasBackground,
      body: Container(
        decoration: hasBackground
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(background.gradientColors[0]),
                    Color(background.gradientColors[1]),
                  ],
                ),
              )
            : null,
        child: SafeArea(
          top: !hasBackground,
          child: Padding(
            padding: hasBackground ? const EdgeInsets.only(top: kToolbarHeight + 12) : EdgeInsets.zero,
            child: vehiclesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(child: Text('שגיאה בטעינה')),
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car_outlined,
                              size: 64,
                              color: hasBackground ? Colors.white70 : AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.noVehiclesYet,
                            textAlign: TextAlign.center,
                            style: hasBackground
                                ? const TextStyle(color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.tapPlusToAddVehicle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: hasBackground ? Colors.white70 : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _VehicleCard(
                    vehicle: vehicles[index],
                    householdId: householdId,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddVehicle(context),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addVehicleButton),
      ),
    );
  }

  void _openAddVehicle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditVehicleScreen(householdId: householdId)),
    );
  }

  void _showBackgroundPicker(BuildContext context, WidgetRef ref, String currentId) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(AppStrings.chooseBackgroundTooltip, style: AppTextStyles.heading2),
            ),
            ...kVehiclesBackgrounds.map(
              (option) => ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                    gradient: LinearGradient(
                      colors: [
                        Color(option.gradientColors[0]),
                        Color(option.gradientColors[1]),
                      ],
                    ),
                  ),
                ),
                title: Text(option.label),
                trailing: option.id == currentId
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setVehiclesBackgroundId(householdId, option.id);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// אייקון רכב עגול צבעוני - אותו סגנון עיצובי שכבר קיים באפליקציה
/// (אייקוני הקטגוריות הצבעוניים ברשימת הקניות), כדי שהמודול הזה
/// ירגיש חלק מאותה שפה עיצובית.
class _VehicleIcon extends StatelessWidget {
  final double size;
  const _VehicleIcon({this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.directions_car_filled, color: Colors.white, size: size * 0.55),
    );
  }
}

/// מחזיר צבע לפי כמה ימים נשארו עד תאריך: אדום אם פג/קרוב מאוד,
/// כתום אם מתקרב, ירוק אם רחוק - בשימוש גם בכרטיס הרשימה וגם
/// במסך הפרטים.
Color colorForDaysRemaining(int? days) {
  if (days == null) return AppColors.textSecondary;
  if (days < 0) return AppColors.error;
  if (days <= 14) return AppColors.error;
  if (days <= 30) return Colors.orange;
  return AppColors.itemPurchased;
}

int? daysUntil(DateTime? date) {
  if (date == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  return target.difference(today).inDays;
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final String householdId;

  const _VehicleCard({required this.vehicle, required this.householdId});

  @override
  Widget build(BuildContext context) {
    final licenseDays = daysUntil(vehicle.licenseExpiryDate);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VehicleDetailScreen(
              householdId: householdId,
              vehicleId: vehicle.id,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const _VehicleIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.displayName, style: AppTextStyles.heading2),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.licensePlate,
                      style: AppTextStyles.bodySecondary,
                      textDirection: TextDirection.ltr,
                    ),
                    if (licenseDays != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined,
                              size: 16, color: colorForDaysRemaining(licenseDays)),
                          const SizedBox(width: 4),
                          Text(
                            licenseDays < 0
                                ? AppStrings.licenseExpiredLabel
                                : '${AppStrings.daysUntilLicenseLabel} $licenseDays',
                            style: TextStyle(
                              color: colorForDaysRemaining(licenseDays),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
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
VEHICLES_UPGRADE_EOF

echo "כותב lib/features/vehicles/vehicle_detail_screen.dart..."
cat > lib/features/vehicles/vehicle_detail_screen.dart << 'VEHICLES_UPGRADE_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import '../../providers/vehicles_provider.dart';
import 'add_edit_vehicle_screen.dart';
import 'add_service_record_screen.dart';
import 'vehicles_list_screen.dart' show colorForDaysRemaining, daysUntil;

/// מסך פרטי רכב בודד - הכל פר-רכב, בלי ערבוב עם רכבים אחרים:
/// תוקף רישיון/ביטוחים במבט בולט למעלה, קילומטראז' נוכחי, מעקב
/// טיפולים (לפי מרווחי ק"מ) עם המלצה מתי הטיפול הבא, ותיעוד
/// היסטוריית הטיפולים שכבר בוצעו (מקובצת לפי סוג).
class VehicleDetailScreen extends ConsumerWidget {
  final String householdId;
  final String vehicleId;

  const VehicleDetailScreen({
    super.key,
    required this.householdId,
    required this.vehicleId,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${AppStrings.deleteVehicleConfirmTitle} ${vehicle.displayName}?'),
        content: const Text(AppStrings.deleteVehicleConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.deleteAction, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(vehiclesRepositoryProvider)
          .deleteVehicle(householdId: householdId, vehicleId: vehicle.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _updateMileage(BuildContext context, WidgetRef ref, Vehicle vehicle) async {
    final controller = TextEditingController(text: vehicle.currentMileage.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.updateMileageTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          autofocus: true,
          decoration: const InputDecoration(labelText: AppStrings.currentMileageLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(int.tryParse(controller.text.trim())),
            child: const Text(AppStrings.saveButton),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(vehiclesRepositoryProvider).updateMileage(
            householdId: householdId,
            vehicleId: vehicle.id,
            newMileage: result,
          );
    }
  }

  Future<void> _editInterval(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
    String templateKey,
    int currentInterval,
  ) async {
    final controller = TextEditingController(text: currentInterval.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${AppStrings.editIntervalTitlePrefix} ${kMaintenanceTemplateNames[templateKey]}',
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          autofocus: true,
          decoration: const InputDecoration(labelText: AppStrings.intervalKmLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(int.tryParse(controller.text.trim())),
            child: const Text(AppStrings.saveButton),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      await ref.read(vehiclesRepositoryProvider).updateMaintenanceInterval(
            householdId: householdId,
            vehicleId: vehicle.id,
            templateKey: templateKey,
            intervalKm: result,
          );
    }
  }

  void _showMaintenanceInfo(BuildContext context, String templateKey) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(kMaintenanceTemplateNames[templateKey] ?? ''),
        content: Text(kMaintenanceTemplateDescriptions[templateKey] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.closeAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync =
        ref.watch(vehicleDetailProvider((householdId: householdId, vehicleId: vehicleId)));

    return Scaffold(
      body: vehicleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('שגיאה בטעינה')),
        data: (vehicle) {
          if (vehicle == null) {
            return const Center(child: Text('הרכב נמחק'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                title: Text(vehicle.displayName),
                flexibleSpace: const FlexibleSpaceBar(
                  background: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddEditVehicleScreen(
                          householdId: householdId,
                          existing: vehicle,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ref, vehicle),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DatesHeaderCard(vehicle: vehicle),
                      const SizedBox(height: 16),
                      _MileageCard(
                        vehicle: vehicle,
                        onUpdate: () => _updateMileage(context, ref, vehicle),
                      ),
                      const SizedBox(height: 24),
                      Text(AppStrings.maintenanceSectionTitle, style: AppTextStyles.heading2),
                      const SizedBox(height: 8),
                      _MaintenanceSection(
                        householdId: householdId,
                        vehicle: vehicle,
                        onEditInterval: (key, interval) =>
                            _editInterval(context, ref, vehicle, key, interval),
                        onShowInfo: (key) => _showMaintenanceInfo(context, key),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppStrings.serviceHistoryTitle, style: AppTextStyles.heading2),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddServiceRecordScreen(
                                  householdId: householdId,
                                  vehicleId: vehicle.id,
                                  currentMileage: vehicle.currentMileage,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(AppStrings.addServiceRecordButton),
                          ),
                        ],
                      ),
                      _ServiceHistoryList(
                        householdId: householdId,
                        vehicleId: vehicle.id,
                        currentMileage: vehicle.currentMileage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// כרטיס בולט למעלה עם 3 "צ'יפים" - רישיון, ביטוח חובה, ביטוח מקיף -
/// כל אחד עם מספר הימים שנשארו, בצבע לפי דחיפות, על רקע גרדיאנט
/// כהה שמדגיש אותם ונותן מראה "יוקרתי" יותר.
class _DatesHeaderCard extends StatelessWidget {
  final Vehicle vehicle;
  const _DatesHeaderCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F1C2C), Color(0xFF464B7A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const _VehicleIconLarge(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: AppTextStyles.heading2.copyWith(color: Colors.white),
                    ),
                    Text(
                      vehicle.licensePlate,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _DateChip(
                  label: AppStrings.licenseExpiryLabel,
                  date: vehicle.licenseExpiryDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateChip(
                  label: AppStrings.mandatoryInsuranceLabel,
                  date: vehicle.mandatoryInsuranceExpiryDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateChip(
                  label: AppStrings.comprehensiveInsuranceLabel,
                  date: vehicle.comprehensiveInsuranceExpiryDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleIconLarge extends StatelessWidget {
  const _VehicleIconLarge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white24, Colors.white10],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white38, width: 1.5),
      ),
      child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 30),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime? date;

  const _DateChip({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final days = daysUntil(date);
    final color = colorForDaysRemaining(days);
    // על הרקע הכהה, "רחוק"/ירוק צריך גוון בהיר יותר כדי לבלוט טוב.
    final displayColor = days != null && days > 30 ? const Color(0xFF7CE0C6) : color;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: displayColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            days == null
                ? AppStrings.notSetLabel
                : days < 0
                    ? AppStrings.expiredLabel
                    : '$days ${AppStrings.daysLabel}',
            style: TextStyle(color: displayColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _MileageCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onUpdate;

  const _MileageCard({required this.vehicle, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.speed_outlined, color: AppColors.primary),
        ),
        title: Text(AppStrings.currentMileageLabel),
        subtitle: Text(
          '${vehicle.currentMileage} ${AppStrings.kmUnit}',
          style: AppTextStyles.heading2,
          textDirection: TextDirection.ltr,
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: onUpdate,
          child: const Text(AppStrings.updateMileageButton),
        ),
      ),
    );
  }
}

class _MaintenanceSection extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;
  final void Function(String templateKey, int currentInterval) onEditInterval;
  final void Function(String templateKey) onShowInfo;

  const _MaintenanceSection({
    required this.householdId,
    required this.vehicle,
    required this.onEditInterval,
    required this.onShowInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(
      vehicleServiceRecordsProvider((householdId: householdId, vehicleId: vehicle.id)),
    );

    return recordsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(),
      data: (records) {
        return Column(
          children: kTrackedMaintenanceKeys.map((key) {
            final name = kMaintenanceTemplateNames[key] ?? key;
            final interval = vehicle.maintenanceIntervals[key] ??
                kDefaultMaintenanceIntervals[key] ??
                10000;

            final matching = records.where((r) => r.serviceType == key).toList();
            final lastMileage =
                matching.isEmpty ? 0 : matching.map((r) => r.mileageAtService).reduce((a, b) => a > b ? a : b);
            final nextDue = lastMileage + interval;
            final remaining = nextDue - vehicle.currentMileage;

            final color = remaining < 0
                ? AppColors.error
                : remaining <= (interval * 0.1)
                    ? Colors.orange
                    : AppColors.itemPurchased;

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Row(
                  children: [
                    Flexible(child: Text(name)),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onShowInfo(key),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.textSecondary),
                        ),
                        child: const Icon(Icons.info_outline, size: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  remaining < 0
                      ? '${AppStrings.overdueByLabel} ${-remaining} ${AppStrings.kmUnit}'
                      : '${AppStrings.remainingKmLabel} $remaining ${AppStrings.kmUnit}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.tune, size: 20),
                  tooltip: AppStrings.editIntervalTooltip,
                  onPressed: () => onEditInterval(key, interval),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// היסטוריית הטיפולים - מקובצת לפי סוג טיפול (כל "טיפול קטן" ביחד,
/// כל "החלפת צמיגים" ביחד וכו'), עם כותרת קבוצה שמראה כמה רשומות
/// יש מכל סוג. קבוצות "אחר"/מותאמות אישית מופיעות אחרונות.
class _ServiceHistoryList extends ConsumerWidget {
  final String householdId;
  final String vehicleId;
  final int currentMileage;

  const _ServiceHistoryList({
    required this.householdId,
    required this.vehicleId,
    required this.currentMileage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync =
        ref.watch(vehicleServiceRecordsProvider((householdId: householdId, vehicleId: vehicleId)));

    return recordsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(),
      data: (records) {
        if (records.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(AppStrings.noServiceRecordsYet, style: AppTextStyles.bodySecondary),
          );
        }

        // קיבוץ לפי סוג - סדר קבוע לפי kMaintenanceTemplateNames קודם,
        // ואז כל סוג "אחר" מותאם אישית לפי סדר א"ב.
        final grouped = <String, List<VehicleServiceRecord>>{};
        for (final record in records) {
          grouped.putIfAbsent(record.serviceType, () => []).add(record);
        }

        final knownKeys = kMaintenanceTemplateNames.keys.where(grouped.containsKey).toList();
        final otherKeys = grouped.keys.where((k) => !kMaintenanceTemplateNames.containsKey(k)).toList()
          ..sort();
        final orderedKeys = [...knownKeys, ...otherKeys];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: orderedKeys.map((key) {
            final groupRecords = grouped[key]!;
            final groupName = kMaintenanceTemplateNames[key] ?? key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          groupName,
                          style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${groupRecords.length}',
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...groupRecords.map((record) => _ServiceRecordTile(
                        record: record,
                        householdId: householdId,
                        vehicleId: vehicleId,
                        currentMileage: currentMileage,
                      )),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ServiceRecordTile extends ConsumerWidget {
  final VehicleServiceRecord record;
  final String householdId;
  final String vehicleId;
  final int currentMileage;

  const _ServiceRecordTile({
    required this.record,
    required this.householdId,
    required this.vehicleId,
    required this.currentMileage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = kMaintenanceTemplateNames[record.serviceType] ?? record.serviceType;

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Text(AppStrings.deleteAction, style: TextStyle(color: Colors.white)),
      ),
      confirmDismiss: (_) async {
        await ref.read(vehiclesRepositoryProvider).deleteServiceRecord(
              householdId: householdId,
              vehicleId: vehicleId,
              recordId: record.id,
            );
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.build_outlined, color: AppColors.primary),
          title: Text(displayName),
          subtitle: Text(
            '${DateFormatter.short(record.performedAt)} · ${record.mileageAtService} ${AppStrings.kmUnit}'
            '${record.notes != null ? ' · ${record.notes}' : ''}',
          ),
          trailing: record.cost != null ? Text('₪${record.cost}') : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddServiceRecordScreen(
                householdId: householdId,
                vehicleId: vehicleId,
                currentMileage: currentMileage,
                existing: record,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
VEHICLES_UPGRADE_EOF

echo "כותב lib/features/vehicles/add_service_record_screen.dart..."
cat > lib/features/vehicles/add_service_record_screen.dart << 'VEHICLES_UPGRADE_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import '../../providers/vehicles_provider.dart';

/// טופס תיעוד טיפול - גם להוספת טיפול חדש וגם לעריכת טיפול קיים
/// (אם `existing` מועבר). סוג הטיפול (מהרשימה הקבועה או "אחר" עם
/// טקסט חופשי), תאריך, ק"מ בזמן הטיפול, ואופציונלית עלות והערות.
/// שמירה מעדכנת גם את הקילומטראז' הנוכחי של הרכב אם צריך (ראה
/// VehiclesService.addServiceRecord/updateServiceRecord).
class AddServiceRecordScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String vehicleId;
  final int currentMileage;
  final String? initialTemplateKey;
  final VehicleServiceRecord? existing;

  const AddServiceRecordScreen({
    super.key,
    required this.householdId,
    required this.vehicleId,
    required this.currentMileage,
    this.initialTemplateKey,
    this.existing,
  });

  @override
  ConsumerState<AddServiceRecordScreen> createState() => _AddServiceRecordScreenState();
}

class _AddServiceRecordScreenState extends ConsumerState<AddServiceRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mileageController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;
  late final TextEditingController _customTypeController;

  String? _selectedTemplateKey;
  bool _isOther = false;
  late DateTime _performedAt;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _mileageController = TextEditingController(
      text: (existing?.mileageAtService ?? widget.currentMileage).toString(),
    );
    _costController = TextEditingController(text: existing?.cost?.toString() ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _performedAt = existing?.performedAt ?? DateTime.now();

    if (existing != null) {
      final isKnownType = kMaintenanceTemplateNames.containsKey(existing.serviceType);
      _isOther = !isKnownType;
      _selectedTemplateKey = isKnownType ? existing.serviceType : null;
      _customTypeController = TextEditingController(text: isKnownType ? '' : existing.serviceType);
    } else {
      _selectedTemplateKey = widget.initialTemplateKey ?? kMaintenanceTemplateNames.keys.first;
      _customTypeController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _performedAt,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _performedAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final serviceType = _isOther ? _customTypeController.text.trim() : _selectedTemplateKey!;
      final mileage = int.tryParse(_mileageController.text.trim()) ?? widget.currentMileage;
      final cost = _costController.text.trim().isEmpty
          ? null
          : double.tryParse(_costController.text.trim());
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      final repo = ref.read(vehiclesRepositoryProvider);
      if (_isEditing) {
        await repo.updateServiceRecord(
          householdId: widget.householdId,
          vehicleId: widget.vehicleId,
          recordId: widget.existing!.id,
          serviceType: serviceType,
          performedAt: _performedAt,
          mileageAtService: mileage,
          cost: cost,
          notes: notes,
        );
      } else {
        await repo.addServiceRecord(
          householdId: widget.householdId,
          vehicleId: widget.vehicleId,
          serviceType: serviceType,
          performedAt: _performedAt,
          mileageAtService: mileage,
          cost: cost,
          notes: notes,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('שגיאה בשמירה')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editServiceRecordTitle : AppStrings.addServiceRecordTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppStrings.serviceTypeLabel, style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...kMaintenanceTemplateNames.entries.map((entry) {
                      final selected = !_isOther && _selectedTemplateKey == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _isOther = false;
                          _selectedTemplateKey = entry.key;
                        }),
                      );
                    }),
                    ChoiceChip(
                      label: const Text(AppStrings.otherServiceTypeLabel),
                      selected: _isOther,
                      onSelected: (_) => setState(() => _isOther = true),
                    ),
                  ],
                ),
                if (_isOther) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customTypeController,
                    decoration:
                        const InputDecoration(labelText: AppStrings.otherServiceTypeLabel),
                    validator: (v) {
                      if (!_isOther) return null;
                      return (v == null || v.trim().isEmpty)
                          ? AppStrings.requiredFieldError
                          : null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.serviceDateLabel),
                  subtitle: Text(
                    DateFormatter.short(_performedAt),
                    textDirection: TextDirection.ltr,
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: AppStrings.mileageAtServiceLabel),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return AppStrings.requiredFieldError;
                    if (int.tryParse(v.trim()) == null) return AppStrings.numberOnlyError;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: AppStrings.costLabelOptional),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: AppStrings.notesLabelOptional),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(AppStrings.saveButton, style: AppTextStyles.button),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
VEHICLES_UPGRADE_EOF

echo "מעדכן את app_strings.dart..."
python3 << 'APPSTRINGS_PATCH_EOF'
import json, re
path = 'lib/app/config/app_strings.dart'
entries = [('editServiceRecordTitle', 'עריכת תיעוד טיפול'), ('closeAction', 'סגור'), ('chooseBackgroundTooltip', 'בחר רקע'), ('tapPlusToAddVehicle', 'לחצו על + למטה כדי להוסיף רכב ראשון')]
with open(path, encoding='utf-8') as f:
    content = f.read()
added, skipped = [], []
for key, value in entries:
    if re.search(r'\b' + re.escape(key) + r'\b', content):
        skipped.append(key)
        continue
    line = f'  static const String {key} = {json.dumps(value, ensure_ascii=False)};\n'
    content = content.replace('class AppStrings {', 'class AppStrings {\n' + line, 1)
    added.append(key)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
for k in added:
    print(f'  {k} נוסף.')
for k in skipped:
    print(f'  {k} כבר קיים - מדלג.')
APPSTRINGS_PATCH_EOF

echo ""
echo "=== הסתיים! ==="
echo "עכשיו תריץ: flutter pub get"
echo "ואז הפעל מחדש את שרת הפיתוח (Ctrl+C או q, ואז flutter run -d web-server --web-port=8000)."
