import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import '../../providers/vehicles_provider.dart';
import 'dart:typed_data';
import 'add_edit_vehicle_screen.dart';
import 'add_service_record_screen.dart';
import 'vehicle_photo_picker.dart';
import 'vehicles_background_provider.dart';
import 'vehicles_list_screen.dart' show colorForDaysRemaining, daysUntil;

/// אייקון קבוע לכל סוג טיפול - משותף בין כרטיסי הרשת (_MaintenanceSection)
/// לבין חלונית ההגדרות (_showMaintenanceSettingsSheet), כדי שלא יהיה כפול.
const Map<String, IconData> _kMaintenanceIcons = {
  'oilChange': Icons.opacity,
  'majorService': Icons.build_circle_outlined,
  'battery': Icons.battery_charging_full,
  'brakes': Icons.album_outlined,
};

/// מסך פרטי רכב בודד - הכל פר-רכב, בלי ערבוב עם רכבים אחרים:
/// תוקף רישיון/ביטוחים במבט בולט למעלה, קילומטראז' נוכחי, מעקב
/// טיפולים (לפי מרווחי ק"מ) עם המלצה מתי הטיפול הבא, ותיעוד
/// היסטוריית הטיפולים שכבר בוצעו (מקובצת לפי סוג).
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

  Future<void> _editInterval(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
    String templateKey,
    int currentInterval,
  ) async {
    final controller = TextEditingController(text: currentInterval.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${AppStrings.editIntervalTitlePrefix} ${kMaintenanceTemplateNames[templateKey]}',
        ),
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
            templateKey: templateKey,
            intervalKm: result,
          );
    }
  }

  /// חלונית "הגדרות טווחי טיפולים" - נפתחת מהאייקון (☰) ליד כותרת
  /// מקטע הטיפולים. זו הדרך היחידה לערוך מרווחים - אין יותר עריכה
  /// מתוך הכרטיסים ברשת עצמם, כדי שלא יהיו שתי דרכים מקבילות.
  void _showMaintenanceSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer(
                builder: (context, ref, _) {
                  final vehicleAsync = ref.watch(
                    vehicleDetailProvider((householdId: householdId, vehicleId: vehicleId)),
                  );
                  final vehicle = vehicleAsync.value;
                  if (vehicle == null) return const SizedBox.shrink();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.maintenanceSettingsTitle, style: AppTextStyles.heading2),
                      const SizedBox(height: 8),
                      ...kTrackedMaintenanceKeys.map((key) {
                        final name = kMaintenanceTemplateNames[key] ?? key;
                        final interval = vehicle.maintenanceIntervals[key] ??
                            kDefaultMaintenanceIntervals[key] ??
                            10000;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(_kMaintenanceIcons[key] ?? Icons.build_outlined,
                              color: AppColors.primary),
                          title: Text(name),
                          subtitle: Text(
                            '$interval ${AppStrings.kmUnit}',
                            textDirection: TextDirection.ltr,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.tune, size: 20),
                            tooltip: AppStrings.editIntervalTooltip,
                            onPressed: () => _editInterval(context, ref, vehicle, key, interval),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync =
        ref.watch(vehicleDetailProvider((householdId: householdId, vehicleId: vehicleId)));
    final backgroundId = ref.watch(vehiclesBackgroundIdProvider(householdId)).value ?? 'none';
    final background = backgroundOptionById(backgroundId);
    final hasBackground = background.id != 'none';

    return Scaffold(
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

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                title: const Text(AppStrings.vehicleDetailsTitle),
                flexibleSpace: const FlexibleSpaceBar(
                  background: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                    ),
                  ),
                ),
                actions: [
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DatesHeaderCard(householdId: householdId, vehicle: vehicle),
                      const SizedBox(height: 8),
                      Center(
                        child: _MileageCard(
                          vehicle: vehicle,
                          onUpdate: () => _updateMileage(context, ref, vehicle),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Material(
                            color: Colors.black.withOpacity(0.32),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _showMaintenanceSettingsSheet(context, ref),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.menu, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(AppStrings.maintenanceSectionTitle, style: AppTextStyles.heading2),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _MaintenanceSection(
                        householdId: householdId,
                        vehicle: vehicle,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppStrings.serviceHistoryTitle, style: AppTextStyles.heading2),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddServiceRecordScreen(
                                  householdId: householdId,
                                  vehicleId: vehicle.id,
                                  currentMileage: vehicle.currentMileage,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(AppStrings.addServiceRecordButton),
                          ),
                        ],
                      ),
                      _ServiceHistoryList(
                        householdId: householdId,
                        vehicleId: vehicle.id,
                        currentMileage: vehicle.currentMileage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}

/// כרטיס בולט למעלה - שני "עמודים" ניתנים להחלקה (PageView) עם
/// נקודות סימון (dots) למטה: עמוד 1 - המסך הראשי הרגיל (תמונה/שם/
/// מספר רישוי + 3 צ'יפים עם ימים שנשארו). עמוד 2 - "ביטוחים": אותם
/// 3 תאריכים בפירוט, עם אפשרות להעלות/לצפות בקובץ סרוק/מצולם של
/// המסמך הפיזי לכל אחד מהם. שני העמודים על אותו רקע גרדיאנט כהה.
class _DatesHeaderCard extends ConsumerStatefulWidget {
  final String householdId;
  final Vehicle vehicle;
  const _DatesHeaderCard({required this.householdId, required this.vehicle});

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
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _MainInfoPage(householdId: widget.householdId, vehicle: vehicle),
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
            children: List.generate(2, (i) {
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

/// עמוד 1 בהחלקה - התוכן שהיה קודם ב-_DatesHeaderCard: תמונה/שם/
/// מספר רישוי, ומתחת 3 צ'יפים עם כמות הימים שנותרו לכל תאריך.
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

/// עמוד 2 בהחלקה - "ביטוחים": שורה לכל אחד מ-3 התאריכים (רישיון,
/// ביטוח חובה, ביטוח מקיף) עם התאריך עצמו, וכפתור להעלאת/צפייה
/// בקובץ סרוק/מצולם של המסמך הפיזי. התאריכים האלה כבר מופיעים
/// אוטומטית גם בלוח השנה הראשי של האפליקציה (אין צורך בתזכורת
/// נפרדת - ראה vehicle_calendar_provider.dart).
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

/// מקטע הטיפולים - שורת אייקונים קטנים וקומפקטיים (אחד לכל סוג
/// טיפול), צבועים לפי דחיפות. לחיצה על אייקון פותחת חלונית (bottom
/// sheet) עם כל הפרטים: כמה נשאר, הסבר על הטיפול, וכפתור לעריכת
/// המרווח - כדי לא לתפוס מקום קבוע במסך.
class _MaintenanceSection extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;

  const _MaintenanceSection({
    required this.householdId,
    required this.vehicle,
  });

  void _openDetail(
    BuildContext context,
    String key,
    String name,
    IconData icon,
    Color color,
    int remaining,
    int interval,
  ) {
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
                    decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name, style: AppTextStyles.heading2)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                remaining < 0
                    ? '${AppStrings.overdueByLabel} ${-remaining} ${AppStrings.kmUnit}'
                    : '${AppStrings.nextServiceInLabel} $remaining ${AppStrings.kmUnit}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                kMaintenanceTemplateDescriptions[key] ?? '',
                style: AppTextStyles.bodySecondary,
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
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(),
      data: (records) {
        final tiles = kTrackedMaintenanceKeys.map((key) {
          final name = kMaintenanceTemplateNames[key] ?? key;
          final interval = vehicle.maintenanceIntervals[key] ??
              kDefaultMaintenanceIntervals[key] ??
              10000;

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
          final isUrgent = remaining < 0;

          return Material(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDetail(context, key, name, icon, color, remaining, interval),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.35)),
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
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 16),
                        ),
                        const Spacer(),
                        if (isUrgent)
                          const Icon(Icons.error, color: AppColors.error, size: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySecondary
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      remaining < 0
                          ? '${AppStrings.overdueByLabel} ${-remaining} ${AppStrings.kmUnit}'
                          : '${AppStrings.nextServiceInLabel} $remaining ${AppStrings.kmUnit}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
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

/// היסטוריית הטיפולים - מקובצת לפי סוג טיפול (כל "טיפול קטן" ביחד,
/// כל "החלפת צמיגים" ביחד וכו'), עם כותרת קבוצה שמראה כמה רשומות
/// יש מכל סוג. קבוצות "אחר"/מותאמות אישית מופיעות אחרונות.
class _ServiceHistoryList extends ConsumerWidget {
  final String householdId;
  final String vehicleId;
  final int currentMileage;

  const _ServiceHistoryList({
    required this.householdId,
    required this.vehicleId,
    required this.currentMileage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync =
        ref.watch(vehicleServiceRecordsProvider((householdId: householdId, vehicleId: vehicleId)));

    return recordsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(),
      data: (records) {
        if (records.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(AppStrings.noServiceRecordsYet, style: AppTextStyles.bodySecondary),
          );
        }

        // קיבוץ לפי סוג - סדר קבוע לפי kMaintenanceTemplateNames קודם,
        // ואז כל סוג "אחר" מותאם אישית לפי סדר א"ב.
        final grouped = <String, List<VehicleServiceRecord>>{};
        for (final record in records) {
          grouped.putIfAbsent(record.serviceType, () => []).add(record);
        }

        final knownKeys = kMaintenanceTemplateNames.keys.where(grouped.containsKey).toList();
        final otherKeys = grouped.keys.where((k) => !kMaintenanceTemplateNames.containsKey(k)).toList()
          ..sort();
        final orderedKeys = [...knownKeys, ...otherKeys];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: orderedKeys.map((key) {
            final groupRecords = grouped[key]!;
            final groupName = kMaintenanceTemplateNames[key] ?? key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          groupName,
                          style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${groupRecords.length}',
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...groupRecords.map((record) => _ServiceRecordTile(
                        record: record,
                        householdId: householdId,
                        vehicleId: vehicleId,
                        currentMileage: currentMileage,
                      )),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ServiceRecordTile extends ConsumerWidget {
  final VehicleServiceRecord record;
  final String householdId;
  final String vehicleId;
  final int currentMileage;

  const _ServiceRecordTile({
    required this.record,
    required this.householdId,
    required this.vehicleId,
    required this.currentMileage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = kMaintenanceTemplateNames[record.serviceType] ?? record.serviceType;

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Text(AppStrings.deleteAction, style: TextStyle(color: Colors.white)),
      ),
      confirmDismiss: (_) async {
        await ref.read(vehiclesRepositoryProvider).deleteServiceRecord(
              householdId: householdId,
              vehicleId: vehicleId,
              recordId: record.id,
            );
        return false;
      },
      child: Card(
        color: Colors.white.withOpacity(0.8),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.build_outlined, color: AppColors.primary),
          title: Text(displayName),
          subtitle: Text(
            '${DateFormatter.short(record.performedAt)} · ${record.mileageAtService} ${AppStrings.kmUnit}'
            '${record.notes != null ? ' · ${record.notes}' : ''}',
          ),
          trailing: record.cost != null ? Text('₪${record.cost}') : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddServiceRecordScreen(
                householdId: householdId,
                vehicleId: vehicleId,
                currentMileage: currentMileage,
                existing: record,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
