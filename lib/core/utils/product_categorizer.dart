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

