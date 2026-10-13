import 'package:flutter/material.dart';

/// קטגוריות מוצרים אפשריות לרשימת קניות של הבית.
enum ProductCategory {
  produce,
  dairy,
  meatFishPoultry,
  bakery,
  frozen,
  pantry,
  spicesAndSauces,
  beverages,
  snacks,
  cleaning,
  toiletries,
  other,
}

/// מסווג מוצרים אוטומטית לקטגוריה, לפי מילות מפתח בשם המוצר.
///
/// זהו סיווג מבוסס טקסט (לא AI) - פשוט, צפוי, וניתן להרחבה בקלות
/// ע"י הוספת מילות מפתח ל-_keywords. אינו נשמר ב-Firestore בכוונה -
/// מחושב תמיד מחדש משם המוצר, כך שעריכת שם מוצר קיים מעדכנת
/// אוטומטית גם את הקטגוריה שלו.
class ProductCategorizer {
  ProductCategorizer._();

  static const Map<ProductCategory, String> categoryNames = {
    ProductCategory.produce: 'ירקות ופירות',
    ProductCategory.dairy: 'מוצרי חלב',
    ProductCategory.meatFishPoultry: 'בשר, עוף ודגים',
    ProductCategory.bakery: 'לחם ומאפים',
    ProductCategory.frozen: 'קפואים',
    ProductCategory.pantry: 'מזון יבש ושימורים',
    ProductCategory.spicesAndSauces: 'תבלינים ורטבים',
    ProductCategory.beverages: 'משקאות',
    ProductCategory.snacks: 'חטיפים וממתקים',
    ProductCategory.cleaning: 'ניקיון',
    ProductCategory.toiletries: 'טואלטיקה וטיפוח',
    ProductCategory.other: 'שונות',
  };

  /// סדר תצוגה קבוע - בערך לפי סדר מדפים אופייני בסופרמרקט.
  static const List<ProductCategory> displayOrder = [
    ProductCategory.produce,
    ProductCategory.dairy,
    ProductCategory.meatFishPoultry,
    ProductCategory.bakery,
    ProductCategory.frozen,
    ProductCategory.pantry,
    ProductCategory.spicesAndSauces,
    ProductCategory.beverages,
    ProductCategory.snacks,
    ProductCategory.cleaning,
    ProductCategory.toiletries,
    ProductCategory.other,
  ];

  /// אימוג'י ספציפי למוצר, אם השם מזהה משהו מוכר (חלב, דג וכו') -
  /// null אם לא זוהה כלום ספציפי, ואז נופלים חזרה לאייקון הקטגוריה
  /// הכללי. בדיקה לפי הכלה (contains) בשם המוצר, לא התאמה מדויקת.
  static String? productEmoji(String name) {
    final n = name.trim();
    const map = <String, String>{
      'חלב': '🥛',
      'קוטג': '🧀',
      'גבינה': '🧀',
      'יוגורט': '🥣',
      'חמאה': '🧈',
      'ביצ': '🥚',
      'דג': '🐟',
      'סלמון': '🐟',
      'טונה': '🐟',
      'עוף': '🍗',
      'הודו': '🍗',
      'בשר': '🥩',
      'סטייק': '🥩',
      'המבורגר': '🍔',
      'נקניק': '🌭',
      'לחם': '🍞',
      'פיתה': '🍞',
      'בגט': '🍞',
      'חלה': '🍞',
      'עגבני': '🍅',
      'מלפפון': '🥒',
      'גזר': '🥕',
      'בצל': '🧅',
      'שום': '🧄',
      'פלפל': '🫑',
      'תפוח אדמה': '🥔',
      'תפו"א': '🥔',
      'חסה': '🥬',
      'תרד': '🥬',
      'ברוקולי': '🥦',
      'אבוקדו': '🥑',
      'תפוח': '🍎',
      'בננה': '🍌',
      'תפוז': '🍊',
      'קלמנטינה': '🍊',
      'לימון': '🍋',
      'ענב': '🍇',
      'אבטיח': '🍉',
      'תות': '🍓',
      'אננס': '🍍',
      'אורז': '🍚',
      'פסטה': '🍝',
      'ספגטי': '🍝',
      'שוקולד': '🍫',
      'עוגי': '🍪',
      'עוגה': '🍰',
      'גלידה': '🍦',
      'קפה': '☕',
      'תה': '🍵',
      'מים': '💧',
      'מיץ': '🧃',
      'יין': '🍷',
      'בירה': '🍺',
      'סוכר': '🍬',
      'ממתק': '🍬',
      'קמח': '🌾',
      'שמן': '🫒',
      'ביסלי': '🍟',
      'צ\'יפס': '🍟',
      'פופקורן': '🍿',
      'סבון': '🧼',
      'שמפו': '🧴',
      'נייר טואלט': '🧻',
    };

    String? best;
    var bestScore = -1;
    for (final entry in map.entries) {
      final score = _matchScore(n, entry.key);
      if (score > bestScore) {
        bestScore = score;
        best = entry.value;
      }
    }
    return best;
  }

