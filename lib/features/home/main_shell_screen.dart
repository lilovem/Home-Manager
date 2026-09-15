import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_config.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/share_provider.dart';
import '../household/add_household_screen.dart';
import '../household/household_members_screen.dart';
import '../household/invite_partner_screen.dart';
import 'home_modules.dart';
import 'tabs/calendar_tab_content.dart';
import 'tabs/home_tab_content.dart';
import 'tabs/more_tab_content.dart';
import 'tabs/shopping_tab_content.dart';
import 'tabs/tasks_tab_content.dart';

/// המסך הראשי של האפליקציה - "שלד" (shell) קבוע.
///
/// מבנה:
/// - חלק עליון קבוע (לא משתנה בין טאבים): לוגו, ברכה, כרטיסיית
///   household (הזמנה/החלפה/חברים), באנר התראות אם צריך.
/// - סרגל ניווט תחתון קבוע עם 5 טאבים: בית | קניות | לוח שנה |
///   משימות | עוד. הטאב הפעיל תמיד מודגש עם השם שלו.
/// - גוף המסך מתחלף לפי הטאב הנבחר - כל טאב מוטמע ישירות (לא
///   נפתח כמסך נפרד), כדי שהחלק העליון הקבוע יישאר גלוי תמיד.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _selectedTab = 0;
  late String _permissionStatus;

  @override
  void initState() {
    super.initState();
    _permissionStatus = ref.read(browserNotificationServiceProvider).permissionStatus;
  }

  Future<void> _requestPermission() async {
    await ref.read(browserNotificationServiceProvider).requestPermission();
    setState(() {
      _permissionStatus = ref.read(browserNotificationServiceProvider).permissionStatus;
    });
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.confirmSignOutTitle),
        content: const Text(AppStrings.confirmSignOutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.signOut, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  void _showInviteFriendSheet(BuildContext context, WidgetRef ref) {
    final message = 'בוא תנסה את ${AppStrings.appName} - אפליקציה לניהול משק הבית! 🏠\n'
        '${AppConfig.publicUrl}';

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.inviteFriendToApp, style: AppTextStyles.heading2),
              const SizedBox(height: 4),
              const Text(AppStrings.inviteFriendBody, style: AppTextStyles.bodySecondary),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                title: const Text(AppStrings.shareViaWhatsApp),
                onTap: () {
                  ref.read(shareServiceProvider).shareViaWhatsApp(message);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: const Text(AppStrings.shareViaEmail),
                onTap: () {
                  ref.read(shareServiceProvider).shareViaEmail(
                        subject: AppStrings.inviteFriendToApp,
                        body: message,
                      );
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHouseholdSwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Consumer(
          builder: (consumerContext, sheetRef, _) {
            final households = sheetRef.watch(myHouseholdsProvider).value ?? [];
            final currentId = sheetRef.watch(currentHouseholdProvider)?.id;

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(AppStrings.myHouseholds, style: AppTextStyles.heading2),
                  ),
                  ...households.map(
                    (household) => ListTile(
                      leading: Icon(
                        household.id == currentId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: AppColors.primary,
                      ),
                      title: Text(household.name),
                      onTap: () {
                        sheetRef.read(selectedHouseholdIdProvider.notifier).state =
                            household.id;
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add, color: AppColors.primary),
                    title: const Text(AppStrings.addAnotherHousehold),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddHouseholdScreen()),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider);

    if (household == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final featured = buildFeaturedModules(householdId: household.id);
    final restModules = buildHomeModules(householdId: household.id);

    final Widget body;
    switch (_selectedTab) {
      case 1:
        body = ShoppingTabContent(householdId: household.id);
        break;
      case 2:
        body = CalendarTabContent(householdId: household.id);
        break;
      case 3:
        body = const TasksTabContent();
        break;
      case 4:
        body = MoreTabContent(modules: restModules);
        break;
      default:
        body = HomeTabContent(
          householdId: household.id,
          tiles: featured,
          onSelectTab: (i) => setState(() => _selectedTab = i),
        );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: _permissionStatus == 'granted'
            ? IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: AppStrings.notificationsInfoTooltip,
                onPressed: () => ref.read(browserNotificationServiceProvider).show(
                      title: AppStrings.testNotificationTitle,
                      body: AppStrings.testNotificationBody,
                    ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: AppStrings.inviteFriendToApp,
            onPressed: () => _showInviteFriendSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.signOut,
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // חלק עליון קבוע - לא בתוך גלילה, נשאר גלוי בכל הטאבים.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 30, color: Colors.white),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Text(
                        AppStrings.appName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('${AppStrings.greetingPrefix} ${household.name}!',
                  style: AppTextStyles.heading2.copyWith(fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                onManageMembers: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HouseholdMembersScreen(
                      householdId: household.id,
                      isOwner: household.createdBy ==
                          ref.read(authStateChangesProvider).value?.uid,
                    ),
                  ),
                ),
                onSwitchHousehold: () => _showHouseholdSwitcher(context, ref),
              ),
            ),
            if (_permissionStatus == 'default' || _permissionStatus == 'denied')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _NotificationBanner(
                  isBlocked: _permissionStatus == 'denied',
                  onEnable: _requestPermission,
                ),
              ),
            const Divider(height: 1),
            // גוף המסך - משתנה לפי הטאב הנבחר.
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: AppStrings.tabHome),
          NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined), label: AppStrings.tabShopping),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), label: AppStrings.tabCalendar),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: AppStrings.tabTasks),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: AppStrings.tabMore),
        ],
      ),
    );
  }
}

/// באנר שמזמין להפעיל התראות, או מסביר איך לתקן אם נחסמו.
class _NotificationBanner extends StatelessWidget {
  final bool isBlocked;
  final VoidCallback onEnable;

  const _NotificationBanner({required this.isBlocked, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBlocked ? AppColors.surface : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: isBlocked ? Border.all(color: AppColors.divider) : null,
      ),
      child: Row(
        children: [
          Icon(
            isBlocked ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
            color: isBlocked ? AppColors.textSecondary : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.enableNotificationsTitle,
                    style: AppTextStyles.heading2.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  isBlocked
                      ? AppStrings.notificationsBlockedBody
                      : AppStrings.enableNotificationsBody,
                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isBlocked)
            TextButton(
              onPressed: onEnable,
              child: const Text(AppStrings.enableNotificationsButton),
            ),
        ],
      ),
    );
  }
}

/// כרטיסיית household - שם, מספר חברים, כפתור הזמנה.
class _HouseholdCard extends StatelessWidget {
  final String name;
  final int membersCount;
  final VoidCallback onInvite;
  final VoidCallback onManageMembers;
  final VoidCallback onSwitchHousehold;

  const _HouseholdCard({
    required this.name,
    required this.membersCount,
    required this.onInvite,
    required this.onManageMembers,
    required this.onSwitchHousehold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onSwitchHousehold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppTextStyles.heading2.copyWith(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.unfold_more, size: 15, color: AppColors.textSecondary),
                    ],
                  ),
                  InkWell(
                    onTap: onManageMembers,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$membersCount ${AppStrings.membersCount}',
                          style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onInvite,
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 20),
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

