import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import '../../providers/vehicles_provider.dart';
import 'dart:typed_data';
import 'add_edit_vehicle_screen.dart';
import 'add_service_record_screen.dart';
import 'service_history_screen.dart';
import 'vehicle_photo_picker.dart';
import 'vehicles_background_provider.dart';
import 'vehicles_list_screen.dart' show colorForDaysRemaining, daysUntil;

/// אייקון קבוע לכל סוג טיפול - משותף בין הרשת (_MaintenanceSection),
/// בורר סוגי הטיפול, ותצוגת התקציר בכרטיס העליון.
const Map<String, IconData> _kMaintenanceIcons = {
  'oilChange': Icons.opacity,
  'majorService': Icons.build_circle_outlined,
  'tires': Icons.donut_large,
  'battery': Icons.battery_charging_full,
  'brakes': Icons.album_outlined,
};

/// סוגי הטיפול שניתן לערוך את הטווח שלהם ישירות מהכרטיס העליון -
/// רק טיפול קטן וטיפול גדול (הכי נפוצים), כדי שהכרטיס יישאר נקי
/// ומרווח. שאר סוגי הטיפול (מצבר/בלמים) עדיין עוקבים אוטומטית
/// ברשת שמתחת לכרטיס, לפי kTrackedMaintenanceKeys.
const List<String> _kAllMaintenanceKeys = [
  'oilChange',
  'majorService',
];

/// סטטוס טיפול מחושב עבור סוג טיפול בודד (כמה ק"מ נשארו/כמה איחור) -
/// מחושב פעם אחת ומשותף בין תצוגת "הטיפול הבא", רשת הטיפולים,
/// ותקציר הכרטיס העליון, כדי לא לכפול לוגיקה.
class MaintenanceStatus {
  final String key;
  final String name;
  final IconData icon;
  final Color color;
  final int remaining;
  final int interval;

  const MaintenanceStatus({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.remaining,
    required this.interval,
  });
}

List<MaintenanceStatus> computeMaintenanceStatuses(
  Vehicle vehicle,
  List<VehicleServiceRecord> records,
) {
  return kTrackedMaintenanceKeys.map((key) {
    final name = kMaintenanceTemplateNames[key] ?? key;
    final interval =
        vehicle.maintenanceIntervals[key] ?? kDefaultMaintenanceIntervals[key] ?? 10000;

    final matching = records.where((r) => r.serviceType == key).toList();
    // נקודת ההתחלה לספירה: הגבוה מבין (א) תיעוד טיפול אמיתי אחרון
    // מהסוג הזה, או אם אין - הקילומטראז' שהיה לרכב כשנוסף לאפליקציה
    // (initialMileage, כדי שלא ייראה מיד "באיחור ענק"), ו-(ב) איפוס
    // ידני של התזכורת (maintenanceResetMileage) - בלי צורך ברשומת
    // טיפול מזויפת בהיסטוריה.
    final realMileage = matching.isEmpty
        ? vehicle.initialMileage
        : matching.map((r) => r.mileageAtService).reduce((a, b) => a > b ? a : b);
    final resetMileage = vehicle.maintenanceResetMileage[key];
    final lastMileage =
        resetMileage != null && resetMileage > realMileage ? resetMileage : realMileage;
    final nextDue = lastMileage + interval;
    final remaining = nextDue - vehicle.currentMileage;

    final color = remaining < 0
        ? AppColors.error
        : remaining <= (interval * 0.1)
            ? Colors.orange
            : AppColors.itemPurchased;

    final icon = _kMaintenanceIcons[key] ?? Icons.build_outlined;

    return MaintenanceStatus(
      key: key,
      name: name,
      icon: icon,
      color: color,
      remaining: remaining,
      interval: interval,
    );
  }).toList();
}

