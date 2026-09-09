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

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _service.signUp(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapErrorMessage(e.code));
    }
  }

  Future<void> signOut() => _service.signOut();

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
      default:
        return 'שגיאה בהתחברות, נסו שוב';
    }
  }
}

