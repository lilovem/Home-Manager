#!/bin/bash
set -e
echo "=== התקנת מודול רכבים ==="

mkdir -p lib/models lib/services/firebase lib/repositories lib/providers lib/features/vehicles lib/features/home

echo "כותב lib/models/vehicle_model.dart..."
cat > lib/models/vehicle_model.dart << 'VEHICLES_MODULE_EOF'
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
VEHICLES_MODULE_EOF

echo "כותב lib/models/vehicle_service_record_model.dart..."
cat > lib/models/vehicle_service_record_model.dart << 'VEHICLES_MODULE_EOF'
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
}
VEHICLES_MODULE_EOF

echo "כותב lib/services/firebase/vehicles_service.dart..."
cat > lib/services/firebase/vehicles_service.dart << 'VEHICLES_MODULE_EOF'
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
}
VEHICLES_MODULE_EOF

echo "כותב lib/repositories/vehicles_repository.dart..."
cat > lib/repositories/vehicles_repository.dart << 'VEHICLES_MODULE_EOF'
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
}
VEHICLES_MODULE_EOF

echo "כותב lib/providers/vehicles_provider.dart..."
cat > lib/providers/vehicles_provider.dart << 'VEHICLES_MODULE_EOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_service_record_model.dart';
import '../repositories/vehicles_repository.dart';
import '../services/firebase/vehicles_service.dart';

/// עצמאי (לא תלוי ב-provider משותף אחר של Firestore), בדיוק כמו
/// firebaseAuthProvider ב-auth_provider.dart - כל תחום מגדיר את
/// ה-instance שהוא צריך.
final _vehiclesFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final vehiclesServiceProvider = Provider<VehiclesService>((ref) {
  return VehiclesService(ref.watch(_vehiclesFirestoreProvider));
});

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  return VehiclesRepository(ref.watch(vehiclesServiceProvider));
});

final vehiclesListProvider =
    StreamProvider.family<List<Vehicle>, String>((ref, householdId) {
  return ref.watch(vehiclesRepositoryProvider).watchVehicles(householdId);
});

final vehicleDetailProvider = StreamProvider.family<Vehicle?,
    ({String householdId, String vehicleId})>((ref, args) {
  return ref
      .watch(vehiclesRepositoryProvider)
      .watchVehicle(args.householdId, args.vehicleId);
});

final vehicleServiceRecordsProvider = StreamProvider.family<
    List<VehicleServiceRecord>, ({String householdId, String vehicleId})>((ref, args) {
  return ref.watch(vehiclesRepositoryProvider).watchServiceRecords(
        householdId: args.householdId,
        vehicleId: args.vehicleId,
      );
});
VEHICLES_MODULE_EOF

