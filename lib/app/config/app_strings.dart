/// טקסטים מרכזיים בממשק.
///
/// בשלב זה כל הטקסטים בעברית קשיחים כאן (לא בתוך ה-widgets עצמם).
/// זה מכין את הקרקע להוספת תמיכה רב-לשונית (i18n) בעתיד בלי
/// לשכתב מסכים - רק להחליף את המקור של המחלקה הזו.
class AppStrings {
  AppStrings._();

  // כללי
  static const String appName = 'Home Manager';
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
  static const String inviteMessageTitle = 'הזמנה ל-Home Manager';
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
}

