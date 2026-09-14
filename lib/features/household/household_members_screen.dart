import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../models/household_member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';

/// מסך ניהול חברי household - מציג את כל החברים ומאפשר להסיר מישהו.
/// כל חבר יכול להסיר כל חבר אחר (כולל את "הבעלים") - זו פשטות
/// מכוונת עבור household משפחתי קטן, לא היררכיית הרשאות מורכבת.
/// אי אפשר להסיר את עצמך מהמסך הזה (אין עדיין פיצ'ר "עזיבת household").
///
/// מחיקת household בשלמותו כן מוגבלת רק לבעלים (isOwner) - זו פעולה
/// הרסנית יותר (מוחקת גם רשימות/היסטוריה), לכן ההגבלה מחמירה יותר.
class HouseholdMembersScreen extends ConsumerWidget {
  final String householdId;
  final bool isOwner;

  const HouseholdMembersScreen({
    super.key,
    required this.householdId,
    this.isOwner = false,
  });

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    HouseholdMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.confirmRemoveMemberTitle),
        content: Text('${member.email}\n${AppStrings.confirmRemoveMemberMessage}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(householdRepositoryProvider).removeMember(
            householdId: householdId,
            memberUid: member.uid,
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDeleteHousehold(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.confirmDeleteHouseholdTitle),
        content: const Text(AppStrings.confirmDeleteHouseholdMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.deleteHousehold, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(householdRepositoryProvider).deleteHousehold(householdId);
      // ה-household נעלם אוטומטית מ-myHouseholdsProvider; חוזרים
      // למסך הבית (currentHouseholdProvider יבחר household אחר או
      // יעביר למסך יצירה/הצטרפות אם לא נשאר אף אחד).
      if (context.mounted) Navigator.of(context).pop();
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(householdMembersProvider(householdId));
    final myUid = ref.watch(authStateChangesProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.manageMembers)),
      body: Column(
        children: [
          Expanded(
            child: membersAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, st) => const ErrorView(),
              data: (members) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isMe = member.uid == myUid;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(
                          member.role == 'owner' ? Icons.star : Icons.person,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(member.email, textDirection: TextDirection.ltr),
                      subtitle: Text(
                        member.role == 'owner' ? AppStrings.ownerLabel : AppStrings.memberLabel,
                        style: AppTextStyles.bodySecondary,
                      ),
                      trailing: isMe
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.person_remove_outlined, color: AppColors.error),
                              tooltip: AppStrings.removeMember,
                              onPressed: () => _confirmRemove(context, ref, member),
                            ),
                    );
                  },
                );
              },
            ),
          ),
          if (isOwner)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _confirmDeleteHousehold(context, ref),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text(
                  AppStrings.deleteHousehold,
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

