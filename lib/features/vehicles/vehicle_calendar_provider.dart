import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../providers/vehicles_provider.dart';

/// אירוע תאריך-רכב בודד (רישיון/ביטוח חובה/ביטוח מקיף) - נבנה
/// מתוך נתוני הרכבים הקיימים, בלי לשמור שום דבר נוסף ב-Firestore.
/// זו רק "תרגום" של תאריכים שכבר קיימים על הרכב לתצוגה בלוח השנה
/// הכללי של האפליקציה (ר' calendar_tab_content.dart).
class VehicleDateEvent {
  final String vehicleLabel;
  final String dateLabel;
  final DateTime date;

  const VehicleDateEvent({
    required this.vehicleLabel,
    required this.dateLabel,
    required this.date,
  });
}

/// כל אירועי תאריכי הרכבים (מכל הרכבים ב-household) - רישיון,
/// ביטוח חובה, ביטוח מקיף, לכל רכב שיש לו תאריך מוגדר. מתעדכן
/// אוטומטית עם כל שינוי ברשימת הרכבים (מבוסס על vehiclesListProvider
/// הקיים, בלי מקור נתונים נפרד).
final vehicleDateEventsProvider =
    Provider.family<List<VehicleDateEvent>, String>((ref, householdId) {
  final vehicles = ref.watch(vehiclesListProvider(householdId)).value ?? [];
  final events = <VehicleDateEvent>[];

  for (final vehicle in vehicles) {
    if (vehicle.licenseExpiryDate != null) {
      events.add(VehicleDateEvent(
        vehicleLabel: vehicle.displayName,
        dateLabel: AppStrings.licenseExpiryLabel,
        date: vehicle.licenseExpiryDate!,
      ));
    }
    if (vehicle.mandatoryInsuranceExpiryDate != null) {
      events.add(VehicleDateEvent(
        vehicleLabel: vehicle.displayName,
        dateLabel: AppStrings.mandatoryInsuranceLabel,
        date: vehicle.mandatoryInsuranceExpiryDate!,
      ));
    }
    if (vehicle.comprehensiveInsuranceExpiryDate != null) {
      events.add(VehicleDateEvent(
        vehicleLabel: vehicle.displayName,
        dateLabel: AppStrings.comprehensiveInsuranceLabel,
        date: vehicle.comprehensiveInsuranceExpiryDate!,
      ));
    }
  }

  return events;
});
