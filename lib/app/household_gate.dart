import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/error_view.dart';
import '../features/home/home_screen.dart';
import '../features/household/create_household_screen.dart';
import '../features/splash/splash_screen.dart';
import '../providers/household_provider.dart';

/// "שומר" שני, שרץ אחרי AuthGate (כלומר המשתמש כבר מחובר).
///
/// מאזין ל-household של המשתמש הנוכחי ומציג את המסך המתאים:
/// - עדיין בודק → Splash
/// - אין household → מסך יצירה/הצטרפות
/// - יש household → מסך הבית
class HouseholdGate extends ConsumerWidget {
  const HouseholdGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdState = ref.watch(myHouseholdProvider);

    return householdState.when(
      loading: () => const SplashScreen(),
      error: (error, stack) => const Scaffold(
        body: ErrorView(message: 'שגיאה בטעינת משק הבית'),
      ),
      data: (household) {
        if (household == null) {
          return const CreateOrJoinHouseholdScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

