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
    // בודקים (אחרי הפריים הראשון, כדי שיהיה context תקין) אם למשתמש
    // המחובר יש שם שמור - אם לא (למשל משתמש ותיק שנרשם לפני שהתווספה
    // האפשרות הזו), מבקשים ממנו להכניס שם, חד פעמית.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDisplayName());
  }

  Future<void> _checkDisplayName() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    final name = user.displayName;
    if (name != null && name.trim().isNotEmpty) return;
    if (!mounted) return;
    await _showEnterNameDialog();
  }

  Future<void> _showEnterNameDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text(AppStrings.enterNameTitle),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: AppStrings.fullNameLabel),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? AppStrings.nameRequiredError : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => isSaving = true);
                      await ref
                          .read(authRepositoryProvider)
                          .updateDisplayName(controller.text.trim());
                      ref.invalidate(authStateChangesProvider);
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.saveNameButton),
            ),
          ],
        ),
      ),
    );
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
    final isCalendarTab = _selectedTab == 2;

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
          // "הפעלת התראות" יושבת בשורה העליונה, בצד ימין, ממש ליד
          // שיתוף/ניתוק (לפי בקשה מפורשת) - בלי כפתור נפרד בצד: כל
          // הטקסט "הפעלת התראות" עצמו הוא מה שלוחצים עליו. בלי צבע
          // קבוע (היה לבן על רקע בהיר - בלתי נראה) - צבע ברירת
          // המחדל של ה-AppBar, אותו צבע שבו שיתוף/ניתוק כבר מוצגים
          // וברורים לעין.
          if (!isCalendarTab && _permissionStatus != 'granted')
            _NotificationAppBarAction(
              isBlocked: _permissionStatus == 'denied',
              onEnable: _requestPermission,
            ),
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
            // חלק עליון קבוע - לא בתוך גלילה, נשאר גלוי בכל הטאבים
            // (חוץ מטאב "לוח שנה", ר' isCalendarTab למטה - שם רק
            // הלוגו נשאר, כדי שללוח השנה יהיה כמה שיותר מקום).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 38, color: Colors.white),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Text(
                        AppStrings.appName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedTab == 0) ...[
              // "לוח המודעות" הרץ - ממש מתחת ללוגו, לפי בקשה מפורשת.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: AnnouncementsTicker(householdId: household.id),
              ),
              // הברכה ("שלום, משפחת X!") ושם ה-household מוצגים עכשיו
              // יחד בשורה אחת בתוך הכרטיסייה עצמה (ר. _HouseholdCard),
              // במקום שורת ברכה נפרדת מעליה עם אותו שם פעמיים - גם
              // חוסך מקום אנכי בדף וגם פחות חזרתי.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
              const Divider(height: 1),
            ],
            // גוף המסך - משתנה לפי הטאב הנבחר. בטאב "לוח שנה" זה מקבל
            // כמעט את כל המסך (רק הלוגו למעלה, בלי שאר החלק הקבוע).
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

/// פעולת "הפעלת התראות" בשורה העליונה של ה-AppBar, יחד עם שיתוף
/// וניתוק - לפי בקשה מפורשת. אין כפתור נפרד בצד: כל הטקסט עצמו
/// לחיץ. כשהחסימה קבועה בדפדפן (isBlocked) אי אפשר לבקש הרשאה
/// שוב, אז מוצג רק אייקון לא-לחיץ עם טולטיפ שמסביר את זה.
class _NotificationAppBarAction extends StatelessWidget {
  final bool isBlocked;
  final VoidCallback onEnable;

  const _NotificationAppBarAction({required this.isBlocked, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    // בלי צבע קבוע (לא לבן, לא שחור) - משתמשים בצבע ברירת המחדל
    // שה-AppBar כבר נותן לאייקונים שלו (אותו צבע שבו שיתוף/ניתוק
    // כבר מוצגים וברורים לעין, לידו ממש).
    final defaultColor = IconTheme.of(context).color;
    if (isBlocked) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Tooltip(
          message: AppStrings.notificationsBlockedBody,
          child: Icon(Icons.notifications_off_outlined, color: defaultColor, size: 20),
        ),
      );
    }
    return TextButton.icon(
      onPressed: onEnable,
      style: TextButton.styleFrom(
        foregroundColor: defaultColor,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.notifications_active_outlined, size: 18),
      label: Text(
        AppStrings.enableNotificationsTitle,
        style: TextStyle(fontSize: 12, color: defaultColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// כרטיסיית household - שם, מספר חברים, כפתור הזמנה. עיצוב מחודש
/// ומודרני יותר: אייקון בעיגול גרדיאנט (תואם ללוגו), שם המשפחה
/// בולט יותר עם "צ'יפ" עגול ל"X חברים" (לחיץ בנפרד, פותח את רשימת
/// החברים), וצל רך יותר בגוון הצבע הראשי במקום צל אפור שטוח.
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onSwitchHousehold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${AppStrings.greetingPrefix} $name!',
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.unfold_more, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onManageMembers,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '$membersCount ${AppStrings.membersCount}',
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
