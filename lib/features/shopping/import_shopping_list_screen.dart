import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/product_categorizer.dart';
import '../../core/utils/shopping_text_parser.dart';
import '../../core/utils/shopping_typo_corrector.dart';
import '../../core/utils/web_speech_recognition.dart';
import '../../models/shopping_item_model.dart';

/// פריט מפוענח מטקסט מודבק, לפני שנשמר בפועל - שם (ניתן לעריכה),
/// כמות, וסימון האם לכלול אותו בהוספה הסופית. suggestions מכיל
/// הצעות תיקון שגיאת כתיב למילים שלא זוהו בוודאות - לא מוחל
/// אוטומטית על השם; המשתמשת מתבקשת לבחור מפורשות בלחיצה על "הוספה
/// לרשימה", דרך דיאלוג ייעודי (ולא באמצעות כפתורים בתוך הרשימה עצמה).
class _EditableParsedItem {
  final String originalText;
  String name;
  double quantity;
  final String? unit;
  final String? note;
  bool included;
  late final TextEditingController controller;
  late List<WordSuggestion> suggestions;

  _EditableParsedItem({
    required this.originalText,
    required this.name,
    required this.quantity,
    this.unit,
    this.note,
    this.included = true,
  }) {
    controller = TextEditingController(text: name);
    suggestions = ShoppingTypoCorrector.analyze(name);
  }

  ProductCategory get category => ProductCategorizer.categorize(name);

  /// מחליף במפורש רק את המילה הספציפית הזו בתוך השם (לא את כל
  /// השם) - כדי לא לפגוע בשאר מילות השם כשיש כמה מילים. מחשב
  /// מחדש את ההצעות לפי השם המעודכן.
  void applySuggestion(String originalWord, String candidate) {
    name = name.replaceFirst(RegExp(RegExp.escape(originalWord)), candidate);
    controller.text = name;
    suggestions = ShoppingTypoCorrector.analyze(name);
  }

  /// "השאר כך" - מבטלת את ההצעה הספציפית הזו בלי לשנות את השם.
  void dismissSuggestion(String originalWord) {
    suggestions = suggestions.where((s) => s.originalWord != originalWord).toList();
  }

  /// עריכה ידנית של השם על ידי המשתמשת - מחשב מחדש את ההצעות, כדי
  /// שאם היא כבר תיקנה את המילה בעצמה לא נשאל עליה שוב, ואם היא
  /// הכניסה מילה חדשה שנראית כשגויה נזהה זאת.
  void updateName(String value) {
    name = value;
    suggestions = ShoppingTypoCorrector.analyze(value);
  }

  void dispose() => controller.dispose();
}

/// מסך ייבוא רשימת קניות מטקסט מודבק (למשל מוואטסאפ) או מהכתבה
/// קולית.
///
/// שני "שלבים" (הדבקה/הכתבה, ואז בדיקה/עריכה של מה שזוהה) - אבל
/// באותו מסך אחד (מצב פנימי), לא שני מסכים נפרדים שנדחפים זה על
/// זה. זה מכוון: כך ש-onConfirm יכול לבצע בעצמו בדיוק את הניווט
/// המתאים לסיום (pop חזרה לרשימה קיימת, או pushReplacement למסך
/// רשימה חדשה שרק נוצרה) בלי סיבוכים של כמה מסכים בערימת הניווט.
///
/// בדיקת שגיאות כתיב לא מוצגת כרשימת כפתורים בתוך התצוגה המקדימה -
/// אלא בלחיצה על "הוספה לרשימה" קופץ דיאלוג לכל מילה חשודה, אחת
/// אחרי השנייה, ורק אחרי שכולן נענו (או נדחו) הרשימה נשמרת בפועל.
class ImportShoppingListScreen extends StatefulWidget {
  final String title;

  /// מופעל עם רשימת הטיוטות הסופית שהמשתמשת אישרה (רק הפריטים
  /// המסומנים), אחרי שכל שגיאות הכתיב האפשריות כבר נענו. אחראי גם
  /// על השמירה בפועל (הוספה לרשימה קיימת, או קודם יצירת רשימה
  /// חדשה) וגם על הניווט המתאים בסיום, דרך ה-context שמועבר אליו
  /// (context של המסך הזה עצמו, עדיין תקף בזמן הקריאה).
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
  final _speech = WebSpeechRecognition();
  List<_EditableParsedItem>? _parsedItems;
  bool _isSaving = false;

  @override
  void dispose() {
    _speech.stop();
    _pasteController.dispose();
    for (final item in _parsedItems ?? const <_EditableParsedItem>[]) {
      item.dispose();
    }
    super.dispose();
  }

