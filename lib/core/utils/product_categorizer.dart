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

    for (final entry in map.entries) {
      if (n.contains(entry.key)) return entry.value;
    }
    return null;
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
      'חלב', 'גבינה', 'גבינת', 'יוגורט', 'קוטג', 'שמנת', 'חמאה',
      'לבן', 'מעדן', 'אשל', 'דנונה', 'קוטג\'', 'לאבנה', 'ריקוטה',
    ],
    ProductCategory.meatFishPoultry: [
      'עוף', 'בשר', 'דג', 'דגים', 'סלמון', 'טונה טרי', 'הודו',
      'נקניק', 'נקניקיה', 'קציצות', 'שניצל', 'סטייק', 'המבורגר',
      'כבד', 'פרגית', 'כרעיים', 'חזה עוף', 'טחון', 'צלעות',
    ],
    ProductCategory.produce: [
      'עגבני', 'מלפפון', 'תפוח', 'בננה', 'תפוז', 'חסה', 'גזר',
      'בצל', 'שום', 'פלפל', 'תפוח אדמה', 'תות', 'אבוקדו', 'לימון',
      'ירק', 'פרי', 'ענבים', 'קישוא', 'ברוקולי', 'כרובית', 'אבטיח',
      'מלון', 'אפרסק', 'שזיף', 'אגס', 'פטריות', 'כרוב', 'סלרי',
    ],
    ProductCategory.bakery: [
      'לחם', 'פיתה', 'בגט', 'חלה', 'לחמניה', 'עוגה', 'עוגיות',
      'קרואסון', 'בורקס', 'טוסט',
    ],
    ProductCategory.frozen: [
      'קפוא', 'קפואה', 'קפואים', 'גלידה', 'ופל',
    ],
    ProductCategory.pantry: [
      'אורז', 'פסטה', 'קמח', 'סוכר', 'שימורי', 'קטניות', 'עדשים',
      'שעועית', 'קורנפלקס', 'דגני בוקר', 'שמן', 'טחינה', 'חומוס יבש',
      'פתיתים', 'קוסקוס', 'בורגול',
    ],
    ProductCategory.spicesAndSauces: [
      'מלח', 'פלפל שחור', 'תבלין', 'רוטב', 'קטשופ', 'מיונז',
      'חרדל', 'סויה', 'שמן זית', 'חומץ', 'פפריקה', 'כמון',
    ],
    ProductCategory.beverages: [
      'מים', 'מיץ', 'קולה', 'סודה', 'בירה', 'יין', 'קפה', 'תה',
      'משקה', 'סיידר',
    ],
    ProductCategory.snacks: [
      'שוקולד', 'חטיף', 'במבה', 'ביסלי', 'צ\'יפס', 'סוכריות',
      'גומי', 'פופקורן', 'בוטנים', 'אגוזים',
    ],
    ProductCategory.cleaning: [
      'סבון כלים', 'אקונומיקה', 'מנקה', 'כביסה', 'מרכך', 'שקיות אשפה',
      'נייר סופג', 'ספוג', 'אבקת כביסה',
    ],
    ProductCategory.toiletries: [
      'שמפו', 'סבון', 'משחת שיניים', 'דאודורנט', 'נייר טואלט',
      'מגבונים', 'טיטול', 'פד', 'קרם', 'מברשת שיניים',
    ],
  };

  /// מזהה את הקטגוריה המתאימה ביותר לשם מוצר נתון.
  /// אם אין התאמה לאף מילת מפתח, מוחזרת הקטגוריה "שונות".
  static ProductCategory categorize(String productName) {
    final normalized = productName.trim();
    if (normalized.isEmpty) return ProductCategory.other;

    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        if (normalized.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return ProductCategory.other;
  }
}