  /// אייקון קטן לכל קטגוריה, מוצג ליד שם המוצר ברשימה - נופל אליו
  /// productEmoji() כשלא זוהה מוצר ספציפי.
  static const Map<ProductCategory, IconData> categoryIcons = {
    ProductCategory.produce: Icons.eco_outlined,
    ProductCategory.dairy: Icons.icecream_outlined,
    ProductCategory.meatFishPoultry: Icons.set_meal_outlined,
    ProductCategory.bakery: Icons.bakery_dining_outlined,
    ProductCategory.frozen: Icons.ac_unit,
    ProductCategory.pantry: Icons.rice_bowl_outlined,
    ProductCategory.spicesAndSauces: Icons.liquor_outlined,
    ProductCategory.beverages: Icons.local_drink_outlined,
    ProductCategory.snacks: Icons.cookie_outlined,
    ProductCategory.cleaning: Icons.cleaning_services_outlined,
    ProductCategory.toiletries: Icons.soap_outlined,
    ProductCategory.other: Icons.shopping_bag_outlined,
  };

  /// צבע חי וייחודי לכל קטגוריה - לרקע העיגול הקטן ליד כל מוצר.
  static const Map<ProductCategory, Color> categoryColors = {
    ProductCategory.produce: Color(0xFF43A047), // ירוק
    ProductCategory.dairy: Color(0xFF1E88E5), // כחול
    ProductCategory.meatFishPoultry: Color(0xFFE53935), // אדום
    ProductCategory.bakery: Color(0xFFB8600B), // חום-כתום
    ProductCategory.frozen: Color(0xFF00ACC1), // תכלת
    ProductCategory.pantry: Color(0xFFFB8C00), // כתום
    ProductCategory.spicesAndSauces: Color(0xFF8E24AA), // סגול
    ProductCategory.beverages: Color(0xFF00897B), // טורקיז
    ProductCategory.snacks: Color(0xFFF4511E), // כתום-אדום
    ProductCategory.cleaning: Color(0xFF3949AB), // כחול-סגול
    ProductCategory.toiletries: Color(0xFFD81B60), // ורוד
    ProductCategory.other: Color(0xFF757575), // אפור
  };

