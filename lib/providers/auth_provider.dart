import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../services/firebase/firebase_auth_service.dart';

/// מספק גישה ל-instance היחיד של FirebaseAuth באפליקציה.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// שכבת ה-Service.
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(ref.watch(firebaseAuthProvider));
});

/// שכבת ה-Repository - זו ש-UI אמור להשתמש בה בפועל.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authServiceProvider));
});

/// Stream של מצב ההתחברות הנוכחי.
/// null = לא מחובר, User = מחובר.
///
/// זהו ה-provider המרכזי ש-AuthGate מאזין לו כדי להחליט
/// איזה מסך להציג (Login / Home).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

