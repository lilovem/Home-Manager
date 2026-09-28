import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import 'dart:typed_data';
import '../../models/vehicle_model.dart';
import '../../providers/vehicles_provider.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_photo_picker.dart';

/// צבע רקע אחיד לכל מסכי מודול הרכבים - גוון לילך-לבן רך, נבחר כדי
/// להשתלב עם הגרדיאנט הסגול הכהה של הכרטיסייה העליונה במסך פרטי
/// רכב, במקום רקע לבן סתמי.
const Color kVehiclesPageBackground = Color(0xFFF6F4FB);

/// צבע כותרות/תגיות קטנות על הרקע הבהיר (כמו "עלות ביטוח שנתית",
/// "המסע לחידוש") - גוון סגול כהה עמוק מאותה משפחת צבעים כמו
/// הכרטיסייה העליונה, כדי שהמסכים ירגישו כמערכת אחת.
const Color kVehiclesAccentText = Color(0xFF2E2A45);

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
      backgroundColor: kVehiclesPageBackground,
      appBar: AppBar(
        title: const Text(AppStrings.vehiclesTitle),
      ),
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
                    const Text(
                      AppStrings.noVehiclesYet,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.tapPlusToAddVehicle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
  final String? photoDataUrl;
  const _VehicleIcon({this.size = 48, this.photoDataUrl});

  @override
  Widget build(BuildContext context) {
    final photoBytes = decodeVehiclePhotoDataUrl(photoDataUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: photoBytes == null
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              )
            : null,
        shape: BoxShape.circle,
        image: photoBytes != null
            ? DecorationImage(
                image: MemoryImage(Uint8List.fromList(photoBytes)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: photoBytes == null
          ? Icon(Icons.directions_car_filled, color: Colors.white, size: size * 0.55)
          : null,
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
              _VehicleIcon(photoDataUrl: vehicle.photoDataUrl),
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

