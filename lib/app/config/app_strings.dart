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
  static const String membersCount = 'חברים במשק הבית';

  // Shopping
  static const String shoppingList = 'רשימת קניות';
  static const String addProduct = 'הוספת מוצר';
  static const String productName = 'שם המוצר';
  static const String quantity = 'כמות';
  static const String noItemsYet = 'אין עדיין מוצרים ברשימה';
  static const String startShopping = 'התחל קנייה';
  static const String finishShopping = 'סיום קנייה';
}

