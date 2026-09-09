/// פונקציות ולידציה לשימוש בטפסים (Login, Register, Add Product וכו').
/// כל פונקציה מחזירה null אם הקלט תקין, או הודעת שגיאה בעברית אם לא.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'יש להזין אימייל';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-\.]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'כתובת אימייל לא תקינה';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'יש להזין סיסמה';
    }
    if (value.length < 6) {
      return 'הסיסמה חייבת להכיל לפחות 6 תווים';
    }
    return null;
  }

  static String? requiredText(String? value, {String fieldName = 'שדה זה'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName הוא שדה חובה';
    }
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'יש להזין כמות';
    }
    final number = num.tryParse(value);
    if (number == null || number <= 0) {
      return 'יש להזין מספר חיובי';
    }
    return null;
  }
}
