/// שורה אחת שפוענחה מתוך טקסט מודבק/מוכתב - שם מוצר (לפני תיקון
/// שגיאות כתיב), כמות (1 כברירת מחדל, או מספר שזוהה בשורה), יחידת
/// מידה (למשל "ק"ג", "יחידות" - null אם לא צוינה), והערה חופשית
/// (למשל "הרבה" - null אם אין).
class ParsedShoppingLine {
  final String name;
  final double quantity;
  final String? unit;
  final String? note;

  const ParsedShoppingLine({
    required this.name,
    this.quantity = 1,
    this.unit,
    this.note,
  });
}

/// מפרק טקסט חופשי (שהודבק, למשל מוואטסאפ, או שהוכתב בקול) לרשימת
/// שורות מוצרים - שורה אחת = פריט אחד. מנקה תווי רשימה נפוצים
/// (מספור, נקודות, מקפים, תבליטים) מתחילת כל שורה, מפצל גם לפי
/// פסיקים בתוך אותה שורה (כי בהכתבה קולית כמה מוצרים לפעמים
/// מוכתבים ברצף אחד בלי ירידת שורה, ובטקסט מודבק לפעמים מפרידים
/// בפסיקים ולא בשורות), ולכל פריט בנפרד:
/// - מזהה כמות (מספר) בכל מקום בשורה - "חלב 2" או "2 חלב" נותנים
///   אותה תוצאה.
/// - אם מיד אחרי המספר יש מילת יחידת מידה מוכרת (למשל "ק"ג",
///   "גרם", "יחידות") - שומר אותה בנפרד בשדה unit, לא כחלק מהשם.
/// - אם יש מילת תיאור כמות מוכרת (כרגע: "הרבה"/"מעט"/"קצת") -
///   מוציא אותה מהשם ושם אותה בשדה note (הערה), כדי שהשם עצמו
///   יישאר נקי לזיהוי קטגוריה.
///
/// לא AI - חלוקה וניתוח טקסטואלי פשוט וצפוי, באותה רוח כמו
/// ProductCategorizer.
class ShoppingTextParser {
  ShoppingTextParser._();

  static final RegExp _leadingBullet = RegExp(
    r'^\s*(?:[\d]+[.\)\-:]|[-*•●○▪♦–]+)\s*',
  );

  static final RegExp _numberToken = RegExp(r'^\d+(?:\.\d+)?$');

  /// מפתח = הטוקן כפי שיכול להופיע בטקסט (אחרי הסרת גרשיים/גרש),
  /// ערך = הצורה התקנית שתישמר ב-unit. במכוון בלי "ל" בודד כיחידה
  /// (קיצור אפשרי ל"ליטר") - עלול להתבלבל עם מילת היחס "ל" ולגרום
  /// לזיהוי שגוי.
  static const Map<String, String> _unitAliases = {
    'קג': 'ק"ג',
    'גרם': 'גרם',
    'גר': 'גרם',
    'ליטר': 'ליטר',
    'מל': 'מ"ל',
    'יחידות': 'יחידות',
    'יח': 'יחידות',
    'חבילה': 'חבילה',
    'חבילות': 'חבילות',
    'שקית': 'שקית',
    'שקיות': 'שקיות',
    'קופסה': 'קופסה',
    'קופסאות': 'קופסאות',
    'בקבוק': 'בקבוק',
    'בקבוקים': 'בקבוקים',
  };

  /// מילות תיאור כמות נפוצות שלא שייכות לשם המוצר עצמו - מוצאות
  /// מהשם ונשמרות כהערה במקום.
  static const List<String> _noteKeywords = ['הרבה', 'מעט', 'קצת'];

  static final RegExp _quoteChars = RegExp(r'["\x27׳״]');

  static String _stripQuotes(String s) => s.replaceAll(_quoteChars, '');

  /// מפרק טקסט מודבק/מוכתב לרשימת שורות מוצרים נקיות - ללא תווי
  /// רשימה בתחילת השורה, ללא חלקים ריקים, עם כמות/יחידה/הערה
  /// מזוהות כשמצוינות.
  static List<ParsedShoppingLine> parse(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));
    final result = <ParsedShoppingLine>[];

    for (final rawLine in lines) {
      _parseLine(rawLine, result);
    }

    return result;
  }

  static void _parseLine(String rawLine, List<ParsedShoppingLine> result) {
    var cleaned = rawLine.trim();
    if (cleaned.isEmpty) return;

    // מסיר תבליט/מספור מתחילת השורה (למשל "1. חלב" -> "חלב",
    // "- ביצים" -> "ביצים") - זה מספור של הרשימה, לא כמות מוצר.
    cleaned = cleaned.replaceFirst(_leadingBullet, '').trim();
    if (cleaned.isEmpty) return;

    // אם יש כמה פריטים באותה שורה, מופרדים בפסיק - נפוץ גם בטקסט
    // מודבק ("חלב, ביצים, לחם") וגם כשמוסיפים פסיק ידנית כדי להפריד
    // בין כמה מוצרים שהוכתבו בקול ברצף אחד בלי הפסקה מספיק ארוכה
    // ליצירת שורה חדשה משלהם.
    if (cleaned.contains(',')) {
      for (final part in cleaned.split(',')) {
        _parseSegment(part.trim(), result);
      }
      return;
    }

    _parseSegment(cleaned, result);
  }

  static void _parseSegment(String segment, List<ParsedShoppingLine> result) {
    if (segment.isEmpty) return;

    final words = segment.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return;

    double quantity = 1;
    String? unit;

    // מספר יכול להופיע בכל מקום בשורה - גם "חלב 2" וגם "2 חלב"
    // נותנים אותה תוצאה.
    final quantityIndex = words.indexWhere((w) => _numberToken.hasMatch(w));
    if (quantityIndex != -1) {
      quantity = double.tryParse(words[quantityIndex]) ?? 1;
      words.removeAt(quantityIndex);

      // אם המילה שהייתה מיד אחרי המספר (עכשיו באותו אינדקס, אחרי
      // ההסרה) היא יחידת מידה מוכרת - שומרים אותה בנפרד.
      if (quantityIndex < words.length) {
        final candidate = _stripQuotes(words[quantityIndex]);
        final canonicalUnit = _unitAliases[candidate];
        if (canonicalUnit != null) {
          unit = canonicalUnit;
          words.removeAt(quantityIndex);
        }
      }
    }

    final noteWords = <String>[];
    words.removeWhere((w) {
      if (_noteKeywords.contains(w)) {
        noteWords.add(w);
        return true;
      }
      return false;
    });

    final name = words.join(' ').trim();
    if (name.isEmpty) return;

    result.add(ParsedShoppingLine(
      name: name,
      quantity: quantity,
      unit: unit,
      note: noteWords.isEmpty ? null : noteWords.join(' '),
    ));
  }
}

