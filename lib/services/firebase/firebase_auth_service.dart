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

  Future<void> signOut() => _auth.signOut();
}

