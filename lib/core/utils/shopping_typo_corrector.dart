import 'product_categorizer.dart';

/// הצעת תיקון למילה בודדת שלא זוהתה בוודאות - "האם התכוונת ל...":
/// המילה המקורית שהמשתמשת כתבה, ורשימת מועמדים (עד 3, מהקרוב
/// לרחוק) מתוך מילות המפתח הידועות.
class WordSuggestion {
  final String originalWord;
  final List<String> candidates;

  const WordSuggestion({required this.originalWord, required this.candidates});
}

/// מזהה מילים בשם מוצר שאולי יש בהן שגיאת כתיב, ומציע חלופות -
/// **בלי לתקן אוטומטית**. ההחלטה הסופית תמיד של המשתמשת: אם מילה
/// לא זוהתה כמילת מפתח ידועה, אבל יש לה מועמדים קרובים (טעות של
/// אות אחת-שתיים, יחסית לאורך המילה), המילה מדוגלת כדי שהמשתמשת
/// תבחר בעצמה מבין האפשרויות (למשל "חלכ" -> "חלה" או "חלב") -
/// המערכת לא מנחשת בשמה.
///
/// לא בינה מלאכותית - מרחק עריכה (Levenshtein) פשוט מול מילות
/// המפתח הידועות כבר ב-ProductCategorizer (ProductCategorizer.allKnownWords),
/// כך שכל הצעה גם "מתלכדת" אוטומטית עם סיווג נכון לקטגוריה ברגע
/// שהמשתמשת בוחרת בה.
class ShoppingTypoCorrector {
  ShoppingTypoCorrector._();

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previousRow = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final currentRow = List<int>.filled(b.length + 1, 0);
      currentRow[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final deletionCost = previousRow[j + 1] + 1;
        final insertionCost = currentRow[j] + 1;
        final substitutionCost = previousRow[j] + (a[i] == b[j] ? 0 : 1);
        currentRow[j + 1] = [deletionCost, insertionCost, substitutionCost]
            .reduce((v, e) => v < e ? v : e);
      }
      previousRow = currentRow;
    }
    return previousRow[b.length];
  }

  /// מקסימום מרחק עריכה שעדיין נחשב "אולי שגיאת כתיב", יחסית לאורך
  /// המילה - מילים קצרות מדי (עד 3 תווים) לא נבדקות בכלל (יותר מדי
  /// מועדות להצעות שגויות ביחס לאורכן), בינוניות (4-6) עד טעות אחת,
  /// ארוכות יותר - עד שתיים.
  static int _maxDistanceFor(int wordLength) {
    if (wordLength <= 3) return 0;
    if (wordLength <= 6) return 1;
    return 2;
  }

  /// בודקת אם מילה כבר "מוכרת" בלי להצריך התאמה מדויקת - בדיוק כמו
  /// שProductCategorizer.categorize() בעצמו מזהה מוצר (לפי הכלה,
  /// לא שוויון מדויק). כך "עגבניות" (רבים) מזוהה כמוכר כי הוא מכיל
  /// את מילת המפתח "עגבני" (היחיד/גזע המילה), בלי שנצטרך לרשום כל
  /// צורת רבים/יחיד בנפרד - ובלי לדגול בטעות במילה תקינה רק בגלל
  /// שצורת הרבים/היחיד שלה לא רשומה מילה במילה.
  static bool _isKnownWord(String word, List<String> knownWords) {
    for (final keyword in knownWords) {
      if (word.contains(keyword) || keyword.contains(word)) return true;
    }
    return false;
  }

  /// מחזיר עד [maxSuggestions] מילות מפתח קרובות למילה נתונה (ממוינות
  /// מהקרובה לרחוקה) - רשימה ריקה אם המילה כבר מוכרת (ראה
  /// _isKnownWord), או שאין אף מועמד קרוב מספיק (המילה כנראה תקינה,
  /// פשוט לא מוכרת - למשל שם מוצר ייחודי או מותג, ולא שגיאת כתיב).
  static List<String> suggestionsFor(String word, {int maxSuggestions = 3}) {
    final knownWords = ProductCategorizer.allKnownWords;
    if (word.isEmpty || _isKnownWord(word, knownWords)) return const [];

    final maxDistance = _maxDistanceFor(word.length);
    if (maxDistance == 0) return const [];

    final scored = <MapEntry<String, int>>[];
    for (final keyword in knownWords) {
      // סינון מקדים לפי הפרש אורך - חוסך השוואות מיותרות ומונע
      // התאמות מקריות בין מילים שונות לגמרי באורכן.
      if ((keyword.length - word.length).abs() > maxDistance) continue;
      final distance = _levenshtein(word, keyword);
      if (distance <= maxDistance) {
        scored.add(MapEntry(keyword, distance));
      }
    }
    scored.sort((a, b) => a.value.compareTo(b.value));

    final seen = <String>{};
    final result = <String>[];
    for (final entry in scored) {
      if (seen.add(entry.key)) result.add(entry.key);
      if (result.length >= maxSuggestions) break;
    }
    return result;
  }

  /// מנתח שם מוצר שלם מילה-מילה, ומחזיר הצעת תיקון לכל מילה שאולי
  /// כתובה לא נכון (ראה suggestionsFor) - בלי לשנות את השם עצמו.
  static List<WordSuggestion> analyze(String productName) {
    final words = productName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final result = <WordSuggestion>[];
    for (final word in words) {
      final candidates = suggestionsFor(word);
      if (candidates.isNotEmpty) {
        result.add(WordSuggestion(originalWord: word, candidates: candidates));
      }
    }
    return result;
  }
}

