import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import '../../providers/vehicles_provider.dart';
import 'add_service_record_screen.dart';
import 'vehicle_export.dart';
import 'vehicle_photo_picker.dart';

/// מסך מלא (לא חלונית) עם כל היסטוריית הטיפולים של הרכב - נפתח
/// מכפתור "היסטוריית טיפולים" בעמוד הטיפולים במסך פרטי הרכב, כדי
/// שכל התיעוד לא יתפוס מקום קבוע במסך הרכב עצמו (שם אין גלילה).
/// מקובץ לפי סוג טיפול, עם אפשרות מחיקה (Dismissible) בדיוק כמו
/// שהיה קודם, ואפשרות הוספת טיפול חדש מכפתור בסרגל העליון, ואייקון
/// ייצוא (אקסל/וורד) בצד השני של הסרגל העליון.
class ServiceHistoryScreen extends StatelessWidget {
  final String householdId;
  final String vehicleId;
  final int currentMileage;
  final Vehicle vehicle;

  const ServiceHistoryScreen({
    super.key,
    required this.householdId,
    required this.vehicleId,
    required this.currentMileage,
    required this.vehicle,
  });

  Future<void> _exportFile(
    BuildContext context,
    List<VehicleServiceRecord> records, {
    required bool asExcel,
  }) async {
    // ייצוא לוורד כולל רינדור של קבלות PDF לתמונה (ראה vehicle_export.dart)
    // שיכול לקחת כמה שניות אם יש כמה קבלות - לכן מציגים חלונית טעינה
    // כדי שיהיה ברור שהאפליקציה עובדת ולא "תקועה".
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                const Text(AppStrings.preparingExportMessage),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final dataUrl = asExcel
          ? buildServiceHistoryExcelDataUrl(vehicle, records)
          : await buildServiceHistoryWordDataUrl(vehicle, records);
      final extension = asExcel ? 'xlsx' : 'doc';
      final fileName = 'היסטוריית_טיפולים_${vehicle.licensePlate}.$extension';

      final shared = await shareDataUrlFile(
        dataUrl: dataUrl,
        fileName: fileName,
        title: AppStrings.serviceHistoryScreenTitle,
      );
      if (!shared) {
        downloadDataUrlFile(dataUrl: dataUrl, fileName: fileName);
      }
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showExportSheet(BuildContext context, List<VehicleServiceRecord> records) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.grid_on_outlined, color: AppColors.itemPurchased),
              title: const Text(AppStrings.exportAsExcelAction),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _exportFile(context, records, asExcel: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: AppColors.primary),
              title: const Text(AppStrings.exportAsWordAction),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _exportFile(context, records, asExcel: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final recordsAsync = ref.watch(
          vehicleServiceRecordsProvider((householdId: householdId, vehicleId: vehicleId)),
        );
        final records = recordsAsync.asData?.value ?? const <VehicleServiceRecord>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.serviceHistoryScreenTitle),
            actions: [
              _ExportAction(
                enabled: records.isNotEmpty,
                onTap: () => _showExportSheet(context, records),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _ServiceHistoryList(
                householdId: householdId,
                vehicleId: vehicleId,
                currentMileage: currentMileage,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// כפתור הייצוא בסרגל העליון - אייקון עם המילה "ייצוא" ממש מתחתיו
/// (לא רק Tooltip), כדי שהפעולה תהיה ברורה בלי צורך ללחוץ ארוכות.
class _ExportAction extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ExportAction({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface)
        : Theme.of(context).disabledColor;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ios_share_outlined, color: color, size: 22),
            const SizedBox(height: 1),
            Text(
              AppStrings.exportTooltip,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
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
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.build_outlined, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.noServiceRecordsMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
          );
        }

        // ללא כותרות קבוצה (שם הטיפול מופיע ממילא בכל שורה בנפרד, אז
        // כותרת מעל הייתה כפילות מיותרת) וללא מרווח נוסף בין סוגי
        // טיפולים שונים - כל הרשומות מוצגות ברשימה אחת רציפה, שורה
        // אחת מעל השנייה (מסודרות לפי סוג טיפול, כמו קודם).
        final grouped = <String, List<VehicleServiceRecord>>{};
        for (final record in records) {
          grouped.putIfAbsent(record.serviceType, () => []).add(record);
        }

        final knownKeys = kMaintenanceTemplateNames.keys.where(grouped.containsKey).toList();
        final otherKeys = grouped.keys.where((k) => !kMaintenanceTemplateNames.containsKey(k)).toList()
          ..sort();
        final orderedKeys = [...knownKeys, ...otherKeys];

        final allRecords = <VehicleServiceRecord>[
          for (final key in orderedKeys) ...grouped[key]!,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: allRecords
              .map((record) => _ServiceRecordTile(
                    record: record,
                    householdId: householdId,
                    vehicleId: vehicleId,
                    currentMileage: currentMileage,
                  ))
              .toList(),
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

  Future<void> _uploadReceiptPhoto(WidgetRef ref, {required bool useCamera}) async {
    final dataUrl = await pickAndCompressPhoto(useCamera: useCamera);
    if (dataUrl == null) return;
    await ref.read(vehiclesRepositoryProvider).updateServiceRecordReceipt(
          householdId: householdId,
          vehicleId: vehicleId,
          recordId: record.id,
          receiptDataUrl: dataUrl,
        );
  }

  Future<void> _uploadReceiptPdf(WidgetRef ref) async {
    final dataUrl = await pickPdfDataUrl();
    if (dataUrl == null) return;
    await ref.read(vehiclesRepositoryProvider).updateServiceRecordReceipt(
          householdId: householdId,
          vehicleId: vehicleId,
          recordId: record.id,
          receiptDataUrl: dataUrl,
        );
  }

  void _showUploadReceiptSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text(AppStrings.takePhotoOption),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _uploadReceiptPhoto(ref, useCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text(AppStrings.choosePhotoOption),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _uploadReceiptPhoto(ref, useCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text(AppStrings.choosePdfOption),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _uploadReceiptPdf(ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReceipt(WidgetRef ref) {
    return ref.read(vehiclesRepositoryProvider).updateServiceRecordReceipt(
          householdId: householdId,
          vehicleId: vehicleId,
          recordId: record.id,
          receiptDataUrl: null,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = kMaintenanceTemplateNames[record.serviceType] ?? record.serviceType;
    final hasReceipt = record.receiptDataUrl != null;

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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (record.cost != null) ...[
                Text('₪${record.cost}'),
                const SizedBox(width: 4),
              ],
              if (hasReceipt)
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  tooltip: AppStrings.viewDocumentTooltip,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => openDataUrlInNewTab(record.receiptDataUrl!),
                ),
              IconButton(
                icon: Icon(hasReceipt ? Icons.sync : Icons.receipt_long_outlined, size: 20),
                tooltip: AppStrings.uploadDocumentTooltip,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => _showUploadReceiptSheet(context, ref),
              ),
              if (hasReceipt)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  tooltip: AppStrings.deleteDocumentTooltip,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => _deleteReceipt(ref),
                ),
            ],
          ),
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

