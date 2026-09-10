import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/error_view.dart';
import '../features/auth/login_screen.dart';
import '../features/splash/splash_screen.dart';
import '../providers/auth_provider.dart';
import 'household_gate.dart';

/// "השומר" הראשון של האפליקציה.
///
/// מאזין למצב ההתחברות (authStateChangesProvider) ומציג אוטומטית
/// את המסך המתאים:
/// - עדיין בודק (loading) → Splash
/// - לא מחובר (null) → Login
/// - מחובר (User) → HouseholdGate (שבודק אם יש לו household)
///
/// כך שכל שינוי במצב ההתחברות (login/register/signOut) מתעדכן
/// אוטומטית בכל האפליקציה, בלי ניווט ידני.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (error, stack) => const Scaffold(
        body: ErrorView(message: 'שגיאה בבדיקת מצב ההתחברות'),
      ),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        return const HouseholdGate();
      },
    );
  }
}

