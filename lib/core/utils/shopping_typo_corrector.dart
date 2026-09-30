import 'product_categorizer.dart';

/// מתקן שגיאות כתיב קלות בשם מוצר, ע"י השוואה למילות המפתח הידועות
/// כבר ב-ProductCategorizer (ProductCategorizer.allKnownWords) - ולא
/// לרשימת מילים נפרדת - כך שתיקון שגיאת כתיב תמיד "מתלכד" גם עם
/// סיווג נכון לקטגוריה (כי אותה מילה בדיוק תיחשב אח"כ בסיווג).
///
/// לא בינה מלאכותית - מרחק עריכה (Levenshtein) פשוט בין כל מילה
/// בשם המוצר לבין כל מילת מפתח ידועה. מתקן רק כשההתאמה קרובה מאוד
/// (טעות של אות אחת-שתיים בערך, יחסית לאורך המילה) כדי לא "לתקן"
/// בטעות מילים תקינות שפשוט לא הכרנו (למשל שם מוצר ייחודי או מותג).
class ShoppingTypoCorrector {
  ShoppingTypoCorrector._();

  /// מרחק עריכה בין שתי מחרוזות (כמה שינויי תו מינימליים צריך כדי
  /// להפוך אחת לשנייה) - implementation סטנדרטית של Levenshtein.
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

  /// מקסימום מרחק עריכה מותר לתיקון, יחסית לאורך המילה - מילים
  /// קצרות מדי (עד 3 תווים) לא מתוקנות בכלל (הסיכוי לתיקון שגוי
  /// גבוה מדי ביחס לאורך), מילים בינוניות (4-6) מותר טעות של אות
  /// אחת, ארוכות יותר - עד שתיים.
  static int _maxDistanceFor(int wordLength) {
    if (wordLength <= 3) return 0;
    if (wordLength <= 6) return 1;
    return 2;
  }

  /// מנסה לתקן שם מוצר שלם - עובר מילה-מילה, ולכל מילה מחפש את
  /// מילת המפתח הידועה הכי קרובה אליה (אם יש כזו בטווח המרחק
  /// המותר), ומחליף אותה. מילים שכבר תואמות מילת מפתח בדיוק, או
  /// שאין להן התאמה קרובה מספיק, נשארות בדיוק כמו שהן.
  static String correct(String productName) {
    final words = productName.split(RegExp(r'\s+'));
    final knownWords = ProductCategorizer.allKnownWords;

    final correctedWords = words.map((word) {
      if (word.isEmpty) return word;
      if (knownWords.contains(word)) return word;

      final maxDistance = _maxDistanceFor(word.length);
      if (maxDistance == 0) return word;

      String? bestMatch;
      var bestDistance = maxDistance + 1;
      for (final keyword in knownWords) {
        // סינון מקדים לפי הפרש אורך - חוסך השוואות מיותרות ומונע
        // התאמות מקריות בין מילים שונות לגמרי באורכן.
        if ((keyword.length - word.length).abs() > maxDistance) continue;
        final distance = _levenshtein(word, keyword);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestMatch = keyword;
        }
      }

      return (bestMatch != null && bestDistance <= maxDistance) ? bestMatch! : word;
    });

    return correctedWords.join(' ');
  }
}

