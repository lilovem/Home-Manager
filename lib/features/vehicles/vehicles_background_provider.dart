import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// מנגנון בחירת "רקע" למסך רשימת הרכבים ולשאר מסכי הרכב - שמור
/// פר-household (לא גלובלי לכל האפליקציה, בכוונה - זה שייך רק
/// לקטגוריית רכבים). כתיבה/קריאה ישירות מול Firestore בלי לגעת
/// ב-household_model.dart הקיים, כדי לא להסתכן בשבירת קוד household
/// אחר - זה שדה נוסף "רך" (soft) שמתעלמים ממנו בכל מקום אחר שקורא
/// household.
///
/// הרקעים עצמם הם קבצי תמונה אמיתיים (JPEG) שנוצרו ב-AI ע"י המשתמשת
/// ונשמרים כ-assets מובנים באפליקציה (assets/vehicle_backgrounds/) -
/// לא ב-Firestore ולא ב-Firebase Storage, כך שאין עלות נוספת.
class VehiclesBackgroundOption {
  final String id;
  final String label;

  /// נתיב ה-asset של תמונת הרקע. null = 'ללא רקע'.
  final String? imageAsset;

  const VehiclesBackgroundOption({
    required this.id,
    required this.label,
    this.imageAsset,
  });
}

const List<VehiclesBackgroundOption> kVehiclesBackgrounds = [
  VehiclesBackgroundOption(id: 'none', label: 'ללא רקע'),
  VehiclesBackgroundOption(
    id: 'sunset_mountains',
    label: 'שקיעה בהרים',
    imageAsset: 'assets/vehicle_backgrounds/sunset_mountains.jpg',
  ),
  VehiclesBackgroundOption(
    id: 'red_coast_sunset',
    label: 'חוף אדום בשקיעה',
    imageAsset: 'assets/vehicle_backgrounds/red_coast_sunset.jpg',
  ),
  VehiclesBackgroundOption(
    id: 'blue_night_mountain',
    label: 'כחול לילה בהרים',
    imageAsset: 'assets/vehicle_backgrounds/blue_night_mountain.jpg',
  ),
  VehiclesBackgroundOption(
    id: 'yellow_palms_sunset',
    label: 'דקלים בשקיעה',
    imageAsset: 'assets/vehicle_backgrounds/yellow_palms_sunset.jpg',
  ),
  VehiclesBackgroundOption(
    id: 'city_dusk_road',
    label: 'כביש עירוני בדמדומים',
    imageAsset: 'assets/vehicle_backgrounds/city_dusk_road.jpg',
  ),
  VehiclesBackgroundOption(
    id: 'white_coast_sunset',
    label: 'חוף לבן בשקיעה',
    imageAsset: 'assets/vehicle_backgrounds/white_coast_sunset.jpg',
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
