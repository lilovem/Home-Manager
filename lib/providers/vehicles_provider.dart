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
