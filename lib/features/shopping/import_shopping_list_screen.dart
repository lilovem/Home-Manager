import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/product_categorizer.dart';
import '../../core/utils/shopping_text_parser.dart';
import '../../core/utils/shopping_typo_corrector.dart';
import '../../models/shopping_item_model.dart';

/// פריט מפוענח מטקסט מודבק, לפני שנשמר בפועל - שם (ניתן לעריכה,
/// כבר אחרי ניסיון תיקון שגיאת כתיב אוטומטי), כמות, וסימון האם
/// לכלול אותו בהוספה הסופית. originalText משמש רק כדי להראות
/// למשתמשת "במקור: ..." כשהתיקון האוטומטי שינה את השם, כדי שתוכל
/// לתקן בעצמה אם הניחוש שגוי.
class _EditableParsedItem {
  final String originalText;
  String name;
  double quantity;
  bool included;
  late final TextEditingController controller;

  _EditableParsedItem({
    required this.originalText,
    required this.name,
    required this.quantity,
    this.included = true,
  }) {
    controller = TextEditingController(text: name);
  }

  ProductCategory get category => ProductCategorizer.categorize(name);
  bool get wasCorrected => name != originalText;

  void dispose() => controller.dispose();
}

/// מסך ייבוא רשימת קניות מטקסט מודבק (למשל מוואטסאפ).
///
/// שני "שלבים" (הדבקת טקסט, ואז בדיקה/עריכה של מה שזוהה) - אבל
/// באותו מסך אחד (מצב פנימי), לא שני מסכים נפרדים שנדחפים זה על
/// זה. זה מכוון: כך ש-onConfirm יכול לבצע בעצמו בדיוק את הניווט
/// המתאים לסיום (pop חזרה לרשימה קיימת, או pushReplacement למסך
/// רשימה חדשה שרק נוצרה) בלי סיבוכים של כמה מסכים בערימת הניווט.
class ImportShoppingListScreen extends StatefulWidget {
  final String title;

  /// מופעל עם רשימת הטיוטות הסופית שהמשתמשת אישרה (רק הפריטים
  /// המסומנים). אחראי גם על השמירה בפועל (הוספה לרשימה קיימת, או
  /// קודם יצירת רשימה חדשה) וגם על הניווט המתאים בסיום, דרך ה-
  /// context שמועבר אליו (context של המסך הזה עצמו, עדיין תקף
  /// בזמן הקריאה).
  final Future<void> Function(BuildContext context, List<ShoppingItemDraft> items) onConfirm;

  const ImportShoppingListScreen({
    super.key,
    required this.title,
    required this.onConfirm,
  });

  @override
  State<ImportShoppingListScreen> createState() => _ImportShoppingListScreenState();
}

class _ImportShoppingListScreenState extends State<ImportShoppingListScreen> {
  final _pasteController = TextEditingController();
  List<_EditableParsedItem>? _parsedItems;
  bool _isSaving = false;

  @override
  void dispose() {
    _pasteController.dispose();
    for (final item in _parsedItems ?? const <_EditableParsedItem>[]) {
      item.dispose();
    }
    super.dispose();
  }

  void _parse() {
    final lines = ShoppingTextParser.parse(_pasteController.text);
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.importNoItemsDetected)));
      return;
    }

    setState(() {
      _parsedItems = lines
          .map((line) => _EditableParsedItem(
                originalText: line.name,
                name: ShoppingTypoCorrector.correct(line.name),
                quantity: line.quantity,
              ))
          .toList();
    });
  }

  void _backToPaste() {
    setState(() {
      for (final item in _parsedItems ?? const <_EditableParsedItem>[]) {
        item.dispose();
      }
      _parsedItems = null;
    });
  }

  Future<void> _confirm() async {
    final items = _parsedItems ?? const <_EditableParsedItem>[];
    final included = items.where((item) => item.included).toList();
    if (included.isEmpty) return;

    final drafts = included
        .map((item) => ShoppingItemDraft(name: item.name.trim(), quantity: item.quantity))
        .where((draft) => draft.name.isNotEmpty)
        .toList();
    if (drafts.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await widget.onConfirm(context, drafts);
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _parsedItems;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: items == null ? _buildPasteStep() : _buildPreviewStep(items),
      ),
    );
  }

  Widget _buildPasteStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.importInstructions, style: AppTextStyles.bodySecondary),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _pasteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '1. חלב\n2. ביצים\nלחם\nעגבניות',
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _parse,
            child: Text(AppStrings.importParseButton, style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(List<_EditableParsedItem> items) {
    final includedCount = items.where((item) => item.included).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(AppStrings.importPreviewTitle, style: AppTextStyles.heading2),
              ),
              TextButton(
                onPressed: _backToPaste,
                child: const Text(AppStrings.importBackToPaste),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: item.included,
                      activeColor: AppColors.primary,
                      onChanged: (value) => setState(() => item.included = value ?? false),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 12, left: 4, right: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ProductCategorizer.categoryColors[item.category],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ProductCategorizer.categoryIcons[item.category],
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: item.controller,
                            textDirection: TextDirection.rtl,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onChanged: (value) => setState(() => item.name = value),
                          ),
                          if (item.wasCorrected)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${AppStrings.importOriginalTextPrefix}${item.originalText}',
                                style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: includedCount == 0 || _isSaving ? null : _confirm,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    '${AppStrings.importConfirmButton} ($includedCount)',
                    style: AppTextStyles.button,
                  ),
          ),
        ),
      ],
    );
  }
}

