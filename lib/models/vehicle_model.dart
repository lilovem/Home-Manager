import 'package:cloud_firestore/cloud_firestore.dart';

/// רכב בודד ששייך ל-household. אפשר שיהיו כמה רכבים לאותו household -
/// כל רכב מקבל מסמך נפרד תחת households/{id}/vehicles/{vehicleId},
/// כך שיש הפרדה מלאה בין הרכבים (קילומטראז', רישיון, ביטוחים,
/// טיפולים - הכל פר-רכב, בלי שום ערבוב).
class Vehicle {
  final String id;
  final String manufacturer;
  final String model;
  final int? year;
  final String licensePlate;
  final int currentMileage;
  final DateTime? licenseExpiryDate;
  final DateTime? mandatoryInsuranceExpiryDate;
  final DateTime? comprehensiveInsuranceExpiryDate;

  /// מרווחי הטיפולים (בק"מ) לרכב הזה - מתחיל מברירות מחדל גנריות
  /// (ראה kDefaultMaintenanceIntervals), אבל ניתן לעריכה פר-רכב אם
  /// למשתמש יש נתונים מדויקים יותר מספר הרכב שלו.
  final Map<String, int> maintenanceIntervals;

  /// תמונה אמיתית של הרכב שהמשתמש העלה (Data URL - base64 מכווץ),
  /// לתצוגה במקום האייקון הגנרי. נשמר ישירות במסמך הרכב ב-Firestore
  /// (בלי Firebase Storage בתשלום) - ראה vehicle_photo_picker.dart.
  final String? photoDataUrl;

  final DateTime? createdAt;

  const Vehicle({
    required this.id,
    required this.manufacturer,
    required this.model,
    this.year,
    required this.licensePlate,
    required this.currentMileage,
    this.licenseExpiryDate,
    this.mandatoryInsuranceExpiryDate,
    this.comprehensiveInsuranceExpiryDate,
    required this.maintenanceIntervals,
    this.photoDataUrl,
    required this.createdAt,
  });

  String get displayName => '$manufacturer $model';