/// חלונית פרטי טיפול משותפת - נפתחת מ"הטיפול הבא", מרשת הטיפולים,
/// ומבורר סוגי הטיפול. מציגה כמה נשאר/כמה איחור ותיאור קצר.
void showMaintenanceDetailSheet(BuildContext context, MaintenanceStatus status) {
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
                  decoration:
                      BoxDecoration(color: status.color.withOpacity(0.14), shape: BoxShape.circle),
                  child: Icon(status.icon, color: status.color),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(status.name, style: AppTextStyles.heading2)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              status.remaining < 0
                  ? '${AppStrings.overdueByLabel} ${-status.remaining} ${AppStrings.kmUnit}'
                  : '${AppStrings.nextServiceInLabel} ${status.remaining} ${AppStrings.kmUnit}',
              style: TextStyle(color: status.color, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              kMaintenanceTemplateDescriptions[status.key] ?? '',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

/// מסך פרטי רכב בודד - כרטיס עליון קבוע בגודלו (בדיוק כמו שהיה) עם 3
/// עמודים שמחליקים ביניהם (מסך ראשי/טיפולים/ביטוחים), ומתחתיו אזור
/// אחד שמשתנה אוטומטית לפי העמוד המוצג למעלה - כך שכל עמוד "מרגיש"
/// כמו מסך שלם, בלי גלילה בשום מקום.
class VehicleDetailScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String vehicleId;

  const VehicleDetailScreen({
    super.key,
    required this.householdId,
    required this.vehicleId,
  });

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  int _activePage = 0;

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
          .deleteVehicle(householdId: widget.householdId, vehicleId: vehicle.id);
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
            householdId: widget.householdId,
            vehicleId: vehicle.id,
            newMileage: result,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref
        .watch(vehicleDetailProvider((householdId: widget.householdId, vehicleId: widget.vehicleId)));
    final backgroundId =
        ref.watch(vehiclesBackgroundIdProvider(widget.householdId)).value ?? 'none';
    final background = backgroundOptionById(backgroundId);
    final hasBackground = background.id != 'none';

    // הסרגל העליון: רק בעמוד הראשון (קילומטראז') מוצגים כותרת "פרטי
    // רכב" ואייקוני עריכה/מחיקה - בעמודים 2-3 (טיפולים/ביטוחים) נשאר
    // רק אייקון חזרה בודד (יציאה מהמסך), בלי רקע צבעוני.
    final isMainPage = _activePage == 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: hasBackground ? Colors.white : AppColors.primaryDark,
        title: isMainPage ? const Text(AppStrings.vehicleDetailsTitle) : null,
        actions: !isMainPage
            ? const []
            : vehicleAsync.maybeWhen(
                data: (vehicle) => vehicle == null
                    ? const []
                    : [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditVehicleScreen(
                                householdId: widget.householdId,
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
                orElse: () => const [],
              ),
      ),
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

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DatesHeaderCard(
                      householdId: widget.householdId,
                      vehicle: vehicle,
                      onPageChanged: (i) => setState(() => _activePage = i),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _BottomContentArea(
                        page: _activePage,
                        householdId: widget.householdId,
                        vehicle: vehicle,
                        onUpdateMileage: () => _updateMileage(context, ref, vehicle),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// כרטיס בולט למעלה - קבוע בגודלו (בדיוק כמו שהיה) עם 3 עמודים
/// ניתנים להחלקה: עמוד 1 - מסך ראשי (תמונה/שם/מספר רישוי + 3 צ'יפים
/// עם כמות הימים שנותרו). עמוד 2 - תקציר "טיפולים". עמוד 3 -
/// "ביטוחים" (מסמכים עם העלאה/צפייה/מחיקה/שיתוף). שלושת העמודים על
/// אותו רקע גרדיאנט כהה. משנה עמוד גם מדווח החוצה (onPageChanged) כדי
/// שהאזור שמתחת לכרטיס ידע איזה תוכן להציג.
class _DatesHeaderCard extends ConsumerStatefulWidget {
  final String householdId;
  final Vehicle vehicle;
  final ValueChanged<int> onPageChanged;
  const _DatesHeaderCard({
    required this.householdId,
    required this.vehicle,
    required this.onPageChanged,
  });

  @override
  ConsumerState<_DatesHeaderCard> createState() => _DatesHeaderCardState();
}

class _DatesHeaderCardState extends ConsumerState<_DatesHeaderCard> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveDocument(String fieldKey, String? dataUrl) {
    return ref.read(vehiclesRepositoryProvider).updateDocumentPhoto(
          householdId: widget.householdId,
          vehicleId: widget.vehicle.id,
          fieldKey: fieldKey,
          dataUrl: dataUrl,
        );
  }

  Future<void> _uploadPhotoDocument(String fieldKey, {required bool useCamera}) async {
    final dataUrl = await pickAndCompressPhoto(useCamera: useCamera);
    if (dataUrl == null) return;
    await _saveDocument(fieldKey, dataUrl);
  }

  Future<void> _uploadPdfDocument(String fieldKey) async {
    final dataUrl = await pickPdfDataUrl();
    if (dataUrl == null) return;
    if (dataUrlSizeBytes(dataUrl) > 700 * 1024) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(AppStrings.fileTooLargeTitle),
          content: const Text(AppStrings.fileTooLargeMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.okButton),
            ),
          ],
        ),
      );
      return;
    }
    await _saveDocument(fieldKey, dataUrl);
  }

  /// פותחת חלונית תחתונה עם 3 דרכי הוספה - צילום ישיר, גלריה, או
  /// קובץ PDF - כדי לרכז את כל אפשרויות ההוספה בלחיצה אחת נקייה
  /// במקום כמה כפתורים נפרדים בשורה.
  void _showUploadSourceSheet(BuildContext context, String fieldKey) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text(AppStrings.takePhotoOption),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _uploadPhotoDocument(fieldKey, useCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text(AppStrings.choosePhotoOption),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _uploadPhotoDocument(fieldKey, useCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
              title: const Text(AppStrings.choosePdfOption),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _uploadPdfDocument(fieldKey);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDocument(BuildContext context, String fieldKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteDocumentConfirmTitle),
        content: const Text(AppStrings.deleteDocumentConfirmMessage),
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
      await _saveDocument(fieldKey, null);
    }
  }

  Future<void> _shareDocument(String dataUrl) async {
    final isPdf = mimeTypeOfDataUrl(dataUrl) == 'application/pdf';
    final fileName = isPdf ? 'document.pdf' : 'document.jpg';
    final shared = await shareDataUrlFile(
      dataUrl: dataUrl,
      fileName: fileName,
      title: AppStrings.appName,
    );
    if (!shared) {
      downloadDataUrlFile(dataUrl: dataUrl, fileName: fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.shareFallbackDownloadMessage)),
        );
      }
    }
  }

  void _viewDocument(BuildContext context, String? dataUrl) {
    if (dataUrl == null) return;
    if (mimeTypeOfDataUrl(dataUrl) == 'application/pdf') {
      openDataUrlInNewTab(dataUrl);
      return;
    }
    final bytes = decodeVehiclePhotoDataUrl(dataUrl);
    if (bytes == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            InteractiveViewer(
              child: Image.memory(Uint8List.fromList(bytes)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () => _shareDocument(dataUrl),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
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
          SizedBox(
            height: 210,
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) {
                setState(() => _page = i);
                widget.onPageChanged(i);
              },
              children: [
                _MainInfoPage(householdId: widget.householdId, vehicle: vehicle),
                _MaintenanceTopPreview(householdId: widget.householdId, vehicle: vehicle),
                _InsurancePage(
                  vehicle: vehicle,
                  onUploadTap: _showUploadSourceSheet,
                  onView: _viewDocument,
                  onDelete: _confirmDeleteDocument,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _page == i ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// עמוד 1 בהחלקה - התוכן המקורי: תמונה/שם/מספר רישוי, ומתחת 3
/// צ'יפים עם כמות הימים שנותרו לכל תאריך (בדיוק כמו שהיה).
class _MainInfoPage extends StatelessWidget {
  final String householdId;
  final Vehicle vehicle;
  const _MainInfoPage({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _VehicleIconLarge(householdId: householdId, vehicle: vehicle),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vehicle.displayName,
                    style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    vehicle.licensePlate,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
    );
  }
}

/// עמוד 2 בהחלקה - "טיפולים": כותרת + רשימה אופקית של 5 סוגי הטיפול
/// (כולל צמיגים) עם אייקון ירוק לכל אחד - לחיצה על אחד פותחת עריכת
/// המרווח שלו, וכפתור "+" בסוף פותח הוספת תיעוד טיפול. זו הדרך
/// היחידה להגדיר טווחים - קלטה את מקום חלונית ה-☰ הישנה.
class _MaintenanceTopPreview extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;
  const _MaintenanceTopPreview({required this.householdId, required this.vehicle});

  static const Color _greenIcon = Color(0xFF6FE0A0);

  static const Map<String, String> _shortNames = {
    'oilChange': 'קטן',
    'majorService': 'גדול',
    'tires': 'צמיגים',
    'battery': 'מצבר',
    'brakes': 'בלמים',
  };

  Widget _tile(BuildContext context, WidgetRef ref, String key) {
    final shortName = _shortNames[key] ?? kMaintenanceTemplateNames[key] ?? key;
    final icon = _kMaintenanceIcons[key] ?? Icons.build_outlined;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddServiceRecordScreen(
              householdId: householdId,
              vehicleId: vehicle.id,
              currentMileage: vehicle.currentMileage,
              initialTemplateKey: key,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(icon, color: _greenIcon, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                shortName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addTile(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddServiceRecordScreen(
              householdId: householdId,
              vehicleId: vehicle.id,
              currentMileage: vehicle.currentMileage,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _greenIcon.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: _greenIcon.withOpacity(0.5)),
                ),
                child: Icon(Icons.add, color: _greenIcon, size: 26),
              ),
              const SizedBox(height: 6),
              const Text(
                AppStrings.addMaintenanceTooltip,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _MaintenanceSettingsSheet(householdId: householdId, vehicle: vehicle),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
              ),
              const SizedBox(height: 6),
              const Text(
                AppStrings.maintenanceSettingsTooltip,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.maintenancePageTitle,
          style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ..._kAllMaintenanceKeys.map((key) => _tile(context, ref, key)),
            _settingsTile(context),
            _addTile(context),
          ],
        ),
      ],
    );
  }
}

/// עריכת מרווח טיפול (בק"מ) - פונקציה משותפת בשימוש מתוך חלונית
/// ההגדרות בלבד (לחיצה על אריח הטיפול עצמו עברה להוספת תיעוד טיפול).
Future<void> _editMaintenanceIntervalDialog(
  BuildContext context,
  WidgetRef ref,
  String householdId,
  String vehicleId,
  String key,
  String name,
  int currentInterval,
) async {
  final controller = TextEditingController(text: currentInterval.toString());
  final result = await showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('${AppStrings.editIntervalTitlePrefix} $name'),
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
          onPressed: () => Navigator.of(dialogContext).pop(int.tryParse(controller.text.trim())),
          child: const Text(AppStrings.saveButton),
        ),
      ],
    ),
  );
  if (result != null && result > 0) {
    await ref.read(vehiclesRepositoryProvider).updateMaintenanceInterval(
          householdId: householdId,
          vehicleId: vehicleId,
          templateKey: key,
          intervalKm: result,
        );
  }
}

