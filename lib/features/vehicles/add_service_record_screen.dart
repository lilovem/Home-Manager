import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
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
                    formatPrettyDateHe(_performedAt),
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
