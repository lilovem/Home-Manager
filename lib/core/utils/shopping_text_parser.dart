/// שורה אחת שפוענחה מתוך טקסט מודבק/מוכתב - שם מוצר (לפני תיקון
/// שגיאות כתיב), כמות (1 כברירת מחדל, או מספר שזוהה בשורה - כמספר
/// או כמילה כתובה כמו "שתי"), יחידת מידה (למשל "ק"ג", "יחידות" -
/// null אם לא צוינה), והערה חופשית (למשל "הרבה"/"גדולה" - null אם
/// אין).
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
/// פסיקים (אמיתיים, או המילה "פסיק" שנאמרה בקול) בתוך אותה שורה -
/// כי בהכתבה קולית כמה מוצרים לפעמים מוכתבים ברצף אחד בלי ירידת
/// שורה - ולכל פריט בנפרד:
/// - מזהה כמות בכל מקום בשורה, כמספר ("2") או כמילה כתובה ("שתי",
///   "שלוש") - "חלב 2" ו"2 חלב" ו"שני חלב" נותנים תוצאה דומה.
/// - אם מיד אחרי הכמות יש מילת יחידת מידה מוכרת (למשל "ק"ג",
///   "קילו", "גרם", "יחידות") - שומר אותה בנפרד בשדה unit, לא כחלק
///   מהשם.
/// - אם יש מילת תיאור נפוצה שלא שייכת לשם המוצר עצמו (כמות כמו
///   "הרבה"/"מעט", או גודל כמו "גדולה"/"קטן") - מוציא אותה מהשם ושם
///   אותה בשדה note (הערה), כדי שהשם עצמו יישאר נקי לזיהוי קטגוריה.
///
/// לא AI - חלוקה וניתוח טקסטואלי פשוט וצפוי, באותה רוח כמו
/// ProductCategorizer.
class ShoppingTextParser {
  ShoppingTextParser._();

  static final RegExp _leadingBullet = RegExp(
    r'^\s*(?:[\d]+[.\)\-:]|[-*•●○▪♦–]+)\s*',
  );

  static final RegExp _numberToken = RegExp(r'^\d+(?:\.\d+)?$');

  /// מספרים שנאמרים בקול לרוב מגיעים כמילה כתובה ולא כספרה - כולל
  /// שתי הצורות התחביריות (זכר/נקבה, וצורת סמיכות כמו "שתי" לפני
  /// שם עצם) לכל אחד מהמספרים 1 עד 10, שהם הנפוצים ביותר לכמויות
  /// ברשימת קניות.
  static const Map<String, double> _spelledNumbers = {
    'אחד': 1, 'אחת': 1,
    'שניים': 2, 'שתיים': 2, 'שני': 2, 'שתי': 2,
    'שלושה': 3, 'שלוש': 3,
    'ארבעה': 4, 'ארבע': 4,
    'חמישה': 5, 'חמש': 5,
    'שישה': 6, 'שש': 6,
    'שבעה': 7, 'שבע': 7,
    'שמונה': 8,
    'תשעה': 9, 'תשע': 9,
    'עשרה': 10, 'עשר': 10,
  };

  /// מפתח = הטוקן כפי שיכול להופיע בטקסט (אחרי הסרת גרשיים/גרש),
  /// ערך = הצורה התקנית שתישמר ב-unit. במכוון בלי "ל" בודד כיחידה
  /// (קיצור אפשרי ל"ליטר") - עלול להתבלבל עם מילת היחס "ל" ולגרום
  /// לזיהוי שגוי.
  static const Map<String, String> _unitAliases = {
    'קג': 'ק"ג',
    'קילו': 'ק"ג',
    'קילוגרם': 'ק"ג',
    'גרם': 'גרם',
    'גר': 'גרם',
    'גרמים': 'גרם',
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

  /// מילות תיאור נפוצות שלא שייכות לשם המוצר עצמו - מוצאות מהשם
  /// ונשמרות כהערה במקום. כוללות כמות ("הרבה") וגם גודל ("גדולה"),
  /// אבל לא צבע או תיאורי טעם/סוג - אלה בדרך כלל כן חלק מזהות
  /// המוצר (למשל "פלפל אדום" זה מוצר שונה מ"פלפל ירוק").
  static const List<String> _noteKeywords = [
    'הרבה', 'מעט', 'קצת',
    'גדול', 'גדולה', 'גדולים', 'גדולות',
    'קטן', 'קטנה', 'קטנים', 'קטנות',
    'בינוני', 'בינונית',
  ];

  static final RegExp _quoteChars = RegExp(r'["\x27׳״]');

  static String _stripQuotes(String s) => s.replaceAll(_quoteChars, '');

  /// מזהה כמות ממילה בודדת - כספרה ("2") או כמילה כתובה ("שתי") -
  /// null אם המילה אינה כמות בכלל.
  static double? _quantityValue(String word) {
    if (_numberToken.hasMatch(word)) return double.tryParse(word);
    return _spelledNumbers[word];
  }

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

    // מילת "פסיק" שנאמרה בקול (כדי להפריד בין מוצרים בלי סימני
    // פיסוק אמיתיים, שהכתבה קולית לא תמיד מוסיפה) מתפקדת בדיוק כמו
    // פסיק אמיתי.
    cleaned = cleaned.split(RegExp(r'\s+')).map((w) => w == 'פסיק' ? ',' : w).join(' ');

    // אם יש כמה פריטים באותה שורה, מופרדים בפסיק - נפוץ גם בטקסט
    // מודבק ("חלב, ביצים, לחם") וגם כשמוסיפים פסיק ידנית (או אומרים
    // "פסיק" בקול) כדי להפריד בין כמה מוצרים שהוכתבו ברצף אחד בלי
    // הפסקה מספיק ארוכה ליצירת שורה חדשה משלהם.
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

    // כמות יכולה להופיע בכל מקום בשורה, כספרה או כמילה כתובה - גם
    // "חלב 2" וגם "2 חלב" וגם "שתי חלב" נותנים תוצאה דומה.
    final quantityIndex = words.indexWhere((w) => _quantityValue(w) != null);
    if (quantityIndex != -1) {
      quantity = _quantityValue(words[quantityIndex]) ?? 1;
      words.removeAt(quantityIndex);

      // אם המילה שהייתה מיד אחרי הכמות (עכשיו באותו אינדקס, אחרי
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

