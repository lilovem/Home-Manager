#!/bin/bash
set -e
cat > 'lib/app/config/app_strings.dart' << 'HMEOF'
/// טקסטים מרכזיים בממשק.
///
/// בשלב זה כל הטקסטים בעברית קשיחים כאן (לא בתוך ה-widgets עצמם).
/// זה מכין את הקרקע להוספת תמיכה רב-לשונית (i18n) בעתיד בלי
/// לשכתב מסכים - רק להחליף את המקור של המחלקה הזו.
class AppStrings {
  AppStrings._();

  // כללי
  static const String appName = 'LeeHome';
  static const String appTagline = 'ניהול הבית שלכם';
  static const String loading = 'טוען...';
  static const String errorGeneric = 'משהו השתבש. נסו שוב.';
  static const String retry = 'נסה שוב';

  // Auth
  static const String login = 'התחברות';
  static const String register = 'הרשמה';
  static const String email = 'אימייל';
  static const String password = 'סיסמה';
  static const String confirmPassword = 'אימות סיסמה';
  static const String dontHaveAccount = 'אין לך חשבון? הירשם';
  static const String alreadyHaveAccount = 'יש לך כבר חשבון? התחבר';
  static const String createAccount = 'יצירת חשבון';
  static const String signOut = 'התנתקות';
  static const String passwordsDontMatch = 'הסיסמאות אינן תואמות';
  static const String loggedInAs = 'מחובר/ת בתור';
  static const String forgotPassword = 'שכחת סיסמה?';
  static const String resetPasswordTitle = 'איפוס סיסמה';
  static const String resetPasswordBody = 'נשלח אליך קישור לאיפוס הסיסמה בכתובת האימייל שלך';
  static const String sendResetLink = 'שלח קישור';
  static const String resetLinkSent = 'קישור לאיפוס סיסמה נשלח לאימייל שלך';

  // Household
  static const String createHousehold = 'יצירת משק בית';
  static const String householdName = 'שם משק הבית';
  static const String invitePartner = 'הזמנת בן/בת זוג';
  static const String joinHousehold = 'הצטרפות למשק בית קיים';
  static const String inviteCode = 'קוד הזמנה';
  static const String noHouseholdYet = 'עדיין אין לך משק בית';
  static const String createNewHousehold = 'צור משק בית חדש';
  static const String haveInviteCode = 'יש לי קוד הזמנה';
  static const String joinButton = 'הצטרף';
  static const String copyCode = 'העתק קוד';
  static const String codeCopied = 'הקוד הועתק!';
  static const String shareThisCode = 'שתפו את הקוד הזה עם בן/בת הזוג';
  static const String shareViaWhatsApp = 'שתף בוואטסאפ';
  static const String shareViaEmail = 'שלח במייל';
  static const String inviteMessageTitle = 'הזמנה ל-LeeHome';
  static const String inviteFriendToApp = 'הזמן חבר לאפליקציה';
  static const String inviteFriendBody = 'שתפו איתם את הקישור, והם יוכלו להירשם וליצור משק בית משלהם';
  static const String membersCount = 'חברים במשק הבית';
  static const String comingSoon = 'בקרוב';
  static const String manageMembers = 'ניהול חברים';
  static const String removeMember = 'הסר מהמשק בית';
  static const String confirmRemoveMemberTitle = 'להסיר את החבר?';
  static const String confirmRemoveMemberMessage = 'הם לא יראו יותר את הרשימה ואת פרטי משק הבית';
  static const String ownerLabel = 'בעלים';
  static const String memberLabel = 'חבר';
  static const String addAnotherHousehold = 'הצטרפ/י או צור/י משק בית נוסף';
  static const String myHouseholds = 'משקי הבית שלי';
  static const String switchHousehold = 'החלף משק בית';
  static const String deleteHousehold = 'מחק משק בית';
  static const String confirmDeleteHouseholdTitle = 'למחוק את משק הבית?';
  static const String confirmDeleteHouseholdMessage =
      'פעולה זו תמחק לצמיתות את הרשימה, ההיסטוריה וכל החברים. לא ניתן לבטל.';

