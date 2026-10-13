// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'product_categorizer.dart';

/// שמירת סדר הקטגוריות המותאם אישית ברשימת הקניות - לכל סופר יש סדר
/// מדפים משלו, אז אפשר להזיז קטגוריה למעלה/למטה והסדר נשמר.
///
/// נשמר בזיכרון הדפדפן (localStorage) לפי household - כלומר על המכשיר/
/// דפדפן הזה, לא מסתנכרן בין בני הבית. אם הזיכרון ריק או לא זמין,
/// חוזרים לסדר ברירת המחדל (ProductCategorizer.displayOrder).
class CategoryOrderStore {
  CategoryOrderStore._();

  static String _key(String householdId) => 'category_order_$householdId';

  /// הסדר השמור (אם יש), כשקטגוריות חדשות שלא נשמרו מצורפות בסוף לפי
  /// סדר ברירת המחדל - כך שהוספת קטגוריה בגרסה עתידית לא תשבור כלום.
  static List<ProductCategory> load(String householdId) {
    final defaults = ProductCategorizer.displayOrder;
    try {
      final raw = html.window.localStorage[_key(householdId)];
      if (raw == null || raw.isEmpty) return List.of(defaults);

      final result = <ProductCategory>[];
      for (final name in raw.split(',')) {
        for (final category in ProductCategory.values) {
          if (category.name == name && !result.contains(category)) {
            result.add(category);
          }
        }
      }
      for (final category in defaults) {
        if (!result.contains(category)) result.add(category);
      }
      return result;
    } catch (_) {
      return List.of(defaults);
    }
  }

  static void save(String householdId, List<ProductCategory> order) {
    try {
      html.window.localStorage[_key(householdId)] =
          order.map((c) => c.name).join(',');
    } catch (_) {
      // אחסון חסום (למשל גלישה פרטית) - הסדר פשוט לא יישמר, בלי לשבור.
    }
  }
}
