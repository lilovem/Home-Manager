import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/error_view.dart';
import '../features/home/main_shell_screen.dart';
import '../features/household/create_household_screen.dart';
import '../features/shopping/shopping_notifications_listener.dart';
import '../features/splash/splash_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/household_provider.dart';

/// "שומר" שני, שרץ אחרי AuthGate (כלומר המשתמש כבר מחובר).
///
/// מאזין לכל ה-households של המשתמש הנוכחי (תומך בכמה households,
/// לא רק אחד) ומציג את המסך המתאים:
/// - עדיין בודק → Splash
/// - אין אף household → מסך יצירה/הצטרפות
/// - יש לפחות household אחד → מסך הבית עבור ה-household הנוכחי
///   (currentHouseholdProvider), עטוף ב-ShoppingNotificationsListener
///   כדי שההאזנה להתראות תפעל בכל מסך באפליקציה.
///
/// גם "מתקן" ברקע את שדה ה-email על מסמך החברות של המשתמש הנוכחי
/// בכל household שהוא חבר בו (למקרה שהוא חסר - households ישנים).
class HouseholdGate extends ConsumerWidget {
  const HouseholdGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdsState = ref.watch(myHouseholdsProvider);

    return householdsState.when(
      loading: () => const SplashScreen(),
      error: (error, stack) => const Scaffold(
        body: ErrorView(message: 'שגיאה בטעינת משק הבית'),
      ),
      data: (households) {
        if (households.isEmpty) {
          return const CreateOrJoinHouseholdScreen();
        }

        final current = ref.watch(currentHouseholdProvider);
        if (current == null) {
          // מצב ביניים רגעי (הרשימה עדיין לא "התייצבה") - Splash קצר.
          return const SplashScreen();
        }

        final user = ref.read(authStateChangesProvider).value;
        if (user != null) {
          for (final household in households) {
            ref.read(householdRepositoryProvider).ensureMemberEmail(
                  householdId: household.id,
                  uid: user.uid,
                  email: user.email ?? '',
                );
          }
        }

        return ShoppingNotificationsListener(
          householdId: current.id,
          child: const MainShellScreen(),
        );
      },
    );
  }
}