  static const Map<ProductCategory, List<String>> _keywords = {
    ProductCategory.dairy: [
      'חלב', 'גבינה', 'גבינת', 'גבינות', 'יוגורט', 'קוטג', 'שמנת', 'חמאה',
      'מעדן', 'דנונה', 'לאבנה', 'ריקוטה', 'מוצרלה', 'פרמזן', 'קממבר',
      'גבינה צהובה', 'גבינה לבנה', 'שמנת מתוקה', 'שמנת חמוצה', 'קרם פרש',
      'אקסל', 'מילקי', 'יופלה', 'שוקו', 'חלב סויה', 'חלב שקדים', 'חלב שיבולת',
      'בולגרית', 'צפתית', 'פטה', 'קשקבל', 'עמק', 'ביצים', 'ביצה', 'ביצי',
    ],
    ProductCategory.meatFishPoultry: [
      'עוף', 'בשר', 'דג', 'דגים', 'סלמון', 'טונה טרי', 'הודו',
      'נקניק', 'נקניקיה', 'קציצות', 'שניצל', 'סטייק', 'המבורגר',
      'כבד', 'פרגית', 'כרעיים', 'חזה עוף', 'טחון', 'צלעות', 'אנטריקוט',
      'כנפיים', 'שוק עוף', 'פילה', 'קבב', 'שווארמה', 'בקר', 'כבש', 'נתחי',
      'נגיסים', 'אמנון', 'דניס', 'לברק', 'מושט', 'בורי', 'סרדין טרי', 'סלמי',
      'פסטרמה', 'אסאדו', 'ריבס',
    ],
    ProductCategory.produce: [
      'עגבני', 'מלפפון', 'תפוח', 'בננה', 'תפוז', 'חסה', 'גזר',
      'בצל', 'שום', 'פלפל', 'תפוח אדמה', 'תות', 'אבוקדו', 'לימון',
      'ירק', 'פרי', 'ענבים', 'קישוא', 'ברוקולי', 'כרובית', 'אבטיח',
      'מלון', 'אפרסק', 'שזיף', 'אגס', 'פטריות', 'כרוב', 'סלרי',
      'תפוחי אדמה', 'בטטה', 'חציל', 'דלעת', 'סלק', 'צנון', 'צנונית',
      'נענע', 'פטרוזיליה', 'כוסברה', 'שמיר', 'בזיליקום', 'עירית', 'תרד',
      'קלמנטינה', 'אשכולית', 'מנדרינה', 'אפרסמון', 'רימון', 'תמר', 'תאנ',
      'דובדבן', 'ענב', 'מנגו', 'אננס', 'קיווי', 'נקטרינה', 'שסק', 'פומלה',
      'לפת', 'קולורבי', 'כרישה', 'ג׳ינג׳ר', 'זנגביל', 'שעועית ירוקה',
    ],
    ProductCategory.bakery: [
      'לחם', 'פיתה', 'בגט', 'חלה', 'לחמניה', 'לחמניות', 'עוגה', 'עוגת', 'עוגיות',
      'קרואסון', 'בורקס', 'טוסט', 'באגט', 'מאפה', 'מאפים', 'רוגלך', 'בייגל',
      'לאפה', 'טורטייה', 'פיתות', 'כיכר', 'מלאווח', 'ג׳חנון', 'מצה', 'דונאט',
    ],
    ProductCategory.frozen: [
      'קפוא', 'קפואה', 'קפואים', 'גלידה', 'ופל', 'קפואות', 'גלידת', 'שלגון',
      'בצק עלים', 'פופסיקל',
    ],
    ProductCategory.pantry: [
      'אורז', 'פסטה', 'קמח', 'סוכר', 'שימורי', 'קטניות', 'עדשים',
      'שעועית', 'קורנפלקס', 'דגני בוקר', 'שמן', 'טחינה', 'חומוס יבש',
      'פתיתים', 'קוסקוס', 'בורגול', 'סוכר חום', 'אבקת סוכר', 'סוכרזית',
      'ממרח', 'שוקולד השחה', 'ריבה', 'דבש', 'סילאן', 'אבקת אפייה', 'שמרים',
      'עמילן', 'סולת', 'שיבולת שועל', 'גרנולה', 'קוואקר', 'מרק', 'אטריות',
      'ספגטי', 'מקרוני', 'פנה', 'פוסילי', 'תירס', 'זיתים', 'מלפפונים חמוצים',
      'חמוצים', 'טונה', 'סרדינים', 'חומוס', 'פול', 'אפונה', 'גרעינים', 'שומשום',
      'קינואה', 'חומוס גרגירים', 'עגבניות מרוסקות', 'רסק עגבניות', 'פירורי לחם',
      'פתיבר', 'ביסקוויט', 'דגני', 'אורז בסמטי', 'אורז יסמין', 'שמן קנולה',
      'שמן חמניות', 'נייר אפייה', 'חלבה', 'קקאו', 'אבקת פודינג',
    ],
    ProductCategory.spicesAndSauces: [
      'מלח', 'פלפל שחור', 'תבלין', 'רוטב', 'קטשופ', 'מיונז',
      'חרדל', 'סויה', 'שמן זית', 'חומץ', 'פפריקה', 'כמון',
      'כורכום', 'קינמון', 'אורגנו', 'שום גרוס', 'שום מיובש', 'ברביקיו', 'טריאקי',
      'סרירצ׳ה', 'פלפל חריף', 'זעתר', 'חילבה', 'קארי', 'סומק',
      'וניל', 'אבקת מרק', 'צ׳ילי', 'חרדל דיז׳ון', 'פסטו', 'רוטב עגבניות',
    ],
    ProductCategory.beverages: [
      'מים', 'מיץ', 'קולה', 'סודה', 'בירה', 'יין', 'קפה', 'תה',
      'משקה', 'סיידר', 'מינרלים', 'נביעות', 'פריגת', 'קפסולות', 'נס קפה',
      'שתייה', 'לימונדה', 'אייס טי', 'וודקה', 'וויסקי', 'ערק', 'משקאות',
      'ספרייט', 'פנטה', 'שוופס', 'טמפו', 'אנרגיה', 'קפה שחור', 'נס',
    ],
    ProductCategory.snacks: [
      'שוקולד', 'חטיף', 'במבה', 'ביסלי', 'צ\'יפס', 'סוכריות',
      'גומי', 'פופקורן', 'בוטנים', 'אגוזים', 'חטיפים', 'ממתק', 'ממתקים',
      'וופלים', 'עוגיות שוקולד', 'מסטיק', 'גרעיני דלעת', 'גרעיני חמניות',
      'פיסטוק', 'שקדים', 'קשיו', 'צימוקים', 'פירות יבשים', 'תמרים', 'מרשמלו',
      'פסק זמן', 'קליק', 'כיף כף', 'אוראו', 'תפוצ׳יפס', 'דורו', 'צ׳יטוס', 'דוריטוס',
    ],
    ProductCategory.cleaning: [
      'סבון כלים', 'אקונומיקה', 'מנקה', 'כביסה', 'מרכך', 'שקיות אשפה',
      'נייר סופג', 'ספוג', 'אבקת כביסה', 'נוזל כלים', 'מסיר שומנים',
      'מטלית', 'שקיות', 'אשפה', 'מגבות נייר', 'מחסל', 'מדביר', 'שטיפה',
      'חומר ניקוי', 'סנו', 'פיירי', 'טבליות מדיח', 'מלח למדיח', 'נייר כסף',
      'ניילון נצמד', 'סקוץ', 'מטאטא', 'מגב', 'כפפות', 'מנקה חלונות',
    ],
    ProductCategory.toiletries: [
      'שמפו', 'סבון', 'משחת שיניים', 'דאודורנט', 'נייר טואלט',
      'מגבונים', 'טיטול', 'פד', 'קרם', 'מברשת שיניים', 'מרכך שיער',
      'סכיני גילוח', 'קצף גילוח', 'ספוגית', 'אוזניים', 'תחבושות', 'טמפונים',
      'לק', 'מסיר לק', 'בושם', 'קרם הגנה', 'קרם ידיים', 'חיתולים', 'ג׳ל רחצה',
      'סבון גוף', 'סבון ידיים', 'דאודורנט', 'מי פה', 'חוט דנטלי', 'צמר גפן',
    ],
  };

