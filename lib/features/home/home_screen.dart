import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../household/invite_partner_screen.dart';

/// מסך הבית הראשי - מוצג רק כשלמשתמש יש household.
/// בשלב זה עדיין placeholder יחסית, אבל כבר מציג מידע אמיתי
/// (שם ה-household, מספר חברים) ומאפשר להזמין בן/בת זוג.
/// בשלבים הבאים (Shopping List) זה יהפוך למסך המרכזי האמיתי.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(myHouseholdProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(household?.name ?? AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.signOut,
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(household?.name ?? '', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.membersCount}: ${household?.memberIds.length ?? 0}',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.group_add),
              label: const Text(AppStrings.invitePartner),
              onPressed: household == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InvitePartnerScreen(
                            householdId: household.id,
                            householdName: household.name,
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

