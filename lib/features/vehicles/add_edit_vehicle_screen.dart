import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
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
        value != null ? formatPrettyDateHe(value) : AppStrings.notSetLabel,
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
