import 'package:firebase_auth/firebase_auth.dart';

/// עטיפה דקה סביב FirebaseAuth.
///
/// זו שכבת ה-Service - היא רק "מדברת" עם Firebase, לא מכילה
/// שום לוגיקה עסקית ולא יודעת כלום על הודעות שגיאה בעברית.
/// זה תפקידו של ה-Repository (השכבה שמעליה).
class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// כניסה עם חשבון Google - דרך firebase_auth ישירות, בלי חבילת
  /// google_sign_in נפרדת. ב-Flutter Web, firebase_auth כבר יודע
  /// לפתוח את חלון הבחירה של גוגל בעצמו (signInWithPopup) - זה
  /// עובד רק בווב (האפליקציה הזו היא web-only, אז זה מתאים בדיוק).
  /// אם נרצה בעתיד גם אפליקציית מובייל, זה ידרוש את חבילת
  /// google_sign_in בנוסף - לא נדרש כרגע.
  Future<UserCredential> signInWithGoogle() {
    final googleProvider = GoogleAuthProvider();
    return _auth.signInWithPopup(googleProvider);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// מעדכן את השם המוצג של המשתמש המחובר (נשמר בפרופיל של
  /// Firebase Auth עצמו - אין צורך במסמך נפרד ב-Firestore).
  /// reload() בסוף מוודא ש-currentUser בזיכרון מתעדכן מיידית עם
  /// השם החדש, כדי שכל מקום שקורא אותו (למשל הוספת מוצר לרשימת
  /// קניות) יראה אותו כבר מהפעולה הבאה.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await user.reload();
  }
}
