# PROJECT_STATUS.md — Home Manager

> קובץ זה מתעדכן אחרי כל שלב משמעותי. אם פותחים שיחה/session חדש/ה,
> יש לקרוא קובץ זה **וגם** את הקוד הקיים לפני שממשיכים לפתח.

---

## שלב נוכחי
**שלב 4 — Household** ✅ הושלם בקוד (טרם נבדק בפועל ע"י המשתמש, כולל פריסת Security Rules)

## השלב הבא
**שלב 5 — Shopping List** (CRUD בסיסי: הוספה/עריכה/מחיקה/סימון מוצרים)

---

## מה כבר בנוי

### מבנה פרויקט
- מבנה תיקיות מלא לפי הארכיטקטורה שסוכמה: `app/`, `core/`, `models/`, `services/`, `repositories/`, `providers/`, `features/`.
- `pubspec.yaml` עם כל התלויות הצפויות לשלבים 1-10 (Riverpod, go_router, Firebase packages, intl).

### Branding & Config (מרוכז, לא מקושח בקוד)
- `lib/app/config/app_config.dart` — שם אפליקציה, גרסה, קבועים כלליים.
- `lib/app/config/app_colors.dart` — פלטת צבעים (ירוק/לבן/אפור לפי הבריף).
- `lib/app/config/app_text_styles.dart` — טיפוגרפיה מרכזית.
- `lib/app/config/app_strings.dart` — טקסטים מרכזיים בעברית, מוכן ל-i18n עתידי.

### Core (utilities משותפים)
- `lib/core/errors/failures.dart` — מחלקות שגיאה אחידות (Network/Permission/Auth/Unknown).
- `lib/core/utils/validators.dart` — ולידציה לטפסים (email, password, שדה חובה, מספר חיובי).
- `lib/core/widgets/loading_indicator.dart`, `empty_state.dart`, `error_view.dart` — מצבי טעינה/ריק/שגיאה אחידים.

### App shell
- `lib/app/app.dart` — MaterialApp.router, theme מלא, RTL + locale עברית.
- `lib/app/router.dart` — go_router, כרגע רק route יחיד ('/').
- `lib/features/splash/splash_screen.dart` — מסך פתיחה בסיסי.
- `lib/main.dart` — נקודת כניסה, **כולל אתחול Firebase בפועל** (`Firebase.initializeApp`).

### Firebase (שלב 2)
- פרויקט Firebase אמיתי בשם "Home Manager" (Spark plan / חינמי), project id: `home-manager-9407a`.
- Authentication מופעל, Email/Password provider פעיל.
- Cloud Firestore מופעל, ב-production mode (Security Rules ברירת מחדל מחמירות - טרם נכתבו rules מותאמים, זה יגיע בשלב ההרשאות).
- חובר לקוד באמצעות FlutterFire CLI (`flutterfire configure`) — פלטפורמה נתמכת כרגע: **Web בלבד** (Android/iOS ניתן להוסיף בהמשך באותה פקודה בלי לאבד קונפיגורציה קיימת).
- `lib/firebase_options.dart` נוצר אוטומטית - **לא לערוך ידנית**, הוא מנוהל על ידי flutterfire CLI.
- סביבת עבודה: GitHub Codespaces (לא מקומי) - repository: `lilovem/Home-Manager`.

### Authentication (שלב 3)
- `lib/services/firebase/firebase_auth_service.dart` — עטיפה דקה סביב FirebaseAuth (Service layer).
- `lib/repositories/auth_repository.dart` — מתרגם שגיאות Firebase לעברית (AuthFailure), זו השכבה ש-UI קורא לה.
- `lib/providers/auth_provider.dart` — Riverpod providers: `authRepositoryProvider`, `authStateChangesProvider` (Stream<User?>).
- `lib/app/auth_gate.dart` — "השומר" הראשי: מאזין למצב ההתחברות ומציג אוטומטית Splash/Login/Home.
- `lib/features/auth/login_screen.dart` — טופס התחברות אמיתי עם ולידציה, loading state, הצגת שגיאות.
- `lib/features/auth/register_screen.dart` — טופס הרשמה עם אימות סיסמה כפול.
- `lib/features/home/home_screen.dart` — מסך placeholder שמוצג אחרי התחברות מוצלחת, עם כפתור התנתקות.
- `lib/app/router.dart` עודכן: '/' מציג AuthGate, '/register' הוא route נפרד.
- זרימה: משתמש לא מחובר → Login (אפשרות לעבור ל-Register) → הרשמה/התחברות מצליחה → AuthGate מזהה אוטומטית ומעביר ל-Home. אין ניווט ידני אחרי login/register - זה קורה אוטומטית דרך ה-Stream.

### Household (שלב 4)
- `lib/models/household_model.dart` — מודל Household (id, name, createdBy, createdAt, memberIds).
- `lib/services/firebase/household_service.dart` — קריאות Firestore גולמיות (יצירה, הצטרפות, מעקב).
- `lib/repositories/household_repository.dart` — מתרגם שגיאות Firestore לעברית.
- `lib/providers/household_provider.dart` — `myHouseholdProvider` (Stream<Household?>), תלוי אוטומטית ב-authState.
- `lib/app/household_gate.dart` — "שומר" שני (אחרי AuthGate): מציג מסך יצירה/הצטרפות אם אין household, אחרת Home.
- `lib/features/household/create_household_screen.dart` — מסך אחד עם toggle בין "יצירת household חדש" ל-"הצטרפות עם קוד הזמנה".
- `lib/features/household/invite_partner_screen.dart` — מציג את קוד ההזמנה (=מזהה ה-household) עם כפתור העתקה.
- `lib/features/home/home_screen.dart` עודכן — מציג שם household, מספר חברים, כפתור הזמנה, וכפתור התנתקות ב-AppBar.
- **מודל ההזמנה:** מזהה ה-household המקורי (Firestore auto-ID, ארוך ואקראי) משמש גם כ"קוד ההזמנה" - אין collection נפרד ל-invites, ואין Cloud Function. מי שמקבל את הקוד (ידנית, לא דרך שיתוף אוטומטי) יכול "להצטרף" ע"י כתיבה ישירה, כפי שמאושר ב-Security Rules.
- `firestore.rules`, `firebase.json`, `firestore.indexes.json` — נוצרו בשורש הפרויקט. **טרם נפרסו בפועל** (`firebase deploy --only firestore:rules`) - יש לוודא שזה בוצע לפני שממשיכים.

---

## מה עדיין לא עובד / לא קיים
- טרם נבדק בפועל אצל המשתמש (יצירת household, הצטרפות עם קוד, הצגה במסך הבית).
- **Security Rules טרם נפרסו** (`firestore.rules` קיים בקוד אבל לא הורץ `firebase deploy --only firestore:rules`) - עד אז Firestore עדיין ב-production mode דיפולטיבי שחוסם הכל, כלומר יצירת household תיכשל.
- אין עדיין Shopping List, Models/Services/Repositories/Providers של קניות — שלב 5.
- Android/iOS עדיין לא הוגדרו ב-flutterfire (רק Web) - להוסיף כשהמשתמש ירצה לבדוק על מכשיר אמיתי.
- שני חברי household לא נבדקו בפועל יחד (תרחיש: משתמש א' יוצר, משתמש ב' מצטרף עם הקוד) - כדאי לבדוק עם שני חשבונות אימייל שונים.

---

## בעיות פתוחות
- יש להחליט על גופן עברי (`Rubik` צוין ב-`app_text_styles.dart` כברירת מחדל, אך קובץ הגופן עצמו טרם נוסף ל-assets — אפשר גם להשתמש בגופן ברירת המחדל של המערכת בינתיים).
- כשנרצה לבדוק על טלפון אמיתי (Android/iOS), יהיה צריך להריץ שוב `flutterfire configure` ולסמן גם את הפלטפורמות האלה.

---

## החלטות ארכיטקטוניות חשובות
1. **State Management: Riverpod ללא code generation** — נבחר כדי לפשט את חוויית הפיתוח למתחיל (אין תלות ב-`build_runner` בשלב זה). ניתן לשדרג בעתיד ל-`riverpod_generator` אם ירצה המשתמש.
2. **מודלים ידניים (ללא Freezed)** — למען קריאות ופשטות למי שאינו מתכנת מקצועי. אם הפרויקט יגדל משמעותית, ניתן לשקול מעבר ל-Freezed בעתיד.
3. **Branding מרוכז לחלוטין** — שום קובץ UI לא מכיל מחרוזת "Home Manager" קשיחה או קוד צבע ישיר; הכל דרך `app_config.dart` / `app_colors.dart` / `app_strings.dart`.
4. **Firebase מאותחל ב-`main.dart` החל משלב 2** — בשלב 1 הושאר ללא Firebase בכוונה, כדי לוודא שהמבנה הבסיסי תקין לפני הכנסת תלות חיצונית אמיתית.
5. **Secrets** — שום מפתח/סוד לא יישמר בצד ה-Flutter client לאורך כל הפרויקט; קריאות הדורשות secret (מחירי סופר, WhatsApp) יעברו תמיד דרך Cloud Functions.
6. **סביבת הפיתוח: GitHub Codespaces (בענן), לא מקומי** — המשתמש עובד ללא Flutter SDK מותקן על המחשב האישי. כל הפיתוח וההרצה קורים דרך דפדפן ב-`github.com/lilovem/Home-Manager` (Code → Codespaces). זה משפיע על שלבים עתידיים: FCM/Push Notifications ידרוש בסופו של דבר מכשיר אמיתי או אמולטור מקומי לבדיקה מלאה (Web אינו תומך היטב ב-FCM), נדון בזה כשנגיע לשלב 8.
7. **AuthGate במקום go_router redirect** — לניתוב לפי מצב התחברות בחרנו בווידג'ט (`AuthGate`) שמאזין ל-Stream ומחליף תוכן, במקום `redirect` מבוסס-Listenable של go_router. זה פשוט יותר להבנה ולתחזוקה עבור מי שאינו מתכנת מקצועי, במחיר קטן של גמישות ניתוב מתקדמת (שלא נדרשת כרגע).
8. **הזמנה ל-Household ללא Cloud Function** — במקום collection נפרד ל-invites עם תוקף/מעקב, השתמשנו במזהה ה-household עצמו (Firestore auto-ID) כ"קוד ההזמנה", והרשאת ההצטרפות ב-Security Rules בודקת שהעדכון היחיד הוא הוספת ה-uid של המצטרף למערך memberIds. זו פשרה מכוונת: מספיק מאובטח לאפליקציה משפחתית (המזהה ארוך ואקראי, לא ניתן לניחוש), אך פחות "קשיח" מפתרון מבוסס Cloud Function עם תוקף/שימוש חד-פעמי. אם בעתיד נרצה הקשחה (תפוגת קוד, הגבלת מספר הצטרפויות) - נעביר את הלוגיקה ל-Cloud Function.
9. **HouseholdGate כשומר שני** — נוסף מעל AuthGate (לא בתוכו) כדי לשמור על אחריות יחידה לכל widget: AuthGate שואל "האם מחובר", HouseholdGate שואל "האם יש לו household". זה גם מקל להוסיף בעתיד שומרים נוספים (למשל "האם סיים onboarding") בלי לנפח widget אחד.

---

## הוראות הפעלה (למשתמש)
ראה קובץ `SETUP_INSTRUCTIONS.md` שנשלח יחד עם קבצי הפרויקט.

