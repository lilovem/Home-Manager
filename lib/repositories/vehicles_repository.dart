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
