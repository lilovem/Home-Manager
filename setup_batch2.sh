bash setup_batch2.sh#!/bin/bash
set -e
cat > 'lib/core/utils/date_formatter.dart' << 'HMEOF'
/// עיצוב תאריכים פשוט, בלי תלות באתחול locale של intl.
class DateFormatter {
  DateFormatter._();

  /// למשל: "09/09 14:30"
  static String short(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  /// למשל: "09/09/2026" - בלי שעה, לתאריכים שהשעה בהם לא רלוונטית
  /// (כמו התאריך המתוכנן של רשימת קניות).
  static String dateOnly(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

HMEOF
cat > 'lib/features/home/home_screen.dart' << 'HMEOF'
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
import 'home_module.dart';
import 'home_modules.dart';

/// מסך הבית הראשי - Dashboard.
///
/// מציג כרטיסיית household למעלה (שם, מספר חברים, הזמנה),
/// באנר הפעלת התראות (אם עדיין לא הוחלט/נחסם), ומתחתיה רשת
/// אריחים (grid) של כל מודולי האפליקציה - הפעילים (כרגע: רשימת
/// קניות) והעתידיים (מוצגים כ"בקרוב").
///
/// רשימת המודולים עצמה מגיעה מ-home_modules.dart - הוספת מודול
/// חדש בעתיד לא דורשת לגעת בקובץ הזה כלל.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

    final modules = buildHomeModules(householdId: household.id);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: AppStrings.inviteFriendToApp,
            onPressed: () => _showInviteFriendSheet(context, ref),
          ),
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                    const Icon(Icons.home_rounded, size: 40, color: Colors.white),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      AppStrings.appTagline,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
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
            if (_permissionStatus == 'granted')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () => ref.read(browserNotificationServiceProvider).show(
                              title: AppStrings.testNotificationTitle,
                              body: AppStrings.testNotificationBody,
                            ),
                        icon: const Icon(Icons.notifications_active_outlined, size: 18),
                        label: const Text(AppStrings.notificationsLabel),
                      ),
                      Tooltip(
                        message: AppStrings.notificationsInfoTooltip,
                        triggerMode: TooltipTriggerMode.tap,
                        showDuration: const Duration(seconds: 4),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
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
                Text(AppStrings.enableNotificationsTitle, style: AppTextStyles.heading2.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  isBlocked ? AppStrings.notificationsBlockedBody : AppStrings.enableNotificationsBody,
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

/// כרטיסיית household עליונה - שם, מספר חברים, כפתור הזמנה.
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
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
                          style: AppTextStyles.heading2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.unfold_more,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: onManageMembers,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$membersCount ${AppStrings.membersCount}',
                          style: AppTextStyles.bodySecondary,
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
            boxShadow: available
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
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
                        gradient: available
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primaryLight, Color(0xFFCDEBF7)],
                              )
                            : null,
                        color: available ? null : AppColors.surface,
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

HMEOF
cat > 'lib/features/shopping/existing_shopping_lists_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../providers/shopping_provider.dart';
import 'shopping_list_screen.dart';

/// מסך "קנייה נוכחית" - רשימת כל הקניות הקיימות של ה-household,
/// לבחירה. יצירת קנייה חדשה נעשית דרך המסך השני (NewShoppingCalendarScreen),
/// לא כאן.
class ExistingShoppingListsScreen extends ConsumerWidget {
  final String householdId;

  const ExistingShoppingListsScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(shoppingListsProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.currentShoppingOption)),
      body: listsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => const ErrorView(),
        data: (lists) {
          // מציגים רק רשימות שיש בהן בפועל לפחות מוצר אחד - רשימות
          // ריקות (למשל שאריות ישנות מבדיקות) לא מבלבלות את הבחירה.
          final nonEmptyLists = lists.where((list) {
            final itemsAsync = ref.watch(
              shoppingItemsProvider((householdId: householdId, listId: list.id)),
            );
            return (itemsAsync.value ?? const []).isNotEmpty;
          }).toList();

          if (nonEmptyLists.isEmpty) {
            return const EmptyState(
              message: AppStrings.noListsYet,
              icon: Icons.shopping_cart_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: nonEmptyLists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final list = nonEmptyLists[index];
              final isActive = list.activeSessionId != null;

              return ListTile(
                leading: Icon(
                  Icons.shopping_cart,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(list.name),
                subtitle: list.date != null
                    ? Text(DateFormatter.dateOnly(list.date), style: AppTextStyles.bodySecondary)
                    : null,
                trailing: isActive
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          AppStrings.activeSessionBadge,
                          style: TextStyle(color: AppColors.primary, fontSize: 11),
                        ),
                      )
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShoppingListScreen(householdId: householdId, listId: list.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

HMEOF
cat > 'lib/features/shopping/new_shopping_calendar_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/shopping_provider.dart';
import 'shopping_list_screen.dart';

/// מסך "קנייה חדשה" - לוח שנה אמיתי של החודש הנוכחי, בחירת תאריך
/// ואישור יוצרים רשימת קניות חדשה לתאריך שנבחר.
class NewShoppingCalendarScreen extends ConsumerStatefulWidget {
  final String householdId;

  const NewShoppingCalendarScreen({super.key, required this.householdId});

  @override
  ConsumerState<NewShoppingCalendarScreen> createState() =>
      _NewShoppingCalendarScreenState();
}

class _NewShoppingCalendarScreenState extends ConsumerState<NewShoppingCalendarScreen> {
  late final DateTime _month;
  DateTime? _selectedDate;
  bool _isLoading = false;

  static const List<String> _weekdayLabels = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  Future<void> _confirm() async {
    final date = _selectedDate;
    if (date == null) return;

    setState(() => _isLoading = true);

    try {
      final newList = await ref.read(shoppingRepositoryProvider).createList(
            householdId: widget.householdId,
            name: DateFormatter.dateOnly(date),
            date: date,
          );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ShoppingListScreen(
              householdId: widget.householdId,
              listId: newList.id,
            ),
          ),
        );
      }
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // יישור כך שראשון (Sunday) יהיה העמודה הראשונה: DateTime.weekday
    // מחזיר שני=1...ראשון=7, אז %7 הופך את ראשון ל-0.
    final leadingEmptyCells = _month.weekday % 7;
    final monthLabel = '${_month.month}/${_month.year}';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.newShoppingOption)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                AppStrings.selectDateForNewList,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(monthLabel, style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Row(
                children: _weekdayLabels
                    .map((label) => Expanded(
                          child: Center(
                            child: Text(
                              label,
                              style: AppTextStyles.bodySecondary.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: leadingEmptyCells + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < leadingEmptyCells) {
                      return const SizedBox.shrink();
                    }
                    final day = index - leadingEmptyCells + 1;
                    final date = DateTime(_month.year, _month.month, day);
                    final isSelected =
                        _selectedDate != null && _isSameDay(_selectedDate!, date);
                    final isToday = _isSameDay(date, DateTime.now());

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday && !isSelected
                              ? Border.all(color: AppColors.primary, width: 1.4)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: AppTextStyles.body.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedDate == null || _isLoading ? null : _confirm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(AppStrings.confirmDateButton, style: AppTextStyles.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

HMEOF
echo 'DONE - icon size, non-empty list filter, date-only display!'
