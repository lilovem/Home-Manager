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
