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
  'battery': Icons.battery_charging_full,
  'brakes': Icons.album_outlined,
};

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
    // אם אין עדיין תיעוד טיפול אמיתי מהסוג הזה - מתחילים למנות
    // מהקילומטראז' שהיה לרכב כשהוא נוסף לאפליקציה (initialMileage),
    // לא מ-0, כדי שרכב שנוסף עם קילומטראז' גבוה לא ייראה מיד
    // "באיחור ענק".
    final lastMileage = matching.isEmpty
        ? vehicle.initialMileage
        : matching.map((r) => r.mileageAtService).reduce((a, b) => a > b ? a : b);
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(AppStrings.vehicleDetailsTitle),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
        ),
        actions: vehicleAsync.maybeWhen(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: const Offset(0, -6),
              child: _VehicleIconLarge(householdId: householdId, vehicle: vehicle),
            ),
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
    );
  }
}

/// עמוד 2 בהחלקה - תקציר "טיפולים" קטן בתוך הכרטיס העליון: אייקון,
/// כותרת, ועיגול צבעוני לכל סוג טיפול (לפי דחיפות). כל הפרטים
/// המלאים (עריכת מרווחים, טיפולים קרובים, היסטוריה) מוצגים באזור
/// שמתחת לכרטיס.
class _MaintenanceTopPreview extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;
  const _MaintenanceTopPreview({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(
      vehicleServiceRecordsProvider((householdId: householdId, vehicleId: vehicle.id)),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.build_circle_outlined, color: Colors.white, size: 42),
        const SizedBox(height: 10),
        Text(
          AppStrings.maintenancePageTitle,
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 18),
        recordsAsync.when(
          data: (records) {
            final statuses = computeMaintenanceStatuses(vehicle, records);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: statuses.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: s.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: s.color.withOpacity(0.6)),
                    ),
                    child: Icon(s.icon, color: s.color, size: 18),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(height: 36),
          error: (e, st) => const SizedBox(height: 36),
        ),
      ],
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
          style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 15),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(child: _MileageCard(vehicle: vehicle, onUpdate: onUpdateMileage)),
        const SizedBox(height: 24),
        _NextServiceCard(householdId: householdId, vehicle: vehicle),
      ],
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
                  Text(
                    next.remaining < 0
                        ? '${AppStrings.overdueByLabel} ${-next.remaining} ${AppStrings.kmUnit}'
                        : '${AppStrings.nextServiceInLabel} ${next.remaining} ${AppStrings.kmUnit}',
                    style: TextStyle(color: next.color, fontWeight: FontWeight.bold, fontSize: 13),
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

/// אזור תחתון לעמוד 2 - בורר סוגי הטיפול (עריכת מרווחים + הוספת
/// תיעוד), מתחתיו רשת הטיפולים (בדיוק כמו שהיה במקור), ובתחתית כפתור
/// לפתיחת היסטוריית הטיפולים המלאה במסך נפרד.
class _MaintenanceBottom extends StatelessWidget {
  final String householdId;
  final Vehicle vehicle;

  const _MaintenanceBottom({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MaintenanceTypeSelector(
          householdId: householdId,
          vehicle: vehicle,
          onAddTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddServiceRecordScreen(
                householdId: householdId,
                vehicleId: vehicle.id,
                currentMileage: vehicle.currentMileage,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Center(
            child: _MaintenanceSection(householdId: householdId, vehicle: vehicle),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
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
      ],
    );
  }
}

/// בורר סוגי הטיפול - רשימה אופקית של "כרטיסיות" (אחת לכל סוג),
/// לחיצה על כרטיסייה פותחת עריכת המרווח שלה - קלטה את מקום חלונית
/// ה-☰ הישנה. כפתור "+" בסוף הרשימה פותח את מסך הוספת תיעוד הטיפול.
class _MaintenanceTypeSelector extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;
  final VoidCallback onAddTap;

  const _MaintenanceTypeSelector({
    required this.householdId,
    required this.vehicle,
    required this.onAddTap,
  });

  Future<void> _editIntervalDialog(
    BuildContext context,
    WidgetRef ref,
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
            templateKey: key,
            intervalKm: result,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 66,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...kTrackedMaintenanceKeys.map((key) {
            final name = kMaintenanceTemplateNames[key] ?? key;
            final interval =
                vehicle.maintenanceIntervals[key] ?? kDefaultMaintenanceIntervals[key] ?? 10000;
            final icon = _kMaintenanceIcons[key] ?? Icons.build_outlined;

            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _editIntervalDialog(context, ref, key, name, interval),
                child: Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AppColors.primary, size: 18),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySecondary
                            .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$interval ${AppStrings.kmUnit}',
                        style: AppTextStyles.bodySecondary.copyWith(fontSize: 9),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onAddTap,
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: AppColors.primary, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// רשת הטיפולים - שורת אייקונים קטנים וקומפקטיים (אחד לכל סוג
/// טיפול), צבועים לפי דחיפות. לחיצה על אייקון פותחת חלונית עם כל
/// הפרטים (בדיוק כמו שהיה במקור, לפני היום).
class _MaintenanceSection extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _MaintenanceSection({
    required this.householdId,
    required this.vehicle,
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
        final statuses = computeMaintenanceStatuses(vehicle, records);

        final tiles = statuses.map((s) {
          final isUrgent = s.remaining < 0;

          return Material(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showMaintenanceDetailSheet(context, s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: s.color.withOpacity(0.35)),
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
                            color: s.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, color: s.color, size: 16),
                        ),
                        const Spacer(),
                        if (isUrgent)
                          const Icon(Icons.error, color: AppColors.error, size: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySecondary
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.remaining < 0
                          ? '${AppStrings.overdueByLabel} ${-s.remaining} ${AppStrings.kmUnit}'
                          : '${AppStrings.nextServiceInLabel} ${s.remaining} ${AppStrings.kmUnit}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: s.color, fontWeight: FontWeight.bold, fontSize: 12),
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

/// אזור תחתון לעמוד 3 - עלות ביטוח שנתית (חובה/מקיף, עריכה בהקשה)
/// ו"מסע לחידוש" ויזואלי לכל אחד מ-3 המסמכים (רישיון/חובה/מקיף).
class _InsuranceBottom extends StatelessWidget {
  final String householdId;
  final Vehicle vehicle;

  const _InsuranceBottom({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.insuranceAnnualCostTitle,
          style: AppTextStyles.heading2.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        _InsuranceCostRow(householdId: householdId, vehicle: vehicle),
        const SizedBox(height: 22),
        Text(
          AppStrings.renewalJourneyTitle,
          style: AppTextStyles.heading2.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        _RenewalJourneyCard(
          label: AppStrings.licenseExpiryLabel,
          icon: Icons.badge_outlined,
          expiryDate: vehicle.licenseExpiryDate,
          color: const Color(0xFF4F9DDE),
        ),
        _RenewalJourneyCard(
          label: AppStrings.mandatoryInsuranceLabel,
          icon: Icons.shield_outlined,
          expiryDate: vehicle.mandatoryInsuranceExpiryDate,
          color: const Color(0xFFE0982E),
        ),
        _RenewalJourneyCard(
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
        borderRadius: BorderRadius.circular(14),
        onTap: () => _editCost(context, ref, fieldKey, cost),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTextStyles.bodySecondary.copyWith(fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                cost == null ? AppStrings.notSetCostLabel : '₪${cost.toStringAsFixed(0)}',
                style: AppTextStyles.heading2.copyWith(fontSize: 15),
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

/// "מסע לחידוש" - רכב קטן שנוסע לאורך כביש לכיוון דגל (יעד = תאריך
/// התפוגה), לפי אחוז הזמן שחלף. מכיוון שאין לנו תאריך תחילת פוליסה
/// שמור, ההתקדמות מחושבת יחסית לשנה אחורה מהתפוגה (הערכה סבירה
/// לביטוח/רישיון שמתחדשים אחת לשנה).
class _RenewalJourneyCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? expiryDate;
  final Color color;

  const _RenewalJourneyCard({
    required this.label,
    required this.icon,
    required this.expiryDate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final days = daysUntil(expiryDate);
    final isExpired = days != null && days < 0;
    double progress = 0;
    if (days != null) {
      progress = (1 - (days / 365)).clamp(0.0, 1.0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Spacer(),
              Text(
                isExpired
                    ? AppStrings.expiredLabel
                    : days == null
                        ? AppStrings.notSetLabel
                        : '$days ${AppStrings.daysLabel}',
                style: TextStyle(
                  color: isExpired ? AppColors.error : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = (constraints.maxWidth - 22).clamp(0.0, double.infinity);
                final carLeft = trackWidth * progress;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Positioned(
                      left: carLeft,
                      child: Icon(Icons.directions_car, color: color, size: 20),
                    ),
                    const Positioned(
                      right: 0,
                      child: Icon(Icons.flag, color: Colors.black45, size: 18),
                    ),
                  ],
                );
              },
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoBytes = decodeVehiclePhotoDataUrl(vehicle.photoDataUrl);

    return GestureDetector(
      onTap: () => _changePhoto(ref),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 68,
            height: 68,
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
                ? const Icon(Icons.directions_car_filled, color: Colors.white, size: 36)
                : null,
          ),
          Positioned(
            bottom: -2,
            left: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
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

