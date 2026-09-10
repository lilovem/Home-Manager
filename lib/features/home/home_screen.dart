import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../household/invite_partner_screen.dart';
import 'home_module.dart';
import 'home_modules.dart';

/// מסך הבית הראשי - Dashboard.
///
/// מציג כרטיסיית household למעלה (שם, מספר חברים, הזמנה),
/// ומתחתיה רשת אריחים (grid) של כל מודולי האפליקציה - הפעילים
/// (כרגע: רשימת קניות) והעתידיים (מוצגים כ"בקרוב").
///
/// רשימת המודולים עצמה מגיעה מ-home_modules.dart - הוספת מודול
/// חדש בעתיד לא דורשת לגעת בקובץ הזה כלל.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(myHouseholdProvider).value;

    if (household == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final modules = buildHomeModules(householdId: household.id);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.signOut,
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _HouseholdCard(
                name: household.name,
                membersCount: household.memberIds.length,
                onInvite: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InvitePartnerScreen(
                      householdId: household.id,
                      householdName: household.name,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemCount: modules.length,
                itemBuilder: (context, index) => _ModuleTile(module: modules[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// כרטיסיית household עליונה - שם, מספר חברים, כפתור הזמנה.
class _HouseholdCard extends StatelessWidget {
  final String name;
  final int membersCount;
  final VoidCallback onInvite;

  const _HouseholdCard({
    required this.name,
    required this.membersCount,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.heading2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$membersCount ${AppStrings.membersCount}',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onInvite,
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
            tooltip: AppStrings.invitePartner,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

/// אריח מודול בודד ברשת. פעיל -> לחיץ ופותח את המסך שלו.
/// לא פעיל -> מעומעם, עם תווית "בקרוב", לא מגיב ללחיצה.
class _ModuleTile extends StatelessWidget {
  final HomeModule module;

  const _ModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    final bool available = module.isAvailable && module.screenBuilder != null;

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: available
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: module.screenBuilder!),
                )
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Opacity(
            opacity: available ? 1 : 0.5,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: available ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        module.icon,
                        color: available ? AppColors.primary : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      module.title,
                      style: AppTextStyles.heading2.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      module.subtitle,
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (!available)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        AppStrings.comingSoon,
                        style: AppTextStyles.bodySecondary.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