  static const Set<String> _prefixLetters = {'ה', 'ו', 'ב', 'כ', 'ל', 'מ', 'ש'};

  /// מילה קצרה (עד 3 אותיות) חייבת להיות זהה למילת המפתח (או ברבים
  /// "ים"/"ות") - אחרת "דג" יתפוס "דגני בוקר", "שום" את "שומשום" וכו'.
  static bool _wordMatches(String word, String keyword) {
    if (keyword.length <= 3) {
      return word == keyword || word == '${keyword}ים' || word == '${keyword}ות';
    }
    return word.startsWith(keyword);
  }

  /// ציון התאמה בין שם מוצר למילת מפתח: -1 אם אין התאמה. התאמה היא
  /// ברמת מילים (לא "מכיל" בתוך מילה אחרת), כולל אות יחס בתחילת מילה
  /// (ה/ו/ב/כ/ל/מ/ש). ככל שהמילה/הביטוי ארוך יותר - הציון גבוה יותר,
  /// והתאמה במילה הראשונה (שהיא בדרך כלל שם המוצר עצמו, ולא תיאור)
  /// מקבלת בונוס - כך "סוכר לבן" הוא סוכר ולא לבן, ו"חלב שוקולד"
  /// הוא חלב ולא שוקולד.
  static final RegExp _quoteChars = RegExp("['\"׳’]");

