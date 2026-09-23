#!/bin/bash
set -e
echo "=== מיישם את הרקע הנבחר גם במסכי הרכב האחרים ==="

mkdir -p lib/features/vehicles

echo "כותב lib/features/vehicles/vehicle_detail_screen.dart..."
cat > lib/features/vehicles/vehicle_detail_screen.dart << 'VEHICLES_BG_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import '../../providers/vehicles_provider.dart';
import 'add_edit_vehicle_screen.dart';
import 'add_service_record_screen.dart';
import 'vehicles_background_provider.dart';
import 'vehicles_list_screen.dart' show colorForDaysRemaining, daysUntil;

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

  void _showMaintenanceInfo(BuildContext context, String templateKey) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(kMaintenanceTemplateNames[templateKey] ?? ''),
        content: Text(kMaintenanceTemplateDescriptions[templateKey] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.closeAction),
          ),
        ],
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(background.gradientColors[0]),
                    Color(background.gradientColors[1]),
                  ],
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
                title: Text(vehicle.displayName),
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
                      _DatesHeaderCard(vehicle: vehicle),
                      const SizedBox(height: 16),
                      _MileageCard(
                        vehicle: vehicle,
                        onUpdate: () => _updateMileage(context, ref, vehicle),
                      ),
                      const SizedBox(height: 24),
                      Text(AppStrings.maintenanceSectionTitle, style: AppTextStyles.heading2),
                      const SizedBox(height: 8),
                      _MaintenanceSection(
                        householdId: householdId,
                        vehicle: vehicle,
                        onEditInterval: (key, interval) =>
                            _editInterval(context, ref, vehicle, key, interval),
                        onShowInfo: (key) => _showMaintenanceInfo(context, key),
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

/// כרטיס בולט למעלה עם 3 "צ'יפים" - רישיון, ביטוח חובה, ביטוח מקיף -
/// כל אחד עם מספר הימים שנשארו, בצבע לפי דחיפות, על רקע גרדיאנט
/// כהה שמדגיש אותם ונותן מראה "יוקרתי" יותר.
class _DatesHeaderCard extends StatelessWidget {
  final Vehicle vehicle;
  const _DatesHeaderCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const _VehicleIconLarge(),
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
      ),
    );
  }
}

class _VehicleIconLarge extends StatelessWidget {
  const _VehicleIconLarge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white24, Colors.white10],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white38, width: 1.5),
      ),
      child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 30),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.speed_outlined, color: AppColors.primary),
        ),
        title: Text(AppStrings.currentMileageLabel),
        subtitle: Text(
          '${vehicle.currentMileage} ${AppStrings.kmUnit}',
          style: AppTextStyles.heading2,
          textDirection: TextDirection.ltr,
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: onUpdate,
          child: const Text(AppStrings.updateMileageButton),
        ),
      ),
    );
  }
}

class _MaintenanceSection extends ConsumerWidget {
  final String householdId;
  final Vehicle vehicle;
  final void Function(String templateKey, int currentInterval) onEditInterval;
  final void Function(String templateKey) onShowInfo;

