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
                image: DecorationImage(
                  image: AssetImage(background.imageAsset!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.35),
                    BlendMode.darken,
                  ),
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
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
          ),
          child: SingleChildScrollView(
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
                        color: option.imageAsset == null ? Colors.white : null,
                        image: option.imageAsset != null
                            ? DecorationImage(
                                image: AssetImage(option.imageAsset!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: option.imageAsset == null
                          ? const Icon(Icons.block, size: 16, color: AppColors.textSecondary)
                          : null,
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
