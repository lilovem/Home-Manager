#!/bin/bash
set -e
echo "== שלב 1: עדכון lib/models/vehicle_model.dart =="
mkdir -p lib/models
cat > lib/models/vehicle_model.dart << 'DARTEOF'
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

  /// תמונה אמיתית של הרכב שהמשתמש העלה (Data URL - base64 מכווץ),
  /// לתצוגה במקום האייקון הגנרי. נשמר ישירות במסמך הרכב ב-Firestore
  /// (בלי Firebase Storage בתשלום) - ראה vehicle_photo_picker.dart.
  final String? photoDataUrl;

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
    this.photoDataUrl,
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
      photoDataUrl: data['photoDataUrl'] as String?,
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

/// שמות החודשים בעברית - לתצוגת תאריך "יפה" (למשל "23 בספטמבר 2026")
/// בלי שעה, בשונה מ-DateFormatter.short הכללי שמיועד לתאריכים עם
/// שעה (כמו רשומות פעילות). בשימוש בבחירת "תאריכים חשובים" של הרכב
/// (רישיון/ביטוחים) ובתאריך ביצוע טיפול.
const List<String> _kHebrewMonthNames = [
  'ינואר',
  'פברואר',
  'מרץ',
  'אפריל',
  'מאי',
  'יוני',
  'יולי',
  'אוגוסט',
  'ספטמבר',
  'אוקטובר',
  'נובמבר',
  'דצמבר',
];

String formatPrettyDateHe(DateTime date) {
  final month = _kHebrewMonthNames[date.month - 1];
  return '${date.day} ב$month ${date.year}';
}
DARTEOF

