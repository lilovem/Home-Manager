import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';

/// כל הניתוב (routes) של האפליקציה מרוכז כאן.
///
/// בשלבים הבאים נוסיף כאן: '/login', '/register', '/create-household',
/// '/shopping-list/:listId' וכו'. כרגע יש רק את מסך ה-Splash
/// כדי שיהיה לנו משהו להריץ ולבדוק בסוף שלב 1.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
  ],
);
