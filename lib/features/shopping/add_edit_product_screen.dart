import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../models/shopping_item_model.dart';

/// תוצאת הטופס - שם, כמות ויחידת מידה (אופציונלי).
class ProductFormResult {
  final String name;
  final double quantity;
  final String? unit;

  const ProductFormResult({
    required this.name,
    required this.quantity,
    this.unit,
  });
}

/// מסך הוספה/עריכה של מוצר. משמש גם ליצירה (existingItem == null)
/// וגם לעריכה (existingItem != null), כדי לא לשכפל קוד טופס.
class AddEditProductScreen extends StatefulWidget {
  final ShoppingItem? existingItem;

  const AddEditProductScreen({super.key, this.existingItem});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    _quantityController = TextEditingController(
      text: (widget.existingItem?.quantity ?? 1).toString(),
    );
    _unitController = TextEditingController(text: widget.existingItem?.unit ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      ProductFormResult(
        name: _nameController.text.trim(),
        quantity: double.parse(_quantityController.text),
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editProduct : AppStrings.addProduct),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  decoration: const InputDecoration(labelText: AppStrings.productName),
                  validator: (value) =>
                      Validators.requiredText(value, fieldName: AppStrings.productName),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: AppStrings.quantity),
                  validator: Validators.positiveNumber,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: AppStrings.unit),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(AppStrings.save, style: AppTextStyles.button),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