echo "כותב lib/features/vehicles/vehicles_list_screen.dart..."
cat > lib/features/vehicles/vehicles_list_screen.dart << 'VEHICLES_MODULE_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicles_provider.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.vehiclesTitle)),
      body: vehiclesAsync.when(
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
                    const Icon(Icons.directions_car_outlined,
                        size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    const Text(AppStrings.noVehiclesYet, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openAddVehicle(context),
                      icon: const Icon(Icons.add),
                      label: const Text(AppStrings.addVehicleButton),
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
VEHICLES_MODULE_EOF

echo "כותב lib/features/vehicles/add_edit_vehicle_screen.dart..."
cat > lib/features/vehicles/add_edit_vehicle_screen.dart << 'VEHICLES_MODULE_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicles_provider.dart';

/// מסך הוספה/עריכה של רכב. אם `existing` מועבר - זו עריכה של רכב
/// קיים; אחרת - הוספת רכב חדש. אותו מסך משרת את שני המקרים כדי
/// לא לכפול קוד טופס.
class AddEditVehicleScreen extends ConsumerStatefulWidget {
  final String householdId;
  final Vehicle? existing;

  const AddEditVehicleScreen({
    super.key,
    required this.householdId,
    this.existing,
  });

  @override
  ConsumerState<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _mileageController;

  DateTime? _licenseExpiry;
  DateTime? _mandatoryInsuranceExpiry;
  DateTime? _comprehensiveInsuranceExpiry;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _manufacturerController = TextEditingController(text: v?.manufacturer ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(text: v?.year?.toString() ?? '');
    _plateController = TextEditingController(text: v?.licensePlate ?? '');
    _mileageController = TextEditingController(text: v?.currentMileage.toString() ?? '');
    _licenseExpiry = v?.licenseExpiryDate;
    _mandatoryInsuranceExpiry = v?.mandatoryInsuranceExpiryDate;
    _comprehensiveInsuranceExpiry = v?.comprehensiveInsuranceExpiryDate;
  }

  @override
  void dispose() {
    _manufacturerController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(vehiclesRepositoryProvider);
      final year = _yearController.text.trim().isEmpty
          ? null
          : int.tryParse(_yearController.text.trim());
      final mileage = int.tryParse(_mileageController.text.trim()) ?? 0;

      if (_isEditing) {
        await repo.updateVehicle(
          householdId: widget.householdId,
          vehicleId: widget.existing!.id,
          manufacturer: _manufacturerController.text.trim(),
          model: _modelController.text.trim(),
          year: year,
          licensePlate: _plateController.text.trim(),
          licenseExpiryDate: _licenseExpiry,
          mandatoryInsuranceExpiryDate: _mandatoryInsuranceExpiry,
          comprehensiveInsuranceExpiryDate: _comprehensiveInsuranceExpiry,
        );
      } else {
        await repo.addVehicle(
          householdId: widget.householdId,
          manufacturer: _manufacturerController.text.trim(),
          model: _modelController.text.trim(),
          year: year,
          licensePlate: _plateController.text.trim(),
          currentMileage: mileage,
          licenseExpiryDate: _licenseExpiry,
          mandatoryInsuranceExpiryDate: _mandatoryInsuranceExpiry,
          comprehensiveInsuranceExpiryDate: _comprehensiveInsuranceExpiry,
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

  Widget _dateRow({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback? onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value != null ? DateFormatter.short(value) : AppStrings.notSetLabel,
        textDirection: TextDirection.ltr,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null && onClear != null)
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear),
          const Icon(Icons.calendar_today_outlined),
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editVehicleTitle : AppStrings.addVehicleTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(labelText: AppStrings.manufacturerLabel),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.requiredFieldError : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: AppStrings.modelLabel),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.requiredFieldError : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: AppStrings.yearLabel),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plateController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: AppStrings.licensePlateLabel),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.requiredFieldError : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  enabled: !_isEditing,
                  decoration: InputDecoration(
                    labelText: AppStrings.currentMileageLabel,
                    helperText: _isEditing ? AppStrings.mileageEditedElsewhereHint : null,
                  ),
                  validator: (v) {
                    if (_isEditing) return null;
                    if (v == null || v.trim().isEmpty) return AppStrings.requiredFieldError;
                    if (int.tryParse(v.trim()) == null) return AppStrings.numberOnlyError;
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(AppStrings.importantDatesTitle, style: AppTextStyles.heading2),
                _dateRow(
                  label: AppStrings.licenseExpiryLabel,
                  value: _licenseExpiry,
                  onTap: () => _pickDate(
                    current: _licenseExpiry,
                    onPicked: (d) => setState(() => _licenseExpiry = d),
                  ),
                  onClear: () => setState(() => _licenseExpiry = null),
                ),
                _dateRow(
                  label: AppStrings.mandatoryInsuranceLabel,
                  value: _mandatoryInsuranceExpiry,
                  onTap: () => _pickDate(
                    current: _mandatoryInsuranceExpiry,
                    onPicked: (d) => setState(() => _mandatoryInsuranceExpiry = d),
                  ),
                  onClear: () => setState(() => _mandatoryInsuranceExpiry = null),
                ),
                _dateRow(
                  label: AppStrings.comprehensiveInsuranceLabel,
                  value: _comprehensiveInsuranceExpiry,
                  onTap: () => _pickDate(
                    current: _comprehensiveInsuranceExpiry,
                    onPicked: (d) => setState(() => _comprehensiveInsuranceExpiry = d),
                  ),
                  onClear: () => setState(() => _comprehensiveInsuranceExpiry = null),
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
VEHICLES_MODULE_EOF

echo "כותב lib/features/vehicles/vehicle_detail_screen.dart..."
cat > lib/features/vehicles/vehicle_detail_screen.dart << 'VEHICLES_MODULE_EOF'
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
/// היסטוריית הטיפולים שכבר בוצעו.
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
                title: Text(vehicle.displayName),
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
                      _ServiceHistoryList(householdId: householdId, vehicleId: vehicle.id),
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
/// כל אחד עם מספר הימים שנשארו, בצבע לפי דחיפות. זה בדיוק הבקשה
/// ל"כתוב למעלה בצורה מושקעת כמה ימים נשארו לחידוש".
class _DatesHeaderCard extends StatelessWidget {
  final Vehicle vehicle;
  const _DatesHeaderCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      Text(vehicle.displayName, style: AppTextStyles.heading2),
                      Text(
                        vehicle.licensePlate,
                        style: AppTextStyles.bodySecondary,
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        shape: BoxShape.circle,
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            days == null
                ? AppStrings.notSetLabel
                : days < 0
                    ? AppStrings.expiredLabel
                    : '$days ${AppStrings.daysLabel}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
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
      child: ListTile(
        leading: const Icon(Icons.speed_outlined, color: AppColors.primary),
        title: Text(AppStrings.currentMileageLabel),
        subtitle: Text(
          '${vehicle.currentMileage} ${AppStrings.kmUnit}',
          style: AppTextStyles.heading2,
          textDirection: TextDirection.ltr,
        ),
        trailing: OutlinedButton(
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

  const _MaintenanceSection({
    required this.householdId,
    required this.vehicle,
    required this.onEditInterval,
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
          children: kMaintenanceTemplateNames.entries.map((entry) {
            final key = entry.key;
            final name = entry.value;
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
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(name),
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

class _ServiceHistoryList extends ConsumerWidget {
  final String householdId;
  final String vehicleId;

  const _ServiceHistoryList({required this.householdId, required this.vehicleId});

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
        return Column(
          children: records.map((record) => _ServiceRecordTile(
                record: record,
                householdId: householdId,
                vehicleId: vehicleId,
              )).toList(),
        );
      },
    );
  }
}

class _ServiceRecordTile extends ConsumerWidget {
  final VehicleServiceRecord record;
  final String householdId;
  final String vehicleId;

  const _ServiceRecordTile({
    required this.record,
    required this.householdId,
    required this.vehicleId,
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
        ),
      ),
    );
  }
}
VEHICLES_MODULE_EOF

echo "כותב lib/features/vehicles/add_service_record_screen.dart..."
cat > lib/features/vehicles/add_service_record_screen.dart << 'VEHICLES_MODULE_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicles_provider.dart';

/// טופס תיעוד טיפול שבוצע - סוג הטיפול (מהרשימה הקבועה או "אחר"
/// עם טקסט חופשי), תאריך, ק"מ בזמן הטיפול, ואופציונלית עלות והערות.
/// שמירה מעדכנת גם את הקילומטראז' הנוכחי של הרכב אם צריך (ראה
/// VehiclesService.addServiceRecord).
class AddServiceRecordScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String vehicleId;
  final int currentMileage;
  final String? initialTemplateKey;

  const AddServiceRecordScreen({
    super.key,
    required this.householdId,
    required this.vehicleId,
    required this.currentMileage,
    this.initialTemplateKey,
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
  DateTime _performedAt = DateTime.now();
  bool _isSaving = false;

  static const _otherKey = '__other__';

  @override
  void initState() {
    super.initState();
    _mileageController = TextEditingController(text: widget.currentMileage.toString());
    _costController = TextEditingController();
    _notesController = TextEditingController();
    _customTypeController = TextEditingController();
    _selectedTemplateKey = widget.initialTemplateKey ?? kMaintenanceTemplateNames.keys.first;
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

      await ref.read(vehiclesRepositoryProvider).addServiceRecord(
            householdId: widget.householdId,
            vehicleId: widget.vehicleId,
            serviceType: serviceType,
            performedAt: _performedAt,
            mileageAtService: mileage,
            cost: cost,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );

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
      appBar: AppBar(title: const Text(AppStrings.addServiceRecordTitle)),
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
VEHICLES_MODULE_EOF

echo "כותב lib/features/home/home_modules.dart..."
cat > lib/features/home/home_modules.dart << 'VEHICLES_MODULE_EOF'
import 'package:flutter/material.dart';
import 'home_module.dart';
import '../shopping/shopping_choice_screen.dart';
import '../vehicles/vehicles_list_screen.dart';

/// 4 המודולים ה"מומלצים" שמוצגים בכרטיסיות סטטיסטיקה צבעוניות
/// בראש מסך הבית (בהשראת עיצוב שהמשתמש שלח) - קניות (פעיל), ואז
/// משימות/רכבים/לוח שנה כ"בקרוב" (לוח שנה כן מציג נתון אמיתי,
/// המבוסס על תאריכי רשימות קניות קיימים - ראה home_screen.dart).
List<HomeModule> buildFeaturedModules({required String householdId}) {
  return [
    HomeModule(
      title: 'קניות',
      subtitle: 'פריטים ברשימה',
      icon: Icons.shopping_cart_outlined,
      isAvailable: true,
      screenBuilder: (_) => ShoppingChoiceScreen(householdId: householdId),
    ),
    const HomeModule(
      title: 'לוח שנה',
      subtitle: 'אירועים קרובים',
      icon: Icons.calendar_month_outlined,
    ),
    const HomeModule(
      title: 'משימות',
      subtitle: 'ניהול משק הבית היומיומי',
      icon: Icons.checklist_outlined,
    ),
    HomeModule(
      title: 'רכבים',
      subtitle: 'טסטים, טיפולים וקילומטראז\'',
      icon: Icons.directions_car_outlined,
      isAvailable: true,
      screenBuilder: (_) => VehiclesListScreen(householdId: householdId),
    ),
  ];
}

/// שאר מודולי העתיד - מוצגים ברשת הרגילה מתחת לכרטיסיות המומלצות,
/// כולם עדיין "בקרוב". "חשבונות" הוסר מכאן - יש כבר מודול חשבונות
/// מלא ופעיל במסך הבית, אז אריח כפול כאן רק מבלבל.
///
/// כדי להוסיף מודול חדש בעתיד:
/// 1. בונים את המסך שלו תחת lib/features/<module_name>/
/// 2. מוסיפים כאן HomeModule עם isAvailable: true ו-screenBuilder מתאים
List<HomeModule> buildHomeModules({required String householdId}) {
  return const [
    HomeModule(
      title: 'ביטוחים',
      subtitle: 'פוליסות ותאריכי חידוש',
      icon: Icons.shield_outlined,
    ),
    HomeModule(
      title: 'רישיונות',
      subtitle: 'תעודות ומסמכים בעלי תוקף',
      icon: Icons.badge_outlined,
    ),
    HomeModule(
      title: 'חוגים',
      subtitle: 'פעילויות ולוחות זמנים',
      icon: Icons.sports_soccer_outlined,
    ),
    HomeModule(
      title: 'מסמכים',
      subtitle: 'קבצים ותעודות חשובות',
      icon: Icons.folder_outlined,
    ),
  ];
}
VEHICLES_MODULE_EOF

echo "מעדכן את app_strings.dart..."
python3 << 'APPSTRINGS_PATCH_EOF'
import json, re
path = 'lib/app/config/app_strings.dart'
entries = [('vehiclesTitle', 'רכבים'), ('noVehiclesYet', 'עדיין לא הוספת רכבים'), ('addVehicleButton', 'הוסף רכב'), ('addVehicleTitle', 'הוספת רכב'), ('editVehicleTitle', 'עריכת רכב'), ('manufacturerLabel', 'יצרן'), ('modelLabel', 'דגם'), ('yearLabel', 'שנת ייצור'), ('licensePlateLabel', 'מספר רישוי'), ('currentMileageLabel', "קילומטראז' נוכחי"), ('mileageEditedElsewhereHint', "ניתן לעדכן קילומטראז' ממסך פרטי הרכב"), ('importantDatesTitle', 'תאריכים חשובים'), ('licenseExpiryLabel', 'רישיון רכב'), ('mandatoryInsuranceLabel', 'ביטוח חובה'), ('comprehensiveInsuranceLabel', 'ביטוח מקיף'), ('notSetLabel', 'לא הוגדר'), ('expiredLabel', 'פג תוקף'), ('daysLabel', 'ימים'), ('licenseExpiredLabel', 'הרישיון פג תוקף'), ('daysUntilLicenseLabel', 'ימים לחידוש רישיון:'), ('deleteVehicleConfirmTitle', 'למחוק את'), ('deleteVehicleConfirmBody', 'פעולה זו תמחק את כל היסטוריית הטיפולים של הרכב ולא ניתן לשחזר אותה.'), ('updateMileageTitle', "עדכון קילומטראז'"), ('updateMileageButton', 'עדכן'), ('kmUnit', 'ק"מ'), ('editIntervalTitlePrefix', 'עריכת מרווח -'), ('editIntervalTooltip', 'ערוך מרווח טיפול'), ('intervalKmLabel', 'מרווח בק"מ'), ('maintenanceSectionTitle', 'טיפולים'), ('overdueByLabel', 'באיחור של'), ('remainingKmLabel', 'נותרו'), ('serviceHistoryTitle', 'היסטוריית טיפולים'), ('addServiceRecordButton', 'הוסף תיעוד טיפול'), ('addServiceRecordTitle', 'תיעוד טיפול חדש'), ('noServiceRecordsYet', 'עדיין לא תועדו טיפולים לרכב זה'), ('serviceTypeLabel', 'סוג הטיפול'), ('otherServiceTypeLabel', 'אחר'), ('serviceDateLabel', 'תאריך הטיפול'), ('mileageAtServiceLabel', 'ק"מ בזמן הטיפול'), ('costLabelOptional', 'עלות (לא חובה)'), ('notesLabelOptional', 'הערות (לא חובה)'), ('cancel', 'ביטול'), ('deleteAction', 'מחיקה'), ('saveButton', 'שמור'), ('requiredFieldError', 'שדה חובה'), ('numberOnlyError', 'יש להזין מספר בלבד')]
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
echo "=== הסתיים! מודול הרכבים הותקן בהצלחה ==="
echo "עכשיו תריץ: flutter pub get"
echo "ואז הפעל מחדש את שרת הפיתוח."
