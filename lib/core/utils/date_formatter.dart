/// עיצוב תאריכים פשוט, בלי תלות באתחול locale של intl.
class DateFormatter {
  DateFormatter._();

  /// למשל: "09/09 14:30"
  static String short(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  /// למשל: "09/09/2026" - בלי שעה, לתאריכים שהשעה בהם לא רלוונטית
  /// (כמו התאריך המתוכנן של רשימת קניות).
  static String dateOnly(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