/// חלונית "הגדרות טיפולים" - נפתחת מהאייקון החדש בכרטיסיית הטיפולים.
/// שני חלקים: עריכת מרווחי טיפול קטן/גדול (בק"מ), ואיפוס התראות
/// שעברו - שומר "נקודת איפוס" בקילומטראז' הנוכחי (maintenanceResetMileage),
/// בלי להוסיף רשומת טיפול מזויפת להיסטוריה, כדי שהמונה יתחיל
/// להימנות מחדש מרגע האיפוס.
class _MaintenanceSettingsSheet extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _MaintenanceSettingsSheet({required this.householdId, required this.vehicle});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref, MaintenanceStatus status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${AppStrings.resetMaintenanceConfirmTitle} ${status.name}'),
        content: const Text(AppStrings.resetMaintenanceConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.resetAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(vehiclesRepositoryProvider).resetMaintenanceBaseline(
            householdId: householdId,
            vehicleId: vehicle.id,
            templateKey: status.key,
            mileage: vehicle.currentMileage,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.resetMaintenanceDoneMessage} ${status.name}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(
      vehicleServiceRecordsProvider((householdId: householdId, vehicleId: vehicle.id)),
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.maintenanceSettingsTitle, style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Text(
                AppStrings.editIntervalsSectionTitle,
                style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold),
              ),
              ..._kAllMaintenanceKeys.map((key) {
                final name = kMaintenanceTemplateNames[key] ?? key;
                final interval =
                    vehicle.maintenanceIntervals[key] ?? kDefaultMaintenanceIntervals[key] ?? 10000;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(name),
                  subtitle: Text('$interval ${AppStrings.kmUnit}'),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _editMaintenanceIntervalDialog(
                      context, ref, householdId, vehicle.id, key, name, interval),
                );
              }),
              const Divider(height: 28),
              Text(
                AppStrings.resetOverdueSectionTitle,
                style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold),
              ),
              recordsAsync.when(
                data: (records) {
                  final statuses = computeMaintenanceStatuses(vehicle, records);
                  return Column(
                    children: statuses.map((s) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration:
                              BoxDecoration(color: s.color.withOpacity(0.15), shape: BoxShape.circle),
                          child: Icon(s.icon, color: s.color, size: 18),
                        ),
                        title: Text(s.name),
                        subtitle: Text(
                          s.remaining < 0
                              ? '${AppStrings.overdueByLabel} ${-s.remaining} ${AppStrings.kmUnit}'
                              : '${AppStrings.nextServiceInLabel} ${s.remaining} ${AppStrings.kmUnit}',
                          style: TextStyle(color: s.color, fontWeight: FontWeight.bold),
                        ),
                        trailing: TextButton(
                          onPressed: () => _confirmReset(context, ref, s),
                          child: const Text(AppStrings.resetAction),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// עמוד 3 בהחלקה - "ביטוחים": שורה לכל אחד מ-3 התאריכים (רישיון,
/// ביטוח חובה, ביטוח מקיף) עם התאריך עצמו, וכפתור להעלאת/צפייה
/// בקובץ סרוק/מצולם של המסמך הפיזי (בדיוק כמו שהיה).
class _InsurancePage extends StatelessWidget {
  final Vehicle vehicle;
  final void Function(BuildContext context, String fieldKey) onUploadTap;
  final void Function(BuildContext context, String? dataUrl) onView;
  final void Function(BuildContext context, String fieldKey) onDelete;

  const _InsurancePage({
    required this.vehicle,
    required this.onUploadTap,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        label: AppStrings.licenseExpiryLabel,
        date: vehicle.licenseExpiryDate,
        fieldKey: 'licenseDocumentDataUrl',
        documentDataUrl: vehicle.licenseDocumentDataUrl,
      ),
      (
        label: AppStrings.mandatoryInsuranceLabel,
        date: vehicle.mandatoryInsuranceExpiryDate,
        fieldKey: 'mandatoryInsuranceDocumentDataUrl',
        documentDataUrl: vehicle.mandatoryInsuranceDocumentDataUrl,
      ),
      (
        label: AppStrings.comprehensiveInsuranceLabel,
        date: vehicle.comprehensiveInsuranceExpiryDate,
        fieldKey: 'comprehensiveInsuranceDocumentDataUrl',
        documentDataUrl: vehicle.comprehensiveInsuranceDocumentDataUrl,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.insuranceDocumentsTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...rows.map((row) {
          final days = daysUntil(row.date);
          final color = colorForDaysRemaining(days);
          final displayColor = days != null && days > 30 ? const Color(0xFF7CE0C6) : color;
          final hasDocument = row.documentDataUrl != null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.label,
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        row.date == null ? AppStrings.notSetLabel : formatPrettyDateHe(row.date!),
                        style: TextStyle(
                            color: displayColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (hasDocument)
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, color: Colors.white, size: 20),
                    tooltip: AppStrings.viewDocumentTooltip,
                    onPressed: () => onView(context, row.documentDataUrl),
                  ),
                IconButton(
                  icon: Icon(
                    hasDocument ? Icons.sync : Icons.upload_file_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: AppStrings.uploadDocumentTooltip,
                  onPressed: () => onUploadTap(context, row.fieldKey),
                ),
                if (hasDocument)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B), size: 20),
                    tooltip: AppStrings.deleteDocumentTooltip,
                    onPressed: () => onDelete(context, row.fieldKey),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// אזור שמוצג מתחת לכרטיס העליון - מתחלף אוטומטית לפי העמוד שמוצג
/// למעלה (page), כדי שכל עמוד ירגיש מלא ומעניין בלי גלילה.
class _BottomContentArea extends StatelessWidget {
  final int page;
  final String householdId;
  final Vehicle vehicle;
  final VoidCallback onUpdateMileage;

  const _BottomContentArea({
    required this.page,
    required this.householdId,
    required this.vehicle,
    required this.onUpdateMileage,
  });

  @override
  Widget build(BuildContext context) {
    switch (page) {
      case 1:
        return _MaintenanceBottom(householdId: householdId, vehicle: vehicle);
      case 2:
        return _InsuranceBottom(householdId: householdId, vehicle: vehicle);
      default:
        return _MainInfoBottom(
          householdId: householdId,
          vehicle: vehicle,
          onUpdateMileage: onUpdateMileage,
        );
    }
  }
}

/// אזור תחתון לעמוד 1 - קילומטראז' (עם עריכה, בדיוק כמו שהיה) ומתחתיו
/// "הטיפול הבא" (הכי דחוף מתוך כל סוגי הטיפול העוקבים).
class _MainInfoBottom extends StatelessWidget {
  final String householdId;
  final Vehicle vehicle;
  final VoidCallback onUpdateMileage;

  const _MainInfoBottom({
    required this.householdId,
    required this.vehicle,
    required this.onUpdateMileage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Center(child: _MileageCard(vehicle: vehicle, onUpdate: onUpdateMileage)),
        const SizedBox(height: 12),
        _NextServiceCard(householdId: householdId, vehicle: vehicle),
        const SizedBox(height: 12),
        _NotesCard(householdId: householdId, vehicle: vehicle),
      ],
    );
  }
}

/// הערה חופשית לרכב - טקסט קצר שאפשר להוסיף/לערוך/למחוק בכל רגע
/// (למשל תזכורת "לבדוק לחץ אוויר"), נשמר ישירות במסמך הרכב.
class _NotesCard extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _NotesCard({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNotes = vehicle.notes != null && vehicle.notes!.isNotEmpty;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _NotesEditScreen(householdId: householdId, vehicle: vehicle),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        color: Colors.white.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sticky_note_2_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.notesTitle,
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                    ),
                    if (hasNotes)
                      Text(
                        vehicle.notes!,
                        style: AppTextStyles.heading2.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// מסך מלא (לא חלונית קטנה) לעריכת ההערה/תזכורת של הרכב - כדי שיהיה
/// מקום נוח לכתוב הערה ארוכה יותר (למשל "לא לשכוח לקנות שמן לרכב").
class _NotesEditScreen extends ConsumerStatefulWidget {
  final String householdId;
  final Vehicle vehicle;

  const _NotesEditScreen({required this.householdId, required this.vehicle});

  @override
  ConsumerState<_NotesEditScreen> createState() => _NotesEditScreenState();
}

class _NotesEditScreenState extends ConsumerState<_NotesEditScreen> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.vehicle.notes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await ref.read(vehiclesRepositoryProvider).updateNotes(
          householdId: widget.householdId,
          vehicleId: widget.vehicle.id,
          notes: _controller.text,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteDocumentConfirmTitle),
        content: const Text(AppStrings.deleteDocumentConfirmMessage),
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
      await ref.read(vehiclesRepositoryProvider).updateNotes(
            householdId: widget.householdId,
            vehicleId: widget.vehicle.id,
            notes: null,
          );
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = widget.vehicle.notes != null && widget.vehicle.notes!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notesTitle),
        actions: [
          if (hasNotes)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: AppStrings.deleteDocumentTooltip,
              onPressed: _isSaving ? null : _delete,
            ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: AppStrings.saveButton,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: AppTextStyles.heading2.copyWith(fontSize: 16, fontWeight: FontWeight.normal),
          decoration: const InputDecoration(
            hintText: AppStrings.notesHint,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

/// כרטיס "הטיפול הבא" - מציג את הפריט הכי דחוף מתוך כל סוגי הטיפול
/// העוקבים, בסגנון עקבי לכרטיס הקילומטראז' שמעליו.
class _NextServiceCard extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _NextServiceCard({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(
      vehicleServiceRecordsProvider((householdId: householdId, vehicleId: vehicle.id)),
    );

    return recordsAsync.when(
      data: (records) {
        final statuses = computeMaintenanceStatuses(vehicle, records)
          ..sort((a, b) => a.remaining.compareTo(b.remaining));
        if (statuses.isEmpty) return const SizedBox.shrink();
        final next = statuses.first;

        return InkWell(
          onTap: () => showMaintenanceDetailSheet(context, next),
          borderRadius: BorderRadius.circular(16),
          child: Card(
            elevation: 2,
            color: Colors.white.withOpacity(0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration:
                        BoxDecoration(color: next.color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(next.icon, color: next.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.nextServiceLabel,
                          style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                        ),
                        Text(next.name, style: AppTextStyles.heading2.copyWith(fontSize: 15)),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      children: [
                        TextSpan(
                          text: next.remaining < 0
                              ? '${AppStrings.overdueByLabel} '
                              : '${AppStrings.nextServiceInLabel} ',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        TextSpan(
                          text:
                              '${next.remaining < 0 ? -next.remaining : next.remaining} ${AppStrings.kmUnit}',
                          style: TextStyle(color: next.color),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

/// אזור תחתון לעמוד 2 - כפתור "היסטוריית טיפולים" ממש מתחת לכרטיס,
/// ומתחתיו רשת 4 הטיפולים העוקבים (טיפול קטן/גדול/מצבר/בלמים),
/// בפריסה שמתאימה בדיוק לגובה הפנוי - כדי שלא יחתכו/יגלשו מחוץ
/// למסך. הגדרת הטווחים עברה לכרטיס העליון עצמו (עמוד 2 שם).
class _MaintenanceBottom extends StatelessWidget {
  final String householdId;
  final Vehicle vehicle;

  const _MaintenanceBottom({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServiceHistoryScreen(
                  householdId: householdId,
                  vehicleId: vehicle.id,
                  currentMileage: vehicle.currentMileage,
                ),
              ),
            ),
            icon: const Icon(Icons.history, size: 18),
            label: const Text(AppStrings.serviceHistoryButton),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _MaintenanceSection(householdId: householdId, vehicle: vehicle),
        ),
      ],
    );
  }
}

/// רשת 4 הטיפולים העוקבים - בנויה מ-Row/Column עם Expanded בכל תא,
/// כך שהיא תמיד תופסת בדיוק את הגובה הפנוי שקיבלה (לא יכולה לגלוש
/// מחוץ למסך, בשונה מ-GridView עם יחס-רוחב קבוע). לחיצה על תא פותחת
/// חלונית עם כל הפרטים.
class _MaintenanceSection extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _MaintenanceSection({
    required this.householdId,
    required this.vehicle,
  });

  Widget _tile(BuildContext context, MaintenanceStatus s) {
    final isUrgent = s.remaining < 0;
    return Material(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showMaintenanceDetailSheet(context, s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: s.color.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration:
                        BoxDecoration(color: s.color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(s.icon, color: s.color, size: 14),
                  ),
                  const Spacer(),
                  if (isUrgent) const Icon(Icons.error, color: AppColors.error, size: 13),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
              ),
              Text(
                s.remaining < 0
                    ? '${AppStrings.overdueByLabel} ${-s.remaining} ${AppStrings.kmUnit}'
                    : '${AppStrings.nextServiceInLabel} ${s.remaining} ${AppStrings.kmUnit}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: s.color, fontWeight: FontWeight.bold, fontSize: 11),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const SizedBox.shrink(),
      data: (records) {
        final statuses = computeMaintenanceStatuses(vehicle, records);
        if (statuses.length < 4) return const SizedBox.shrink();

        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(context, statuses[0])),
                  const SizedBox(width: 10),
                  Expanded(child: _tile(context, statuses[1])),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(context, statuses[2])),
                  const SizedBox(width: 10),
                  Expanded(child: _tile(context, statuses[3])),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// אזור תחתון לעמוד 3 - עלות ביטוח שנתית (חובה/מקיף, עריכה בהקשה)
/// ו"מסע לחידוש" ויזואלי לכל אחד מ-3 המסמכים (רישיון/חובה/מקיף).
class _InsuranceBottom extends StatelessWidget {
  final String householdId;
  final Vehicle vehicle;

  const _InsuranceBottom({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.insuranceAnnualCostTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading2.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 6),
        _InsuranceCostRow(householdId: householdId, vehicle: vehicle),
        const SizedBox(height: 18),
        Text(
          AppStrings.renewalJourneyTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading2.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 8),
        _RenewalJourneyRow(
          label: AppStrings.licenseExpiryLabel,
          icon: Icons.badge_outlined,
          expiryDate: vehicle.licenseExpiryDate,
          color: const Color(0xFF4F9DDE),
        ),
        _RenewalJourneyRow(
          label: AppStrings.mandatoryInsuranceLabel,
          icon: Icons.shield_outlined,
          expiryDate: vehicle.mandatoryInsuranceExpiryDate,
          color: const Color(0xFFE0982E),
        ),
        _RenewalJourneyRow(
          label: AppStrings.comprehensiveInsuranceLabel,
          icon: Icons.security,
          expiryDate: vehicle.comprehensiveInsuranceExpiryDate,
          color: const Color(0xFF3FA97A),
        ),
      ],
    );
  }
}

/// שני שדות עריכה קומפקטיים לעלות הביטוח השנתית (חובה/מקיף) - הקשה
/// פותחת חלונית להזנת סכום, נשמר ישירות למסמך הרכב.
class _InsuranceCostRow extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _InsuranceCostRow({required this.householdId, required this.vehicle});

  Future<void> _editCost(
    BuildContext context,
    WidgetRef ref,
    String fieldKey,
    double? current,
  ) async {
    final controller =
        TextEditingController(text: current == null ? '' : current.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.editInsuranceCostTitle),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          autofocus: true,
          decoration: const InputDecoration(labelText: AppStrings.insuranceCostFieldLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(double.tryParse(controller.text.trim())),
            child: const Text(AppStrings.saveButton),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(vehiclesRepositoryProvider).updateInsuranceCost(
            householdId: householdId,
            vehicleId: vehicle.id,
            fieldKey: fieldKey,
            cost: result,
          );
    }
  }

  Widget _chip(BuildContext context, WidgetRef ref, String label, String fieldKey, double? cost) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editCost(context, ref, fieldKey, cost),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTextStyles.bodySecondary.copyWith(fontSize: 10)),
              Text(
                cost == null ? AppStrings.notSetCostLabel : '₪${cost.toStringAsFixed(0)}',
                style: AppTextStyles.heading2.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _chip(
          context,
          ref,
          AppStrings.mandatoryInsuranceLabel,
          'mandatoryInsuranceAnnualCost',
          vehicle.mandatoryInsuranceAnnualCost,
        ),
        const SizedBox(width: 10),
        _chip(
          context,
          ref,
          AppStrings.comprehensiveInsuranceLabel,
          'comprehensiveInsuranceAnnualCost',
          vehicle.comprehensiveInsuranceAnnualCost,
        ),
      ],
    );
  }
}

/// "מסע לחידוש" - שורה קומפקטית אחת: אייקון+שם, כביש עם רכב שנוסע
/// לכיוון דגל (יעד = תאריך התפוגה) לפי אחוז הזמן שחלף, וכמות הימים
/// שנשארו. מכיוון שאין לנו תאריך תחילת פוליסה שמור, ההתקדמות
/// מחושבת יחסית לשנה אחורה מהתפוגה (הערכה סבירה לביטוח/רישיון
/// שמתחדשים אחת לשנה).
class _RenewalJourneyRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? expiryDate;
  final Color color;

  const _RenewalJourneyRow({
    required this.label,
    required this.icon,
    required this.expiryDate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final days = daysUntil(expiryDate);
    final isExpired = days != null && days < 0;
    final urgencyColor = colorForDaysRemaining(days);
    double progress = 0;
    if (days != null) {
      progress = (1 - (days / 365)).clamp(0.0, 1.0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          SizedBox(
            width: 46,
            child: Text(
              label,
              style: AppTextStyles.bodySecondary.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 32,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = (constraints.maxWidth - 24).clamp(0.0, double.infinity);
                  final carLeft = trackWidth * progress;
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Positioned(
                        left: carLeft,
                        child: Icon(Icons.directions_car, color: color, size: 24),
                      ),
                      const Positioned(
                        right: 0,
                        child: Icon(Icons.flag, color: Color(0xFFE53935), size: 20),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 40,
            child: Text(
              isExpired
                  ? AppStrings.expiredLabel
                  : days == null
                      ? AppStrings.notSetLabel
                      : '$days ${AppStrings.daysLabel}',
              style: TextStyle(
                color: isExpired ? AppColors.error : urgencyColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

  Future<void> _deletePhoto(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteDocumentConfirmTitle),
        content: const Text(AppStrings.deleteDocumentConfirmMessage),
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
      await ref.read(vehiclesRepositoryProvider).updateVehiclePhoto(
            householdId: householdId,
            vehicleId: vehicle.id,
            photoDataUrl: null,
          );
    }
  }

  void _showPhotoMenu(BuildContext context, WidgetRef ref, bool hasPhoto) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text(AppStrings.choosePhotoOption),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _changePhoto(ref);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
                title: const Text(AppStrings.deleteDocumentTooltip),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _deletePhoto(context, ref);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoBytes = decodeVehiclePhotoDataUrl(vehicle.photoDataUrl);

    return GestureDetector(
      onTap: () => _showPhotoMenu(context, ref, photoBytes != null),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 88,
            height: 88,
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
                ? const Icon(Icons.directions_car_filled, color: Colors.white, size: 44)
                : null,
          ),
          Positioned(
            bottom: -2,
            left: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
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
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: displayColor.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            days == null
                ? AppStrings.notSetLabel
                : days < 0
                    ? AppStrings.expiredLabel
                    : '$days ${AppStrings.daysLabel}',
            style: TextStyle(color: displayColor, fontWeight: FontWeight.bold, fontSize: 14),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onUpdate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "שעון" דשבורד עיטורי - טבעת התקדמות קבועה ואייקון מד-מהירות
              // במרכזה, כדי שהקילומטראז' יראה כמו תצוגה ברכב.
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: 0.72,
                        strokeWidth: 4,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const Icon(Icons.speed_outlined, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.currentMileageLabel,
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        textDirection: TextDirection.ltr,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            AppStrings.kmUnit,
                            style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${vehicle.currentMileage}',
                            style: AppTextStyles.heading2.copyWith(fontSize: 18),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