  const _MaintenanceSection({
    required this.householdId,
    required this.vehicle,
    required this.onEditInterval,
    required this.onShowInfo,
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
        return Column(
          children: kTrackedMaintenanceKeys.map((key) {
            final name = kMaintenanceTemplateNames[key] ?? key;
            final interval = vehicle.maintenanceIntervals[key] ??
                kDefaultMaintenanceIntervals[key] ??
                10000;

            final matching = records.where((r) => r.serviceType == key).toList();
            final lastMileage =
                matching.isEmpty ? 0 : matching.map((r) => r.mileageAtService).reduce((a, b) => a > b ? a : b);
            final nextDue = lastMileage + interval;
            final remaining = nextDue - vehicle.currentMileage;

            final color = remaining < 0
                ? AppColors.error
                : remaining <= (interval * 0.1)
                    ? Colors.orange
                    : AppColors.itemPurchased;

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Row(
                  children: [
                    Flexible(child: Text(name)),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onShowInfo(key),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.textSecondary),
                        ),
                        child: const Icon(Icons.info_outline, size: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  remaining < 0
                      ? '${AppStrings.overdueByLabel} ${-remaining} ${AppStrings.kmUnit}'
                      : '${AppStrings.remainingKmLabel} $remaining ${AppStrings.kmUnit}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.tune, size: 20),
                  tooltip: AppStrings.editIntervalTooltip,
                  onPressed: () => onEditInterval(key, interval),
                ),
              ),
            );
          }).toList(),
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
VEHICLES_BG_EOF

echo "כותב lib/features/vehicles/add_edit_vehicle_screen.dart..."
cat > lib/features/vehicles/add_edit_vehicle_screen.dart << 'VEHICLES_BG_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicles_provider.dart';
import 'vehicles_background_provider.dart';

/// מסך הוספה/עריכה של רכב. אם `existing` מועבר - זו עריכה של רכב
/// קיים; אחרת - הוספת רכב חדש. אותו מסך משרת את שני המקרים כדי
/// לא לכפול קוד טופס.
class AddEditVehicleScreen extends ConsumerStatefulWidget {
  final String householdId;
  final Vehicle? existing;

  const AddEditVehicleScreen({
    super.key,
    required this.householdId,
    this.existing,
  });

  @override
  ConsumerState<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _mileageController;

  DateTime? _licenseExpiry;
  DateTime? _mandatoryInsuranceExpiry;
  DateTime? _comprehensiveInsuranceExpiry;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _manufacturerController = TextEditingController(text: v?.manufacturer ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(text: v?.year?.toString() ?? '');
    _plateController = TextEditingController(text: v?.licensePlate ?? '');
    _mileageController = TextEditingController(text: v?.currentMileage.toString() ?? '');
    _licenseExpiry = v?.licenseExpiryDate;
    _mandatoryInsuranceExpiry = v?.mandatoryInsuranceExpiryDate;
    _comprehensiveInsuranceExpiry = v?.comprehensiveInsuranceExpiryDate;
  }

  @override
  void dispose() {
    _manufacturerController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(vehiclesRepositoryProvider);
      final year = _yearController.text.trim().isEmpty
          ? null
          : int.tryParse(_yearController.text.trim());
      final mileage = int.tryParse(_mileageController.text.trim()) ?? 0;

      if (_isEditing) {
        await repo.updateVehicle(
          householdId: widget.householdId,
          vehicleId: widget.existing!.id,
          manufacturer: _manufacturerController.text.trim(),
          model: _modelController.text.trim(),
          year: year,
          licensePlate: _plateController.text.trim(),
          licenseExpiryDate: _licenseExpiry,
          mandatoryInsuranceExpiryDate: _mandatoryInsuranceExpiry,
          comprehensiveInsuranceExpiryDate: _comprehensiveInsuranceExpiry,
        );
      } else {
        await repo.addVehicle(
          householdId: widget.householdId,
          manufacturer: _manufacturerController.text.trim(),
          model: _modelController.text.trim(),
          year: year,
          licensePlate: _plateController.text.trim(),
          currentMileage: mileage,
          licenseExpiryDate: _licenseExpiry,
          mandatoryInsuranceExpiryDate: _mandatoryInsuranceExpiry,
          comprehensiveInsuranceExpiryDate: _comprehensiveInsuranceExpiry,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('שגיאה בשמירה')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _dateRow({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback? onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value != null ? DateFormatter.short(value) : AppStrings.notSetLabel,
        textDirection: TextDirection.ltr,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null && onClear != null)
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear),
          const Icon(Icons.calendar_today_outlined),
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundId =
        ref.watch(vehiclesBackgroundIdProvider(widget.householdId)).value ?? 'none';
    final background = backgroundOptionById(backgroundId);
    final hasBackground = background.id != 'none';

    final formContent = Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(labelText: AppStrings.manufacturerLabel),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.requiredFieldError : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: AppStrings.modelLabel),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.requiredFieldError : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: AppStrings.yearLabel),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plateController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: AppStrings.licensePlateLabel),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.requiredFieldError : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  enabled: !_isEditing,
                  decoration: InputDecoration(
                    labelText: AppStrings.currentMileageLabel,
                    helperText: _isEditing ? AppStrings.mileageEditedElsewhereHint : null,
                  ),
                  validator: (v) {
                    if (_isEditing) return null;
                    if (v == null || v.trim().isEmpty) return AppStrings.requiredFieldError;
                    if (int.tryParse(v.trim()) == null) return AppStrings.numberOnlyError;
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(AppStrings.importantDatesTitle, style: AppTextStyles.heading2),
                _dateRow(
                  label: AppStrings.licenseExpiryLabel,
                  value: _licenseExpiry,
                  onTap: () => _pickDate(
                    current: _licenseExpiry,
                    onPicked: (d) => setState(() => _licenseExpiry = d),
                  ),
                  onClear: () => setState(() => _licenseExpiry = null),
                ),
                _dateRow(
                  label: AppStrings.mandatoryInsuranceLabel,
                  value: _mandatoryInsuranceExpiry,
                  onTap: () => _pickDate(
                    current: _mandatoryInsuranceExpiry,
                    onPicked: (d) => setState(() => _mandatoryInsuranceExpiry = d),
                  ),
                  onClear: () => setState(() => _mandatoryInsuranceExpiry = null),
                ),
                _dateRow(
                  label: AppStrings.comprehensiveInsuranceLabel,
                  value: _comprehensiveInsuranceExpiry,
                  onTap: () => _pickDate(
                    current: _comprehensiveInsuranceExpiry,
                    onPicked: (d) => setState(() => _comprehensiveInsuranceExpiry = d),
                  ),
                  onClear: () => setState(() => _comprehensiveInsuranceExpiry = null),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(AppStrings.saveButton, style: AppTextStyles.button),
                ),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editVehicleTitle : AppStrings.addVehicleTitle),
      ),
      body: Container(
        decoration: hasBackground
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(background.gradientColors[0]),
                    Color(background.gradientColors[1]),
                  ],
                ),
              )
            : null,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: hasBackground
                ? Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(padding: const EdgeInsets.all(16), child: formContent),
                  )
                : formContent,
          ),
        ),
      ),
    );
  }
}
VEHICLES_BG_EOF

