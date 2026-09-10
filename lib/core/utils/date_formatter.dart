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
}

