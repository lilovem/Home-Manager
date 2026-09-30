import 'package:firebase_auth/firebase_auth.dart';
import '../core/errors/failures.dart';
import '../services/firebase/firebase_auth_service.dart';

/// השכבה שה-UI קורא לה בפועל להתחברות/הרשמה/יציאה.
///
/// אחראית לתרגם שגיאות טכניות של Firebase (קודי שגיאה באנגלית)
/// להודעות ברורות בעברית, דרך מחלקות ה-Failure שכבר הגדרנו ב-core/errors.
/// ה-UI לעולם לא מטפל ב-FirebaseAuthException ישירות.
class AuthRepository {
  final FirebaseAuthService _service;

  AuthRepository(this._service);

  Stream<User?> get authStateChanges => _service.authStateChanges;

  User? get currentUser => _service.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _service.signIn(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapErrorMessage(e.code));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _service.signUp(email: email, password: password);
      // שומרים את השם מיד אחרי יצירת החשבון - כך שמהרגע הראשון
      // הוא כבר מוצג בכל מקום (למשל "מי הוסיף" ברשימת קניות)
      // במקום האימייל.
      await _service.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapErrorMessage(e.code));
    }
  }

  /// מעדכן את השם המוצג של המשתמש המחובר - משמש גם למשתמשים
  /// ותיקים שנרשמו לפני שהתווספה האפשרות לשם, וגם לכל מי שירצה
  /// לשנות את השם שלו מאוחר יותר.
  Future<void> updateDisplayName(String name) async {
    try {
      await _service.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapErrorMessage(e.code));
    }
  }

  /// כניסה עם Google. אם המשתמש סוגר את חלון הבחירה בעצמו
  /// (התחרט) - זו לא "שגיאה" אמיתית, פשוט לא עושים כלום ולא
  /// מציגים הודעת שגיאה מבהילה (בדיוק כמו שלחיצה על "ביטול" לא
  /// אמורה להראות כשל).
  Future<void> signInWithGoogle() async {
    try {
      await _service.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        return;
      }
      throw AuthFailure(_mapErrorMessage(e.code));
    }
  }

  Future<void> signOut() => _service.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _service.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapErrorMessage(e.code));
    }
  }

  String _mapErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'לא נמצא משתמש עם אימייל זה';
      case 'wrong-password':
      case 'invalid-credential':
        return 'אימייל או סיסמה שגויים';
      case 'email-already-in-use':
        return 'כתובת האימייל כבר בשימוש';
      case 'invalid-email':
        return 'כתובת אימייל לא תקינה';
      case 'weak-password':
        return 'הסיסמה חלשה מדי - נדרשים לפחות 6 תווים';
      case 'too-many-requests':
        return 'יותר מדי ניסיונות. נסו שוב מאוחר יותר';
      case 'account-exists-with-different-credential':
        return 'כבר קיים חשבון עם אימייל זה, שנוצר בדרך אחרת (למשל אימייל+סיסמה). נסו להתחבר בדרך שבה נרשמתם במקור';
      case 'popup-blocked':
        return 'הדפדפן חסם את חלון ההתחברות של גוגל. אפשרו חלונות קופצים לאתר ונסו שוב';
      case 'unauthorized-domain':
        return 'הכתובת הזו לא מורשית להתחברות עם Google (צריך להוסיף אותה בהגדרות Firebase)';
      default:
        return 'שגיאה בהתחברות, נסו שוב';
    }
  }
}