echo "כותב lib/features/vehicles/add_service_record_screen.dart..."
cat > lib/features/vehicles/add_service_record_screen.dart << 'VEHICLES_BG_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import '../../providers/vehicles_provider.dart';
import 'vehicles_background_provider.dart';

/// טופס תיעוד טיפול - גם להוספת טיפול חדש וגם לעריכת טיפול קיים
/// (אם `existing` מועבר). סוג הטיפול (מהרשימה הקבועה או "אחר" עם
/// טקסט חופשי), תאריך, ק"מ בזמן הטיפול, ואופציונלית עלות והערות.
/// שמירה מעדכנת גם את הקילומטראז' הנוכחי של הרכב אם צריך (ראה
/// VehiclesService.addServiceRecord/updateServiceRecord).
class AddServiceRecordScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String vehicleId;
  final int currentMileage;
  final String? initialTemplateKey;
  final VehicleServiceRecord? existing;

  const AddServiceRecordScreen({
    super.key,
    required this.householdId,
    required this.vehicleId,
    required this.currentMileage,
    this.initialTemplateKey,
    this.existing,
  });

  @override
  ConsumerState<AddServiceRecordScreen> createState() => _AddServiceRecordScreenState();
}

class _AddServiceRecordScreenState extends ConsumerState<AddServiceRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mileageController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;
  late final TextEditingController _customTypeController;

  String? _selectedTemplateKey;
  bool _isOther = false;
  late DateTime _performedAt;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _mileageController = TextEditingController(
      text: (existing?.mileageAtService ?? widget.currentMileage).toString(),
    );
    _costController = TextEditingController(text: existing?.cost?.toString() ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _performedAt = existing?.performedAt ?? DateTime.now();

    if (existing != null) {
      final isKnownType = kMaintenanceTemplateNames.containsKey(existing.serviceType);
      _isOther = !isKnownType;
      _selectedTemplateKey = isKnownType ? existing.serviceType : null;
      _customTypeController = TextEditingController(text: isKnownType ? '' : existing.serviceType);
    } else {
      _selectedTemplateKey = widget.initialTemplateKey ?? kMaintenanceTemplateNames.keys.first;
      _customTypeController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _performedAt,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _performedAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final serviceType = _isOther ? _customTypeController.text.trim() : _selectedTemplateKey!;
      final mileage = int.tryParse(_mileageController.text.trim()) ?? widget.currentMileage;
      final cost = _costController.text.trim().isEmpty
          ? null
          : double.tryParse(_costController.text.trim());
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      final repo = ref.read(vehiclesRepositoryProvider);
      if (_isEditing) {
        await repo.updateServiceRecord(
          householdId: widget.householdId,
          vehicleId: widget.vehicleId,
          recordId: widget.existing!.id,
          serviceType: serviceType,
          performedAt: _performedAt,
          mileageAtService: mileage,
          cost: cost,
          notes: notes,
        );
      } else {
        await repo.addServiceRecord(
          householdId: widget.householdId,
          vehicleId: widget.vehicleId,
          serviceType: serviceType,
          performedAt: _performedAt,
          mileageAtService: mileage,
          cost: cost,
          notes: notes,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('שגיאה בשמירה')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundId =
        ref.watch(vehiclesBackgroundIdProvider(widget.householdId)).value ?? 'none';
    final background = backgroundOptionById(backgroundId);
    final hasBackground = background.id != 'none';

    final formContent = Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppStrings.serviceTypeLabel, style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...kMaintenanceTemplateNames.entries.map((entry) {
                      final selected = !_isOther && _selectedTemplateKey == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _isOther = false;
                          _selectedTemplateKey = entry.key;
                        }),
                      );
                    }),
                    ChoiceChip(
                      label: const Text(AppStrings.otherServiceTypeLabel),
                      selected: _isOther,
                      onSelected: (_) => setState(() => _isOther = true),
                    ),
                  ],
                ),
                if (_isOther) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customTypeController,
                    decoration:
                        const InputDecoration(labelText: AppStrings.otherServiceTypeLabel),
                    validator: (v) {
                      if (!_isOther) return null;
                      return (v == null || v.trim().isEmpty)
                          ? AppStrings.requiredFieldError
                          : null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.serviceDateLabel),
                  subtitle: Text(
                    DateFormatter.short(_performedAt),
                    textDirection: TextDirection.ltr,
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: AppStrings.mileageAtServiceLabel),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return AppStrings.requiredFieldError;
                    if (int.tryParse(v.trim()) == null) return AppStrings.numberOnlyError;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: AppStrings.costLabelOptional),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: AppStrings.notesLabelOptional),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(AppStrings.saveButton, style: AppTextStyles.button),
                ),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editServiceRecordTitle : AppStrings.addServiceRecordTitle),
      ),
      body: Container(
        decoration: hasBackground
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(background.gradientColors[0]),
                    Color(background.gradientColors[1]),
                  ],
                ),
              )
            : null,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: hasBackground
                ? Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(padding: const EdgeInsets.all(16), child: formContent),
                  )
                : formContent,
          ),
        ),
      ),
    );
  }
}
VEHICLES_BG_EOF

echo ""
echo "=== הסתיים! ==="
echo "עכשיו תריץ: flutter pub get"
echo "ואז הפעל מחדש את שרת הפיתוח."
