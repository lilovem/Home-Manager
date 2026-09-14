import 'package:go_router/go_router.dart';
import '../features/auth/register_screen.dart';
import 'auth_gate.dart';

/// כל הניתוב (routes) של האפליקציה מרוכז כאן.
///
/// המסך הראשי ('/') הוא AuthGate - הוא זה שמחליט אם להציג
/// Login או Home, לפי מצב ההתחברות. '/register' הוא מסך נפרד
/// שנפתח (push) מעל מסך ה-Login.
///
/// בשלבים הבאים נוסיף כאן routes נוספים כמו
/// '/create-household', '/shopping-list/:listId' וכו'.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'root',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);

