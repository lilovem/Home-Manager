/// שורה אחת שפוענחה מתוך טקסט מודבק - שם מוצר (לפני תיקון שגיאות
/// כתיב) וכמות (1 כברירת מחדל, או מספר שזוהה בתחילת השורה).
class ParsedShoppingLine {
  final String name;
  final double quantity;

  const ParsedShoppingLine({required this.name, this.quantity = 1});
}

/// מפרק טקסט חופשי (שהודבק, למשל מוואטסאפ) לרשימת שורות מוצרים -
/// שורה אחת = פריט אחד. מנקה תווי רשימה נפוצים (מספור, נקודות,
/// מקפים, תבליטים) מתחילת כל שורה, מזהה כמות אם מצוינת בתחילת
/// השורה, ומדלג על שורות ריקות.
///
/// לא AI - חלוקה וניקוי טקסטואלי פשוט וצפוי, באותה רוח כמו
/// ProductCategorizer.
class ShoppingTextParser {
  ShoppingTextParser._();

  static final RegExp _leadingBullet = RegExp(
    r'^\s*(?:[\d]+[.\)\-:]|[-*•●○▪♦–]+)\s*',
  );

  static final RegExp _leadingQuantity = RegExp(r'^(\d+(?:\.\d+)?)\s+(.+)$');

  /// מפרק טקסט מודבק לרשימת שורות מוצרים נקיות - ללא תווי רשימה
  /// בתחילת השורה, ללא שורות ריקות, עם כמות מזוהה כשמצוינת.
  static List<ParsedShoppingLine> parse(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));
    final result = <ParsedShoppingLine>[];

    for (final rawLine in lines) {
      var cleaned = rawLine.trim();
      if (cleaned.isEmpty) continue;

      // מסיר תבליט/מספור מתחילת השורה (למשל "1. חלב" -> "חלב",
      // "- ביצים" -> "ביצים").
      cleaned = cleaned.replaceFirst(_leadingBullet, '').trim();
      if (cleaned.isEmpty) continue;

      // מזהה כמות אם השורה מתחילה במספר ואחריו רווח ואז טקסט
      // (למשל "2 חלב" -> כמות 2, שם "חלב"). אם אין התאמה, כל
      // השורה היא השם והכמות נשארת 1 (ברירת המחדל).
      final quantityMatch = _leadingQuantity.firstMatch(cleaned);
      if (quantityMatch != null) {
        final quantity = double.tryParse(quantityMatch.group(1)!);
        final name = quantityMatch.group(2)!.trim();
        if (quantity != null && name.isNotEmpty) {
          result.add(ParsedShoppingLine(name: name, quantity: quantity));
          continue;
        }
      }

      result.add(ParsedShoppingLine(name: cleaned));
    }

    return result;
  }
}