  factory Vehicle.fromFirestore(String id, Map<String, dynamic> data) {
    final rawIntervals = data['maintenanceIntervals'] as Map<String, dynamic>?;
    return Vehicle(
      id: id,
      manufacturer: data['manufacturer'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: data['year'] as int?,
      licensePlate: data['licensePlate'] as String? ?? '',
      currentMileage: (data['currentMileage'] as num?)?.toInt() ?? 0,
      licenseExpiryDate: (data['licenseExpiryDate'] as Timestamp?)?.toDate(),
      mandatoryInsuranceExpiryDate:
          (data['mandatoryInsuranceExpiryDate'] as Timestamp?)?.toDate(),
      comprehensiveInsuranceExpiryDate:
          (data['comprehensiveInsuranceExpiryDate'] as Timestamp?)?.toDate(),
      maintenanceIntervals: rawIntervals != null
          ? rawIntervals.map((key, value) => MapEntry(key, (value as num).toInt()))
          : Map<String, int>.from(kDefaultMaintenanceIntervals),
      photoDataUrl: data['photoDataUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required String manufacturer,
    required String model,
    int? year,
    required String licensePlate,
    required int currentMileage,
    DateTime? licenseExpiryDate,
    DateTime? mandatoryInsuranceExpiryDate,
    DateTime? comprehensiveInsuranceExpiryDate,
  }) {
    return {
      'manufacturer': manufacturer,
      'model': model,
      if (year != null) 'year': year,
      'licensePlate': licensePlate,
      'currentMileage': currentMileage,
      'licenseExpiryDate':
          licenseExpiryDate != null ? Timestamp.fromDate(licenseExpiryDate) : null,
      'mandatoryInsuranceExpiryDate': mandatoryInsuranceExpiryDate != null
          ? Timestamp.fromDate(mandatoryInsuranceExpiryDate)
          : null,
      'comprehensiveInsuranceExpiryDate': comprehensiveInsuranceExpiryDate != null
          ? Timestamp.fromDate(comprehensiveInsuranceExpiryDate)
          : null,
      'maintenanceIntervals': kDefaultMaintenanceIntervals,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestoreForUpdate({
    String? manufacturer,
    String? model,
    int? year,
    String? licensePlate,
    DateTime? licenseExpiryDate,
    DateTime? mandatoryInsuranceExpiryDate,
    DateTime? comprehensiveInsuranceExpiryDate,
  }) {
    return {
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (licensePlate != null) 'licensePlate': licensePlate,
      'licenseExpiryDate':
          licenseExpiryDate != null ? Timestamp.fromDate(licenseExpiryDate) : null,
      'mandatoryInsuranceExpiryDate': mandatoryInsuranceExpiryDate != null
          ? Timestamp.fromDate(mandatoryInsuranceExpiryDate)
          : null,
      'comprehensiveInsuranceExpiryDate': comprehensiveInsuranceExpiryDate != null
          ? Timestamp.fromDate(comprehensiveInsuranceExpiryDate)
          : null,
    };
  }
}

/// מפתח קבוע -> (שם תצוגה, מרווח ק"מ ברירת מחדל). המרווחים מבוססים
/// על נהוג כללי בתעשייה - לא מדויק לכל יצרן/דגם ספציפי (אין מאגר
/// חינמי כזה), אבל נקודת פתיחה סבירה שאפשר לערוך פר-רכב.
const Map<String, int> kDefaultMaintenanceIntervals = {
  'oilChange': 10000,
  'majorService': 20000,
  'tires': 40000,
  'battery': 50000,
  'brakes': 20000,
};

const Map<String, String> kMaintenanceTemplateNames = {
  'oilChange': 'טיפול קטן (שמן ומסנן)',
  'majorService': 'טיפול גדול',
  'tires': 'החלפת צמיגים',
  'battery': 'החלפת מצבר',
  'brakes': 'בדיקת בלמים',
};

/// הסבר קצר לכל סוג טיפול - מוצג בלחיצה על אייקון ה"מידע" ליד כל
/// סוג טיפול במסך פרטי הרכב, כדי שמשתמש שלא בטוח מה זה בדיוק
/// יידע למה לצפות.
const Map<String, String> kMaintenanceTemplateDescriptions = {
  'oilChange':
      'החלפת שמן מנוע ומסנן שמן. לרוב כולל גם בדיקת נוזלים כלליים (בלמים, קירור, שמשות) ולחץ אוויר בצמיגים.',
  'majorService':
      'טיפול מקיף יותר - כולל את הטיפול הקטן, ובנוסף החלפת מסנני אוויר/דלק/מזגן, ובדיקה כללית של מערכות הרכב (בלמים, היגוי, מתלים).',
  'tires': 'בדיקת מצב הצמיגים והחלפתם כשהסימון (חריצים) נשחק או שיש נזק גלוי.',
  'battery':
      'בדיקת תפוקת המצבר והחלפתו כשהוא מתקשה להתניע את הרכב או שאורך חייו הסתיים (בדרך כלל 3-5 שנים).',
  'brakes':
      'בדיקת מצב רפידות ודיסקיות הבלמים, ולעיתים החלפתן כשהן נשחקות מתחת לעובי הבטיחותי.',
};

/// סוגי הטיפולים שנכנסים למעקב האוטומטי (חישוב "כמה ק"מ נשארו עד
/// הטיפול הבא") במסך פרטי הרכב. "החלפת צמיגים" הוצאה מכאן - היא לא
/// מתבצעת לפי מרווח ק"מ קבוע כמו שאר הטיפולים, אבל עדיין אפשר
/// לתעד אותה בהיסטוריה (מופיעה כאן, ב-kMaintenanceTemplateNames,
/// בבחירת סוג הטיפול במסך "הוסף תיעוד טיפול").
const List<String> kTrackedMaintenanceKeys = [
  'oilChange',
  'majorService',
  'battery',
  'brakes',
];

/// שמות החודשים בעברית - לתצוגת תאריך "יפה" (למשל "23 בספטמבר 2026")
/// בלי שעה, בשונה מ-DateFormatter.short הכללי שמיועד לתאריכים עם
/// שעה (כמו רשומות פעילות). בשימוש בבחירת "תאריכים חשובים" של הרכב
/// (רישיון/ביטוחים) ובתאריך ביצוע טיפול.
const List<String> _kHebrewMonthNames = [
  'ינואר',
  'פברואר',
  'מרץ',
  'אפריל',
  'מאי',
  'יוני',
  'יולי',
  'אוגוסט',
  'ספטמבר',
  'אוקטובר',
  'נובמבר',
  'דצמבר',
];

String formatPrettyDateHe(DateTime date) {
  final month = _kHebrewMonthNames[date.month - 1];
  return '${date.day} ב$month ${date.year}';
}