  // Shopping
  static const String shoppingList = 'רשימת קניות';
  static const String addProduct = 'הוספת מוצר';
  static const String editProduct = 'עריכת מוצר';
  static const String productName = 'שם המוצר';
  static const String quantity = 'כמות';
  static const String unit = 'יחידת מידה (אופציונלי)';
  static const String noteLabel = 'הערה (אופציונלי)';
  static const String noItemsYet = 'אין עדיין מוצרים ברשימה';
  static const String startShopping = 'התחל קנייה';
  static const String finishShopping = 'סיום קנייה';
  static const String save = 'שמירה';
  static const String cancel = 'ביטול';
  static const String delete = 'מחיקה';
  static const String edit = 'עריכה';
  static const String markPurchased = 'סמן כנקנה';
  static const String markNotFound = 'סמן כלא נמצא';
  static const String backToPending = 'החזר לרשימה';
  static const String addedByLabel = 'נוסף ע״י';
  static const String confirmDeleteTitle = 'למחוק מוצר?';
  static const String confirmDeleteMessage = 'הפעולה לא ניתנת לביטול';
  static const String statusNotFound = 'לא נמצא';
  static const String statusPurchased = 'נקנה';
  static const String shoppingSummary = 'סיכום קנייה';
  static const String shoppingHistory = 'היסטוריית קניות';
  static const String noHistoryYet = 'אין עדיין היסטוריית קניות';
  static const String purchasedItemsLabel = 'נקנו';
  static const String notFoundItemsLabel = 'לא נמצאו';
  static const String carryOverHint = 'סמנו אילו מוצרים להעביר לקנייה הבאה';
  static const String selectAll = 'בחר הכל';
  static const String clearAll = 'נקה הכל';
  static const String confirmFinishShopping = 'אישור וסיום';
  static const String nothingToFinish = 'אין עדיין מוצרים שנקנו או שלא נמצאו';
  static const String itemsCountLabel = 'מוצרים';
  static const String myShoppingLists = 'רשימות הקניות שלי';
  static const String newShoppingList = 'רשימת קניות חדשה';
  static const String listNameLabel = 'שם הרשימה';
  static const String listDateLabel = 'תאריך (אופציונלי)';
  static const String chooseDate = 'בחר תאריך';
  static const String createList = 'צור רשימה';
  static const String noListsYet = 'עדיין אין רשימות קניות';
  static const String activeSessionBadge = 'פעילה';
  static const String currentShoppingOption = 'קנייה נוכחית';
  static const String currentShoppingSubtitle = 'בחרו מתוך קניות קיימות';
  static const String newShoppingOption = 'קנייה חדשה';
  static const String newShoppingSubtitle = 'בחרו תאריך והתחילו רשימה חדשה';
  static const String selectDateForNewList = 'בחרו תאריך לקנייה החדשה';
  static const String confirmDateButton = 'אישור';
  static const String greetingPrefix = 'שלום, משפחת';
  static const String greetingSubtitle = 'הנה מה שקורה בבית היום';
  static const String comingSoonSectionTitle = 'בקרוב באפליקציה';
  static const String calendarCardTitle = 'לוח שנה';
  static const String upcomingEventsTitle = 'האירועים הקרובים';
  static const String noUpcomingEvents = 'אין עדיין קניות מתוכננות בחודש הזה';
  static const String tabHome = 'בית';
  static const String tabShopping = 'קניות';
  static const String tabCalendar = 'לוח שנה';
  static const String tabTasks = 'משימות';
  static const String tabMore = 'עוד';
  static const String confirmSignOutTitle = 'להתנתק?';
  static const String confirmSignOutMessage = 'תצטרך להתחבר שוב כדי להיכנס לאפליקציה.';
  static const String tasksComingSoonBody = 'ניהול משימות ותזכורות יומיומיות למשק הבית - בקרוב.';
  static const String noEventOnThisDay = 'אין כלום מתוכנן ביום הזה';
  static const String selectedDayDetailsTitle = 'מתוכנן ליום זה';
  static const String billsSectionTitle = 'חשבונות';
  static const String vaadBayitTitle = 'ועד בית';
  static const String electricityTitle = 'חשמל';
  static const String waterAndTaxTitle = 'מים + ארנונה';
  static const String paidStatus = 'שולם';
  static const String notPaidStatus = 'לא שולם';
  static const String amountLabel = 'סכום ששולם';
  static const String paymentMethodLabel = 'אמצעי תשלום';
  static const String saveButton = 'שמור';
  static const String monthNames = 'ינואר,פברואר,מרץ,אפריל,מאי,יוני,יולי,אוגוסט,ספטמבר,אוקטובר,נובמבר,דצמבר';
  static const String paymentMethodBit = 'ביט';
  static const String paymentMethodPaybox = 'פייבוקס';
  static const String paymentMethodBankTransfer = 'העברה בנקאית';
  static const String paymentMethodCash = 'מזומן';
  static const String paymentMethodOther = 'אחר';
  static const String enterPaymentUrlTitle = 'הגדרת קישור תשלום';
  static const String enterPaymentUrlBody = 'הכניסו את כתובת האתר שבו אתם משלמים - נשמור אותה כדי לפתוח אותה בלחיצה בכל פעם.';
  static const String paymentUrlLabel = 'כתובת האתר';
  static const String saveAndContinue = 'שמור והמשך';
  static const String waterTaxCombinedQuestion = 'מים וארנונה משולמים אצלכם יחד או בנפרד?';
  static const String combinedOption = 'ביחד';
  static const String separateOption = 'בנפרד';
  static const String waterUrlLabel = 'כתובת אתר תשלום מים';
  static const String taxUrlLabel = 'כתובת אתר תשלום ארנונה';
  static const String payNowButton = 'שלם עכשיו';
  static const String payWaterButton = 'שלם מים';
  static const String payTaxButton = 'שלם ארנונה';
  static const String editLinkButton = 'ערוך קישור';
  static const String openAppPrefix = 'פתח את';
  static const String enterAppLinkTitlePrefix = 'הזן קישור ל-';
  static const String close = 'סגור';
  static const String cancelPaymentAction = 'בטל תשלום';
  static const String scanBarcodeButton = 'סרוק ברקוד משובר תשלום';
  static const String scanBarcodeTitle = 'סריקת ברקוד';
  static const String scanBarcodeHint = 'כוונו את המצלמה לברקוד שעל שובר התשלום';
  static const String paymentMethodBarcode = 'נסרק מברקוד';
  static const String payByLinkButton = 'שלם בקישור לאתר';
  static const String paymentMethodLink = 'שולם באתר';
  static const String reminderButton = 'הוסף תזכורת לתשלום';
  static const String reminderSetLabel = 'תזכורת מוגדרת ל-';
  static const String editReminderButton = 'ערוך תזכורת';
  static const String clearReminderButton = 'בטל תזכורת';
  static const String pickReminderDateTitle = 'בחר תאריך לתזכורת';
  static const String pickReminderTimeTitle = 'בחר שעה לתזכורת';
  static const String billReminderTitle = 'תזכורת תשלום';
  static const String billReminderBody = 'הגיע הזמן לשלם - בדקו את מסך החשבונות';
  static const String reminderInPastError = 'התאריך/שעה שנבחרו כבר עברו';
  static const String shoppingEventLabel = 'קנייה';
  static const String timeModeWheel = 'עבור לגלגל';
  static const String timeModeManual = 'עבור להקלדה';
  static const String carriedOverSectionTitle = 'לא נמצאו - הועברו לקנייה הבאה';
  static const String droppedSectionTitle = 'לא נמצאו - לא הועברו';
  static const String activeShoppingBanner = 'קנייה פעילה';
  static const String newBadge = 'חדש';
  static const String startedByLabel = 'התחילה על ידי';
  static const String newItemNotificationTitle = 'מוצר חדש נוסף לרשימה';
  static const String shoppingDoneNotificationTitle = 'הקנייה הסתיימה';
  static const String notFoundNotificationBody = 'לא נמצאו';
  static const String enableNotificationsTitle = 'הפעלת התראות';
  static const String enableNotificationsBody = 'קבלו התראה מיידית כשבן/בת הזוג מוסיפים מוצר בזמן קנייה';
  static const String enableNotificationsButton = 'הפעל התראות';
  static const String notificationsBlockedBody = 'התראות חסומות בדפדפן. יש לאפשר אותן ידנית בהגדרות האתר.';
  static const String testNotificationButton = 'שלח התראת בדיקה';
  static const String testNotificationTitle = 'התראת בדיקה';
  static const String testNotificationBody = 'אם אתה רואה את זה, ההתראות עובדות!';
  static const String notificationsLabel = 'התראות';
  static const String notificationsInfoTooltip = 'זה מאפשר קבלת התראות מהאפליקציה לטלפון';
}