  static int _matchScore(String rawName, String rawKeyword) {
    // מתעלמים מגרש/גרשיים (קוטג', צ'יפס, ג'חנון) בשני הצדדים - גם
    // הגרש הרגיל וגם גרש עברי, כדי שההתאמה לא תלויה באיך הוקלד.
    final normalizedName = rawName.replaceAll(_quoteChars, '');
    final keyword = rawKeyword.replaceAll(_quoteChars, '');
    final words = normalizedName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final keywordWords = keyword.trim().split(' ').length;

    for (var i = 0; i < words.length; i++) {
      if (i + keywordWords > words.length) break;
      final candidate = words.sublist(i, i + keywordWords).join(' ');

      var matched = _wordMatches(candidate, keyword.trim());
      if (!matched && candidate.length > 3 && _prefixLetters.contains(candidate[0])) {
        matched = _wordMatches(candidate.substring(1), keyword.trim());
      }
      if (matched) return keyword.length + (i == 0 ? 6 : 0);
    }
    return -1;
  }

  /// כל מילות המפתח הידועות (משוטחות מכל הקטגוריות, ללא כפילויות) -
  /// משמש את ShoppingTypoCorrector כדי לתקן שגיאות כתיב קלות מול
  /// אותה רשימה בדיוק שממנה מחושבת הקטגוריה, כך שתיקון שם תמיד
  /// "מתלכד" גם עם סיווג נכון.
  static List<String> get allKnownWords =>
      _keywords.values.expand((words) => words).toSet().toList();

  /// מזהה את הקטגוריה המתאימה ביותר לשם מוצר נתון.
  /// אם אין התאמה לאף מילת מפתח, מוחזרת הקטגוריה "שונות".
  static ProductCategory categorize(String productName) {
    final normalized = productName.trim();
    if (normalized.isEmpty) return ProductCategory.other;

    // "קפוא/ה/ים" בכל מקום בשם = קפואים ("בורקס קפוא", "אפונה קפואה").
    if (normalized.split(RegExp(r'\s+')).any((w) => w.startsWith('קפוא'))) {
      return ProductCategory.frozen;
    }
    // "לבן" כשם מוצר בפני עצמו = משקה חלב; כתיאור ("סוכר לבן") - לא.
    if (normalized.split(RegExp(r'\s+')).first == 'לבן') {
      return ProductCategory.dairy;
    }

    ProductCategory? best;
    var bestScore = -1;
    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        final score = _matchScore(normalized, keyword);
        if (score > bestScore) {
          bestScore = score;
          best = entry.key;
        }
      }
    }
    return best ?? ProductCategory.other;
  }
}