echo "== שלב 2: עדכון lib/services/firebase/vehicles_service.dart =="
mkdir -p lib/services/firebase
cat > lib/services/firebase/vehicles_service.dart << 'DARTEOF'
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

  /// שומר/מנקה את תמונת הרכב (Data URL). photoDataUrl == null מוחק
  /// את התמונה ומחזיר לתצוגת האייקון הגנרי.
  Future<void> updateVehiclePhoto({
    required String householdId,
    required String vehicleId,
    required String? photoDataUrl,
  }) {
    return _vehiclesCollection(householdId).doc(vehicleId).update({
      'photoDataUrl': photoDataUrl,
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
DARTEOF

echo "== שלב 3: עדכון lib/repositories/vehicles_repository.dart =="
mkdir -p lib/repositories
cat > lib/repositories/vehicles_repository.dart << 'DARTEOF'
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

  Future<void> updateVehiclePhoto({
    required String householdId,
    required String vehicleId,
    required String? photoDataUrl,
  }) {
    return _service.updateVehiclePhoto(
      householdId: householdId,
      vehicleId: vehicleId,
      photoDataUrl: photoDataUrl,
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
DARTEOF

echo "== שלב 4: עדכון lib/features/vehicles/vehicle_detail_screen.dart =="
mkdir -p lib/features/vehicles
cat > lib/features/vehicles/vehicle_detail_screen.dart << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import '../../providers/vehicles_provider.dart';
import 'dart:typed_data';
import 'add_edit_vehicle_screen.dart';
import 'add_service_record_screen.dart';
import 'vehicle_photo_picker.dart';
import 'vehicles_background_provider.dart';
import 'vehicles_list_screen.dart' show colorForDaysRemaining, daysUntil;

/// אייקון קבוע לכל סוג טיפול - משותף בין כרטיסי הרשת (_MaintenanceSection)
/// לבין חלונית ההגדרות (_showMaintenanceSettingsSheet), כדי שלא יהיה כפול.
const Map<String, IconData> _kMaintenanceIcons = {
  'oilChange': Icons.opacity,
  'majorService': Icons.build_circle_outlined,
  'battery': Icons.battery_charging_full,
  'brakes': Icons.album_outlined,
};

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

  /// חלונית "הגדרות טווחי טיפולים" - נפתחת מהאייקון (☰) ליד כותרת
  /// מקטע הטיפולים. זו הדרך היחידה לערוך מרווחים - אין יותר עריכה
  /// מתוך הכרטיסים ברשת עצמם, כדי שלא יהיו שתי דרכים מקבילות.
  void _showMaintenanceSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer(
                builder: (context, ref, _) {
                  final vehicleAsync = ref.watch(
                    vehicleDetailProvider((householdId: householdId, vehicleId: vehicleId)),
                  );
                  final vehicle = vehicleAsync.value;
                  if (vehicle == null) return const SizedBox.shrink();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.maintenanceSettingsTitle, style: AppTextStyles.heading2),
                      const SizedBox(height: 8),
                      ...kTrackedMaintenanceKeys.map((key) {
                        final name = kMaintenanceTemplateNames[key] ?? key;
                        final interval = vehicle.maintenanceIntervals[key] ??
                            kDefaultMaintenanceIntervals[key] ??
                            10000;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(_kMaintenanceIcons[key] ?? Icons.build_outlined,
                              color: AppColors.primary),
                          title: Text(name),
                          subtitle: Text(
                            '$interval ${AppStrings.kmUnit}',
                            textDirection: TextDirection.ltr,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.tune, size: 20),
                            tooltip: AppStrings.editIntervalTooltip,
                            onPressed: () => _editInterval(context, ref, vehicle, key, interval),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync =
        ref.watch(vehicleDetailProvider((householdId: householdId, vehicleId: vehicleId)));
    final backgroundId = ref.watch(vehiclesBackgroundIdProvider(householdId)).value ?? 'none';
    final background = backgroundOptionById(backgroundId);
    final hasBackground = background.id != 'none';

    return Scaffold(
      body: Container(
        decoration: hasBackground
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(background.imageAsset!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.28),
                    BlendMode.darken,
                  ),
                ),
              )
            : null,
        child: vehicleAsync.when(
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
                title: const Text(AppStrings.vehicleDetailsTitle),
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
                      _DatesHeaderCard(householdId: householdId, vehicle: vehicle),
                      const SizedBox(height: 8),
                      Center(
                        child: _MileageCard(
                          vehicle: vehicle,
                          onUpdate: () => _updateMileage(context, ref, vehicle),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Material(
                            color: Colors.black.withOpacity(0.32),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _showMaintenanceSettingsSheet(context, ref),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.menu, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(AppStrings.maintenanceSectionTitle, style: AppTextStyles.heading2),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _MaintenanceSection(
                        householdId: householdId,
                        vehicle: vehicle,
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
      ),
    );
  }
}

/// כרטיס בולט למעלה עם 3 "צ'יפים" - רישיון, ביטוח חובה, ביטוח מקיף -
/// כל אחד עם מספר הימים שנשארו, בצבע לפי דחיפות, על רקע גרדיאנט
/// כהה שמדגיש אותם ונותן מראה "יוקרתי" יותר.
class _DatesHeaderCard extends StatelessWidget {
  final String householdId;
  final Vehicle vehicle;
  const _DatesHeaderCard({required this.householdId, required this.vehicle});

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
              _VehicleIconLarge(householdId: householdId, vehicle: vehicle),
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

/// אייקון/תמונה גדולה של הרכב בכרטיס העליון - אם למשתמש יש תמונה
/// שמורה (photoDataUrl) היא מוצגת במקום האייקון הגנרי. לחיצה עליה
/// פותחת בחירת תמונה חדשה מהמחשב/טלפון (ראה vehicle_photo_picker.dart).
class _VehicleIconLarge extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _VehicleIconLarge({required this.householdId, required this.vehicle});

  Future<void> _changePhoto(WidgetRef ref) async {
    final dataUrl = await pickAndCompressVehiclePhoto();
    if (dataUrl == null) return;
    await ref.read(vehiclesRepositoryProvider).updateVehiclePhoto(
          householdId: householdId,
          vehicleId: vehicle.id,
          photoDataUrl: dataUrl,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoBytes = decodeVehiclePhotoDataUrl(vehicle.photoDataUrl);

    return GestureDetector(
      onTap: () => _changePhoto(ref),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: photoBytes == null
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white24, Colors.white10],
                    )
                  : null,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 1.5),
              image: photoBytes != null
                  ? DecorationImage(
                      image: MemoryImage(Uint8List.fromList(photoBytes)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoBytes == null
                ? const Icon(Icons.directions_car_filled, color: Colors.white, size: 30)
                : null,
          ),
          Positioned(
            bottom: -2,
            left: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
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
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.speed_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.currentMileageLabel,
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                  ),
                  Text(
                    '${vehicle.currentMileage} ${AppStrings.kmUnit}',
                    style: AppTextStyles.heading2.copyWith(fontSize: 16),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: AppStrings.updateMileageButton,
              onPressed: onUpdate,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

/// מקטע הטיפולים - שורת אייקונים קטנים וקומפקטיים (אחד לכל סוג
/// טיפול), צבועים לפי דחיפות. לחיצה על אייקון פותחת חלונית (bottom
/// sheet) עם כל הפרטים: כמה נשאר, הסבר על הטיפול, וכפתור לעריכת
/// המרווח - כדי לא לתפוס מקום קבוע במסך.
class _MaintenanceSection extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _MaintenanceSection({
    required this.householdId,
    required this.vehicle,
  });

  void _openDetail(
    BuildContext context,
    String key,
    String name,
    IconData icon,
    Color color,
    int remaining,
    int interval,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name, style: AppTextStyles.heading2)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                remaining < 0
                    ? '${AppStrings.overdueByLabel} ${-remaining} ${AppStrings.kmUnit}'
                    : '${AppStrings.nextServiceInLabel} $remaining ${AppStrings.kmUnit}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                kMaintenanceTemplateDescriptions[key] ?? '',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        final tiles = kTrackedMaintenanceKeys.map((key) {
          final name = kMaintenanceTemplateNames[key] ?? key;
          final interval = vehicle.maintenanceIntervals[key] ??
              kDefaultMaintenanceIntervals[key] ??
              10000;

          final matching = records.where((r) => r.serviceType == key).toList();
          final lastMileage = matching.isEmpty
              ? 0
              : matching.map((r) => r.mileageAtService).reduce((a, b) => a > b ? a : b);
          final nextDue = lastMileage + interval;
          final remaining = nextDue - vehicle.currentMileage;

          final color = remaining < 0
              ? AppColors.error
              : remaining <= (interval * 0.1)
                  ? Colors.orange
                  : AppColors.itemPurchased;

          final icon = _kMaintenanceIcons[key] ?? Icons.build_outlined;
          final isUrgent = remaining < 0;

          return Material(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDetail(context, key, name, icon, color, remaining, interval),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 16),
                        ),
                        const Spacer(),
                        if (isUrgent)
                          const Icon(Icons.error, color: AppColors.error, size: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySecondary
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      remaining < 0
                          ? '${AppStrings.overdueByLabel} ${-remaining} ${AppStrings.kmUnit}'
                          : '${AppStrings.nextServiceInLabel} $remaining ${AppStrings.kmUnit}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList();

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: tiles,
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
        color: Colors.white.withOpacity(0.8),
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
DARTEOF

echo "הסתיים בהצלחה! עכשיו הריצי: flutter pub get, ואז הפעילי מחדש את שרת הפיתוח."