HMEOF
cat > 'lib/features/home/tabs/calendar_tab_content.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_strings.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/bill_payment_model.dart';
import '../../../models/shopping_list_model.dart';
import '../../../providers/bills_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../shopping/shopping_list_screen.dart';

/// תוכן טאב "לוח שנה" - לוח חודשי אמיתי עם גלילה בין חודשים,
/// לחיצה על יום מציגה מה מתוכנן בו, ולמטה "אירועים קרובים" ל-3
/// ימים קדימה. מבוסס על שני מקורות אמיתיים: תאריכי רשימות קניות,
/// **וגם** תזכורות תשלום שהוגדרו (ר' bill_reminder_listener.dart
/// להתראה בפועל - זה כאן רק התצוגה החזותית בלוח).
class CalendarTabContent extends ConsumerStatefulWidget {
  final String householdId;

  const CalendarTabContent({super.key, required this.householdId});

  @override
  ConsumerState<CalendarTabContent> createState() => _CalendarTabContentState();
}

class _CalendarTabContentState extends ConsumerState<CalendarTabContent> {
  late DateTime _month;
  DateTime? _selectedDay;

  static const _weekdayLabels = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _selectedDay = null;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(shoppingListsProvider(widget.householdId)).value ?? [];
    final reminders =
        ref.watch(allScheduledRemindersProvider(widget.householdId)).value ?? [];

