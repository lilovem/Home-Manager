/// מחלקת בסיס לכל השגיאות באפליקציה.
///
/// המטרה: כל שגיאה שמגיעה מ-Repository תהיה מסוג Failure ידוע,
/// כך שה-UI תמיד יודע איך להציג אותה למשתמש (בלי try/catch
/// גנרי בכל מסך שתופס Exception לא צפוי).
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// שגיאת רשת / חוסר חיבור לאינטרנט
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'אין חיבור לאינטרנט']);
}

/// שגיאת הרשאה (המשתמש לא חבר ב-household, וכו')
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'אין לך הרשאה לבצע פעולה זו']);
}

/// שגיאת אימות (Auth) - התחברות/הרשמה נכשלה
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// שגיאה כללית שלא סווגה
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'משהו השתבש, נסו שוב']);
}