  void _toggleVoiceInput() {
    if (_speech.isListening) {
      _speech.stop();
      return;
    }

    setState(() {});
    _speech.start(
      onResult: (chunk) {
        setState(() {
          final current = _pasteController.text;
          final needsNewline = current.isNotEmpty && !current.endsWith('\n');
          final updated = needsNewline ? '$current\n$chunk' : '$current$chunk';
          _pasteController.value = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: updated.length),
          );
        });
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(AppStrings.importVoiceError)));
      },
    );
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
                name: line.name,
                quantity: line.quantity,
                unit: line.unit,
                note: line.note,
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

  /// מוצג בלחיצה על "הוספה לרשימה" - עוברת פריט-פריט, ומילה-מילה,
  /// ומציגה דיאלוג לכל מילה עם הצעות תיקון שעדיין לא נענתה. רק
  /// אחרי שכל השאלות נענו (או נדחו) קוראת בפועל ל-_confirm ושומרת.
  Future<void> _resolvePendingSuggestionsThenConfirm() async {
    final items = _parsedItems ?? const <_EditableParsedItem>[];
    for (final item in items) {
      if (!item.included || item.suggestions.isEmpty) continue;

      final suggestion = item.suggestions.first;
      final chosen = await _showSuggestionDialog(suggestion);
      if (!mounted) return;

      setState(() {
        if (chosen != null) {
          item.applySuggestion(suggestion.originalWord, chosen);
        } else {
          item.dismissSuggestion(suggestion.originalWord);
        }
      });

      // אחרי טיפול בשאלה אחת, בודקים שוב מההתחלה (יכולות להיות עוד
      // מילים חשודות באותו פריט או בפריטים הבאים).
      return _resolvePendingSuggestionsThenConfirm();
    }

    await _confirm();
  }

  /// דיאלוג "האם התכוונת ל..." למילה בודדת - חוזר עם המילה שנבחרה,
  /// או null אם המשתמשת בחרה להשאיר את המילה המקורית. לא ניתן
  /// לסגור בלי לבחור (barrierDismissible: false) כדי שהתהליך יתקדם
  /// באופן ודאי לפריט הבא.
  Future<String?> _showSuggestionDialog(WordSuggestion suggestion) {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.importSuggestionDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${suggestion.originalWord}" - ${AppStrings.importSuggestionPrompt}',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final candidate in suggestion.candidates)
                    ActionChip(
                      label: Text(candidate),
                      onPressed: () => Navigator.of(dialogContext).pop(candidate),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('${AppStrings.importKeepOriginalPrefix}"${suggestion.originalWord}"'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirm() async {
    final items = _parsedItems ?? const <_EditableParsedItem>[];
    final included = items.where((item) => item.included).toList();
    if (included.isEmpty) return;

    final drafts = included
        .map((item) => ShoppingItemDraft(
              name: item.name.trim(),
              quantity: item.quantity,
              unit: item.unit,
              note: item.note,
            ))
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

  /// מציג כמות שלמה בלי ".0" מיותר (למשל "2" ולא "2.0"), אבל שומר
  /// על נקודה עשרונית כשהכמות באמת חלקית (למשל "1.5").
  String _formatQuantity(double quantity) {
    return quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
  }

  /// דיאלוג טיפ קצר להכתבה קולית - איך לגרום לכמה מוצרים שהוכתבו
  /// ברצף אחד להיכנס כל אחד בשורה נפרדת (אמירת המילה "פסיק").
  void _showVoiceHint() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.importVoiceHintTooltip),
          content: const Text(AppStrings.importVoiceHintMessage, style: AppTextStyles.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.importVoiceHintCloseButton),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasteStep() {
    final showVoiceButton = WebSpeechRecognition.isSupported;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.importInstructionsTitle,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(AppStrings.importInstructions, style: AppTextStyles.bodySecondary),
                    ],
                  ),
                ),
                if (showVoiceButton) ...[
                  IconButton(
                    icon: Icon(
                      _speech.isListening ? Icons.mic : Icons.mic_none,
                      color: _speech.isListening ? Colors.red : AppColors.primary,
                    ),
                    tooltip: AppStrings.importVoiceTooltip,
                    onPressed: _toggleVoiceInput,
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                    tooltip: AppStrings.importVoiceHintTooltip,
                    onPressed: _showVoiceHint,
                  ),
                ],
              ],
            ),
          ),
          if (showVoiceButton && _speech.isListening)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                  const SizedBox(width: 6),
                  Text(AppStrings.importVoiceListening, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
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
                hintText: 'חלב\nביצים\nלחם\nעגבניות',
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
                            onChanged: (value) => setState(() => item.updateName(value)),
                          ),
                          // שורת מידע קטנה - כמות/יחידה/הערה שזוהו
                          // אוטומטית מהטקסט, כדי שאפשר לוודא שהזיהוי
                          // נכון לפני השמירה (לא ניתנת לעריכה כאן -
                          // אם משהו לא נכון, עורכים את השם עצמו).
                          if (item.quantity != 1 || item.unit != null || item.note != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                [
                                  '${AppStrings.importQuantityLabel}: ${_formatQuantity(item.quantity)}'
                                      '${item.unit != null ? ' ${item.unit}' : ''}',
                                  if (item.note != null)
                                    '${AppStrings.importNoteLabel}: ${item.note}',
                                ].join('  ·  '),
                                style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                              ),
                            ),
                          // לא מציגים כאן כפתורי בחירה - רק סימון קטן
                          // שהמילה תיבדק בלחיצה על "הוספה לרשימה", כדי
                          // לא להעמיס על התצוגה של כל פריט בנפרד.
                          if (item.suggestions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.help_outline,
                                    size: 13,
                                    color: AppColors.itemNotFound,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.importPendingCheckLabel,
                                    style: AppTextStyles.bodySecondary
                                        .copyWith(fontSize: 11, color: AppColors.itemNotFound),
                                  ),
                                ],
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
            onPressed:
                includedCount == 0 || _isSaving ? null : _resolvePendingSuggestionsThenConfirm,
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