    final datedListsWithItems = <ShoppingList>[];
    for (final list in lists) {
      if (list.date == null) continue;
      final items = ref
              .watch(shoppingItemsProvider((householdId: widget.householdId, listId: list.id)))
              .value ??
          const [];
      if (items.isNotEmpty) datedListsWithItems.add(list);
    }

    final billReminders = reminders.where((b) => b.reminderAt != null).toList();

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingEmptyCells = _month.weekday % 7;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final markedDaysFromLists = datedListsWithItems
        .where((l) => l.date!.year == _month.year && l.date!.month == _month.month)
        .map((l) => l.date!.day);
    final markedDaysFromReminders = billReminders
        .where((b) => b.reminderAt!.year == _month.year && b.reminderAt!.month == _month.month)
        .map((b) => b.reminderAt!.day);
    final markedDays = {...markedDaysFromLists, ...markedDaysFromReminders};

    final selectedDayLists = _selectedDay == null
        ? <ShoppingList>[]
        : datedListsWithItems.where((l) => _isSameDay(l.date!, _selectedDay!)).toList();
    final selectedDayReminders = _selectedDay == null
        ? <BillPayment>[]
        : billReminders.where((b) => _isSameDay(b.reminderAt!, _selectedDay!)).toList();

    final upcomingLists = datedListsWithItems
        .where((l) =>
            !l.date!.isBefore(todayStart) &&
            l.date!.isBefore(todayStart.add(const Duration(days: 3))))
        .toList();
    final upcomingReminders = billReminders
        .where((b) =>
            !b.reminderAt!.isBefore(todayStart) &&
            b.reminderAt!.isBefore(todayStart.add(const Duration(days: 3))))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(-1),
            ),
            Text('${_month.month}/${_month.year}', style: AppTextStyles.heading2),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        Row(
          children: _weekdayLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(l, style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: leadingEmptyCells + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingEmptyCells) return const SizedBox.shrink();
            final day = index - leadingEmptyCells + 1;
            final date = DateTime(_month.year, _month.month, day);
            final isMarked = markedDays.contains(day);
            final isToday = _isSameDay(date, now);
            final isSelected = _selectedDay != null && _isSameDay(_selectedDay!, date);

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedDay = date),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDark
                      : isMarked
                          ? AppColors.primary
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected && !isMarked
                      ? Border.all(color: AppColors.primary, width: 1.4)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected || isMarked ? Colors.white : AppColors.textPrimary,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
        if (_selectedDay != null) ...[
          const Divider(height: 28),
          Text(
            '${AppStrings.selectedDayDetailsTitle} · ${DateFormatter.dateOnly(_selectedDay)}',
            style: AppTextStyles.heading2.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (selectedDayLists.isEmpty && selectedDayReminders.isEmpty)
            Text(AppStrings.noEventOnThisDay, style: AppTextStyles.bodySecondary)
          else ...[
            ...selectedDayLists.map(
              (l) => Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_cart, color: Colors.blue, size: 26),
                  title: const Text(AppStrings.shoppingEventLabel),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ShoppingListScreen(householdId: widget.householdId, listId: l.id),
                    ),
                  ),
                ),
              ),
            ),
            ...selectedDayReminders.map(
              (b) => Card(
                child: ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.green, size: 26),
                  title: Text(billCategoryDisplayName(b.category)),
                  subtitle: Text(DateFormatter.short(b.reminderAt)),
                ),
              ),
            ),
          ],
        ],
        const Divider(height: 28),
        Text(AppStrings.upcomingEventsTitle, style: AppTextStyles.heading2.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        if (upcomingLists.isEmpty && upcomingReminders.isEmpty)
          Text(AppStrings.noUpcomingEvents, style: AppTextStyles.bodySecondary)
        else ...[
          ...upcomingLists.map(
            (l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 22, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(AppStrings.shoppingEventLabel, style: AppTextStyles.body)),
                  Text(DateFormatter.dateOnly(l.date), style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
          ),
          ...upcomingReminders.map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.alarm, size: 22, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(billCategoryDisplayName(b.category), style: AppTextStyles.body),
                  ),
                  Text(DateFormatter.short(b.reminderAt), style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

HMEOF
echo 'DONE - consistent icon+label+date order with vivid colors!'
