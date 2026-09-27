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

/// אייקון קבוע לכל סוג טיפול - משותף בין בורר סוגי הטיפול בעמוד
/// הטיפולים לבין חלוניות הפרטים שנפתחות ממקומות שונים במסך.
const Map<String, IconData> _kMaintenanceIcons = {
  'oilChange': Icons.opacity,
  'majorService': Icons.build_circle_outlined,
  'battery': Icons.battery_charging_full,
  'brakes': Icons.album_outlined,
};

/// סטטוס טיפול מחושב עבור סוג טיפול בודד (כמה ק"מ נשארו/כמה איחור) -
/// מחושב פעם אחת ומשותף בין עמוד 1 ("הטיפול הבא"), עמוד 2 (הרשימה
/// הקצרה של הטיפולים הקרובים) וחלונית הפרטים, כדי לא לכפול לוגיקה.
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

/// חלונית פרטי טיפול משותפת - נפתחת מעמוד 1 ("הטיפול הבא"), מהרשימה
/// הקצרה בעמוד 2 ומבורר סוגי הטיפול. מציגה כמה נשאר/כמה איחור
/// ותיאור קצר של הטיפול.
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

/// מסך פרטי רכב בודד - כל התוכן מרוכז בכרטיס אחד עם 3 עמודים
/// שמחליקים ביניהם (ראה _DatesHeaderCard): מסך ראשי, טיפולים,
/// וביטוחים. אין גלילה כלל במסך הזה - הכרטיס תופס את כל הגובה
/// שנשאר מתחת לסרגל העליון.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync =
        ref.watch(vehicleDetailProvider((householdId: householdId, vehicleId: vehicleId)));
    final backgroundId = ref.watch(vehiclesBackgroundIdProvider(householdId)).value ?? 'none';
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
                padding: const EdgeInsets.all(12),
                child: _DatesHeaderCard(
                  householdId: householdId,
                  vehicle: vehicle,
                  onUpdateMileage: () => _updateMileage(context, ref, vehicle),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// כרטיס בולט שתופס את כל הגובה הפנוי מתחת לסרגל העליון - 3
/// "עמודים" ניתנים להחלקה (PageView) עם נקודות סימון (dots) למטה:
/// עמוד 1 - מסך ראשי (תמונה/שם/מספר רישוי, קילומטראז', צ'יפים
/// לרישיון/ביטוחים, והטיפול הבא). עמוד 2 - "טיפולים" (בחירת סוג
/// טיפול/עריכת מרווחים, טיפולים קרובים, קישור להיסטוריה). עמוד 3 -
/// "ביטוחים" (מסמכים + עלויות + מסע לחידוש). שלושת העמודים על אותו
/// רקע גרדיאנט כהה.
class _DatesHeaderCard extends ConsumerStatefulWidget {
  final String householdId;
  final Vehicle vehicle;
  final VoidCallback onUpdateMileage;
  const _DatesHeaderCard({
    required this.householdId,
    required this.vehicle,
    required this.onUpdateMileage,
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

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _MainInfoPage(
                  householdId: widget.householdId,
                  vehicle: vehicle,
                  onUpdateMileage: widget.onUpdateMileage,
                  onNavigateToInsurance: () => _goToPage(2),
                ),
                _MaintenancePage(householdId: widget.householdId, vehicle: vehicle),
                _InsurancePage(
                  householdId: widget.householdId,
                  vehicle: vehicle,
                  onUploadTap: _showUploadSourceSheet,
                  onView: _viewDocument,
                  onDelete: _confirmDeleteDocument,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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

/// עמוד 1 בהחלקה - מסך ראשי: תמונה/שם/מספר רישוי + קילומטראז' (עם
/// עריכה), 3 צ'יפים קומפקטיים לרישיון/ביטוח חובה/ביטוח מקיף (לחיצה
/// עליהם קופצת ישר לעמוד הביטוחים), ובתחתית - תצוגת "הטיפול הבא"
/// (הפריט הכי דחוף מתוך כל סוגי הטיפול העוקבים).
class _MainInfoPage extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;
  final VoidCallback onUpdateMileage;
  final VoidCallback onNavigateToInsurance;

  const _MainInfoPage({
    required this.householdId,
    required this.vehicle,
    required this.onUpdateMileage,
    required this.onNavigateToInsurance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(
      vehicleServiceRecordsProvider((householdId: householdId, vehicleId: vehicle.id)),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: const Offset(0, -6),
              child: _VehicleIconLarge(householdId: householdId, vehicle: vehicle),
            ),
            const SizedBox(width: 14),
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
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onUpdateMileage,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${vehicle.currentMileage}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          textDirection: TextDirection.ltr,
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.edit_outlined, color: Colors.white54, size: 12),
                      ],
                    ),
                    const Text(
                      AppStrings.kmUnit,
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _CompactStatusChip(
                label: AppStrings.licenseExpiryLabel,
                date: vehicle.licenseExpiryDate,
                onTap: onNavigateToInsurance,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _CompactStatusChip(
                label: AppStrings.mandatoryInsuranceLabel,
                date: vehicle.mandatoryInsuranceExpiryDate,
                onTap: onNavigateToInsurance,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _CompactStatusChip(
                label: AppStrings.comprehensiveInsuranceLabel,
                date: vehicle.comprehensiveInsuranceExpiryDate,
                onTap: onNavigateToInsurance,
              ),
            ),
          ],
        ),
        recordsAsync.when(
          data: (records) {
            final statuses = computeMaintenanceStatuses(vehicle, records)
              ..sort((a, b) => a.remaining.compareTo(b.remaining));
            if (statuses.isEmpty) return const SizedBox.shrink();
            final next = statuses.first;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showMaintenanceDetailSheet(context, next),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(next.icon, color: next.color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${AppStrings.nextServiceLabel}: ${next.name}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      next.remaining < 0
                          ? '${AppStrings.overdueByLabel} ${-next.remaining}'
                          : '${AppStrings.nextServiceInLabel} ${next.remaining}',
                      style: TextStyle(color: next.color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// צ'יפ קומפקטי לתצוגת סטטוס תאריך (רישיון/ביטוח) - כמו _DateChip
/// הישן, אבל קטן משמעותית (רק מספר הימים, בלי המילה "ימים") כדי
/// שיהיה מקום גם לקילומטראז' וגם ל"טיפול הבא" באותו עמוד. לחיצה
/// עליו קופצת לעמוד הביטוחים לפרטים המלאים.
class _CompactStatusChip extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _CompactStatusChip({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final days = daysUntil(date);
    final color = colorForDaysRemaining(days);
    final displayColor = days != null && days > 30 ? const Color(0xFF7CE0C6) : color;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: displayColor.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              days == null
                  ? AppStrings.notSetLabel
                  : days < 0
                      ? AppStrings.expiredLabel
                      : '$days',
              style: TextStyle(color: displayColor, fontWeight: FontWeight.bold, fontSize: 13),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}

/// עמוד 2 בהחלקה - "טיפולים": למעלה בורר אופקי של סוגי הטיפול (עם
/// המרווח הנוכחי של כל אחד, לחיצה פותחת עריכת מרווח) + כפתור עגול
/// להוספת תיעוד טיפול חדש. למטה - הטיפולים הקרובים ביותר וכפתור
/// לפתיחת היסטוריית הטיפולים המלאה (מסך נפרד, עם אפשרות מחיקה).
class _MaintenancePage extends StatelessWidget {
  final String householdId;
  final Vehicle vehicle;

  const _MaintenancePage({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.maintenancePageTitle,
          style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 6),
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
        const SizedBox(height: 10),
        Expanded(
          child: _MaintenancePageBottom(householdId: householdId, vehicle: vehicle),
        ),
      ],
    );
  }
}

/// בורר סוגי הטיפול - רשימה אופקית של "כרטיסיות" (אחת לכל סוג),
/// לחיצה על כרטיסייה פותחת עריכת המרווח שלה. זו הדרך היחידה לערוך
/// מרווחים כעת - קלטה את מקום חלונית ה-☰ הישנה. כפתור "+" בסוף
/// הרשימה פותח את מסך הוספת תיעוד הטיפול.
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
      height: 64,
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
                  width: 82,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 17),
                      const SizedBox(height: 3),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$interval ${AppStrings.kmUnit}',
                        style: const TextStyle(color: Colors.white60, fontSize: 9),
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
                  color: AppColors.primary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white38),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// חלק תחתון של עמוד הטיפולים - הטיפולים הקרובים ביותר (עד 2), וכפתור
/// לפתיחת היסטוריית הטיפולים המלאה במסך נפרד (שם אפשר גם למחוק).
class _MaintenancePageBottom extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _MaintenancePageBottom({required this.householdId, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(
      vehicleServiceRecordsProvider((householdId: householdId, vehicleId: vehicle.id)),
    );

    return recordsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (records) {
        final statuses = computeMaintenanceStatuses(vehicle, records)
          ..sort((a, b) => a.remaining.compareTo(b.remaining));
        final upcoming = statuses.take(2).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.upcomingMaintenanceTitle,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (upcoming.isEmpty)
                  Text(
                    AppStrings.noUpcomingMaintenance,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  )
                else
                  ...upcoming.map((s) => InkWell(
                        onTap: () => showMaintenanceDetailSheet(context, s),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Icon(s.icon, color: s.color, size: 15),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                s.remaining < 0
                                    ? '${AppStrings.overdueByLabel} ${-s.remaining}'
                                    : '${AppStrings.nextServiceInLabel} ${s.remaining}',
                                style: TextStyle(
                                    color: s.color, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
                icon: const Icon(Icons.history, size: 16),
                label: const Text(AppStrings.serviceHistoryButton, style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// עמוד 3 בהחלקה - "ביטוחים": שורה לכל אחד מ-3 המסמכים (רישיון,
/// ביטוח חובה, ביטוח מקיף) עם התאריך והעלאת/צפייה/מחיקה/שיתוף של
/// הקובץ הסרוק. בתחתית - עלות שנתית לחובה/מקיף (עריכה בהקשה), ו"מסע
/// לחידוש" ויזואלי לכל אחד מ-3 המסמכים.
class _InsurancePage extends StatelessWidget {
  final String householdId;
  final Vehicle vehicle;
  final void Function(BuildContext context, String fieldKey) onUploadTap;
  final void Function(BuildContext context, String? dataUrl) onView;
  final void Function(BuildContext context, String fieldKey) onDelete;

  const _InsurancePage({
    required this.householdId,
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
      children: [
        Text(
          AppStrings.insuranceDocumentsTitle,
          style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 4),
        ...rows.map((row) {
          final days = daysUntil(row.date);
          final color = colorForDaysRemaining(days);
          final displayColor = days != null && days > 30 ? const Color(0xFF7CE0C6) : color;
          final hasDocument = row.documentDataUrl != null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.label,
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(
                        row.date == null ? AppStrings.notSetLabel : formatPrettyDateHe(row.date!),
                        style: TextStyle(
                            color: displayColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (hasDocument)
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, color: Colors.white, size: 18),
                    tooltip: AppStrings.viewDocumentTooltip,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onView(context, row.documentDataUrl),
                  ),
                IconButton(
                  icon: Icon(
                    hasDocument ? Icons.sync : Icons.upload_file_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  tooltip: AppStrings.uploadDocumentTooltip,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onUploadTap(context, row.fieldKey),
                ),
                if (hasDocument)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B), size: 18),
                    tooltip: AppStrings.deleteDocumentTooltip,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onDelete(context, row.fieldKey),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        _InsuranceCostRow(householdId: householdId, vehicle: vehicle),
        const SizedBox(height: 8),
        Text(
          AppStrings.renewalJourneyTitle,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        _RenewalJourneyRow(
          label: AppStrings.licenseExpiryLabel,
          expiryDate: vehicle.licenseExpiryDate,
          color: const Color(0xFF7FD6FF),
        ),
        _RenewalJourneyRow(
          label: AppStrings.mandatoryInsuranceLabel,
          expiryDate: vehicle.mandatoryInsuranceExpiryDate,
          color: const Color(0xFFFFB768),
        ),
        _RenewalJourneyRow(
          label: AppStrings.comprehensiveInsuranceLabel,
          expiryDate: vehicle.comprehensiveInsuranceExpiryDate,
          color: const Color(0xFF7CE0C6),
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
    final controller = TextEditingController(text: current == null ? '' : current.toStringAsFixed(0));
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
        borderRadius: BorderRadius.circular(10),
        onTap: () => _editCost(context, ref, fieldKey, cost),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
              Text(
                cost == null ? AppStrings.notSetCostLabel : '₪${cost.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
        const SizedBox(width: 8),
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
class _RenewalJourneyRow extends StatelessWidget {
  final String label;
  final DateTime? expiryDate;
  final Color color;

  const _RenewalJourneyRow({required this.label, required this.expiryDate, required this.color});

  @override
  Widget build(BuildContext context) {
    final days = daysUntil(expiryDate);
    final isExpired = days != null && days < 0;
    double progress = 0;
    if (days != null) {
      progress = (1 - (days / 365)).clamp(0.0, 1.0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 20,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = (constraints.maxWidth - 18).clamp(0.0, double.infinity);
                  final carLeft = trackWidth * progress;
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Positioned(
                        left: carLeft,
                        child: Icon(Icons.directions_car, color: color, size: 15),
                      ),
                      const Positioned(
                        right: 0,
                        child: Icon(Icons.flag, color: Colors.white70, size: 13),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            child: Text(
              isExpired
                  ? AppStrings.expiredLabel
                  : days == null
                      ? AppStrings.notSetLabel
                      : '$days ${AppStrings.daysLabel}',
              style: TextStyle(
                color: isExpired ? AppColors.error : Colors.white70,
                fontSize: 9,
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

