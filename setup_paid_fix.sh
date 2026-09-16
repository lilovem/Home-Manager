bash setup_bill_reminders_full.sh#!/bin/bash
set -e
cat > 'PROJECT_STATUS.md' << 'HMEOF'
# PROJECT_STATUS.md — Home Manager

> קובץ זה מתעדכן אחרי כל שלב משמעותי. אם פותחים שיחה/session חדש/ה,
> יש לקרוא קובץ זה **וגם** את הקוד הקיים לפני שממשיכים לפתח.

---

## שלב נוכחי
**שלב 8 — Push Notifications (גרסה חינמית, בלי Blaze)** ✅ הושלם בקוד (טרם נבדק). המשתמש בחר במפורש בחלופה החינמית על פני שדרוג ל-Blaze + Cloud Functions.

## השלב הבא
בדיקה בפועל של ההתראות (שני משתמשים, שני חלונות/מכשירים). בעתיד: אפשר לשדרג ל-Blaze + FCM אמיתי בלי לאבד את הקוד הקיים (הארכיטקטורה המודולרית תומכת בזה).

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

### Household (שלב 4) — ✅ נבדק בפועל עם 2 משתמשים אמיתיים
- `lib/models/household_model.dart` — מודל Household (id, name, createdBy, createdAt, memberIds, shoppingListId).
- `lib/services/firebase/household_service.dart` — קריאות Firestore גולמיות (יצירה, הצטרפות, מעקב).
- `lib/repositories/household_repository.dart` — מתרגם שגיאות Firestore לעברית.
- `lib/providers/household_provider.dart` — `myHouseholdProvider` (Stream<Household?>), תלוי אוטומטית ב-authState.
- `lib/app/household_gate.dart` — "שומר" שני (אחרי AuthGate): מציג מסך יצירה/הצטרפות אם אין household, אחרת Home.
- `lib/features/household/create_household_screen.dart` — מסך אחד עם toggle בין "יצירת household חדש" ל-"הצטרפות עם קוד הזמנה".
- `lib/features/household/invite_partner_screen.dart` — מציג את קוד ההזמנה (=מזהה ה-household) עם כפתור העתקה.
- **נבדק בהצלחה:** משתמש א' יצר household, משתמש ב' (מייל שונה, חלון incognito) הצטרף עם הקוד - שניהם רואים "חברים במשק הבית: 2" בזמן אמת.
- `firestore.rules`, `firebase.json`, `firestore.indexes.json` — נפרסו בהצלחה (`firebase deploy --only firestore:rules`).

### Shopping List (שלב 5)
- `lib/models/shopping_list_model.dart` — מודל רשימה (id, name, createdAt). MVP: רשימה אחת בלבד ל-household, ה-id שלה נשמר על `household.shoppingListId`.
- `lib/models/shopping_item_model.dart` — מודל מוצר מלא: name, quantity, unit, status (pending/purchased/notFound), addedBy/addedByName/addedAt, purchasedAt/notFoundAt, וגם `addedDuringShopping` (ברירת מחדל false - מוכן לשלב 7 בלי מיגרציה עתידית).
- `lib/core/utils/date_formatter.dart` — פורמט תאריך פשוט (ללא תלות ב-locale init של intl).
- `lib/services/firebase/shopping_service.dart` — כולל `getOrCreateDefaultListId` שיוצר רשימה אוטומטית אם עדיין אין ל-household אחת (backward-compatible עם households שנוצרו לפני שלב זה).
- `lib/repositories/shopping_repository.dart`, `lib/providers/shopping_provider.dart` — כולל `shoppingItemsProvider` (StreamProvider.family לפי household+list, real-time).
- `lib/features/shopping/shopping_list_screen.dart` — מסך ראשי: רשימה, checkbox לסימון "נקנה", תפריט (⋮) לכל פריט עם "סמן כלא נמצא"/"החזר לרשימה"/"עריכה"/"מחיקה" (עם דיאלוג אישור).
- `lib/features/shopping/add_edit_product_screen.dart` — טופס משותף להוספה ועריכה (name, quantity, unit אופציונלי).
- `lib/features/home/home_screen.dart` עודכן — כפתור "רשימת קניות" חדש.
- `firestore.rules` עודכן — הרשאות ל-`households/{id}/shoppingLists/{id}/items/{id}`, מוגבל לחברי household בלבד (פונקציית עזר `isHouseholdMember` משותפת).

### קטגוריות אוטומטיות למוצרים
- `lib/core/utils/product_categorizer.dart` — 12 קטגוריות קבועות (ירקות ופירות, מוצרי חלב, בשר/עוף/דגים, לחם ומאפים, קפואים, מזון יבש, תבלינים ורטבים, משקאות, חטיפים, ניקיון, טואלטיקה, שונות), עם רשימת מילות מפתח בעברית לכל קטגוריה וסדר תצוגה קבוע (בערך לפי סדר מדפים בסופר).
- `ShoppingItem.category` — getter מחושב (לא נשמר ב-Firestore) שמסווג לפי שם המוצר. עריכת שם מוצר מעדכנת אוטומטית את הקטגוריה.
- `lib/features/shopping/shopping_list_screen.dart` עודכן — הפריטים מקובצים לפי קטגוריה; **קטגוריה מוצגת רק אם יש בה לפחות מוצר אחד ברשימה**.

### עיצוב מסכי כניסה - באנר ירוק
- `lib/features/auth/login_screen.dart`, `lib/features/household/create_household_screen.dart`, `lib/features/home/home_screen.dart` — כולם משתפים עכשיו את אותו באנר עליון: אייקון בית + "Home Manager" ברקע ירוק מעוגל. הוסר כותרת כפולה מה-AppBar של מסך הבית (היה מוצג פעמיים).

### Active Shopping - צד לקוח בלבד (שלב 7)
- `lib/models/shopping_session_model.dart` — מודל session (startedAt, startedBy/Name, endedAt, status).
- `lib/models/shopping_list_model.dart` עודכן — שדה `activeSessionId` (null = אין קנייה פעילה).
- `lib/services/firebase/shopping_service.dart` — `watchListMeta()` (stream של metadata הרשימה, כולל activeSessionId), `startShoppingSession()`.
- `addItem()` מקבל כעת `addedDuringShopping: bool`, נקבע לפי `activeSessionId != null` בזמן ההוספה.
- `finishShopping()` עודכן — מקבל `activeSessionId` אופציונלי; אם קיים, סוגר גם את ה-session (status='completed', endedAt) **באותו batch אטומי** יחד עם שאר הפעולות.
- `lib/features/shopping/shopping_list_screen.dart` עודכן — באנר ירוק "קנייה פעילה" כשיש session פעיל, כפתור "התחל קנייה" כשאין, ותגית "חדש" (כחולה) על פריטים שנוספו בזמן קנייה פעילה.
- `firestore.rules` עודכן — הרשאה ל-`households/{id}/shoppingLists/{id}/sessions/{sessionId}`.
- **חסר עדיין (שלב 8):** שום Push Notification בפועל. הבאנר/תגית הם רק UI - אף אחד לא מקבל התראה כרגע כשמוצר נוסף בזמן קנייה פעילה.
- **תוקן:** באג שבו פריט שהועבר ל"קנייה הבאה" (דרך סיום קנייה) המשיך להציג את תגית "חדש" - `addedDuringShopping` מתאפס עכשיו במפורש בזמן ה-carry-over.

### Push Notifications - גרסה חינמית (שלב 8)
**החלטה מפורשת של המשתמש:** לוותר על Blaze plan + Cloud Functions (שדורשים כרטיס אשראי, גם אם השימוש בפועל נשאר בתוכנית החינמית של Blaze) לטובת חלופה חינמית לגמרי, במחיר מגבלה אחת: **עובד רק כשהאפליקציה פתוחה** (טאב פתוח, ולו ברקע) - לא כשהיא סגורה לגמרי. שדרוג ל-Blaze בעתיד אפשרי בלי לשכתב את הקוד הקיים.

**איך זה עובד:** במקום Cloud Function ששולח Push דרך שרת, האפליקציה עצמה "מאזינה" לשינויים ב-Firestore (כמו שכבר עשתה ל-real-time sync), ומזהה מוצרים/קניות חדשים ברגע שהם מגיעים - ואז מציגה Web Notification אמיתי של הדפדפן (`dart:html`'s `Notification`), לא רק שינוי במסך.

- `lib/services/notifications/browser_notification_service.dart` — קובץ "מתג" (barrel) שבוחר אוטומטית בין המימוש ל-Web לבין stub ריק לכל פלטפורמה אחרת, דרך conditional export (`if (dart.library.html)`). מבטיח שהקוד ימשיך להתקמפל גם ל-Android/iOS בעתיד בלי שינוי.
- `lib/services/notifications/browser_notification_service_web.dart` — המימוש האמיתי, עוטף את `dart:html`'s `Notification` API (בקשת הרשאה + הצגת התראה).
- `lib/services/notifications/browser_notification_service_stub.dart` — גרסת no-op לכל פלטפורמה שאינה Web.
- `lib/providers/notification_provider.dart` — provider פשוט ל-service הזה.
- `lib/models/shopping_history_model.dart` עודכן — שדות `completedBy`/`completedByName`, כדי שנוכל להתעלם ממי שביצע בעצמו את "סיום הקנייה" בהתראה.
- `lib/features/shopping/shopping_list_screen.dart` עודכן — משתמש ב-`ref.listen` (לא `ref.watch`) על `shoppingItemsProvider` ו-`shoppingHistoryProvider` כדי להשוות "לפני" מול "אחרי" ולזהות בדיוק מה חדש, ללא כפל התראות בטעינה הראשונית (`previous == null` מדלג).
- **שני סוגי התראות ממומשים:** (1) מוצר חדש נוסף בזמן קנייה פעילה, (2) קנייה הסתיימה + רשימת "לא נמצא" - בשני המקרים מי שביצע את הפעולה לא מקבל התראה על עצמו.
- **אין צורך בשינוי Security Rules** - אין collection חדש, הכל מבוסס על מה שכבר קיים וכבר נגיש לחברי household.
- **באנר הפעלת התראות במסך הבית** — `lib/features/home/home_screen.dart` הפך ל-ConsumerStatefulWidget, מציג באנר ברור (לא רק בקשה שקטה) עם כפתור "הפעל התראות" אם עדיין לא הוחלט, או הסבר איך לתקן ידנית אם נחסמו. דפדפנים לא מאפשרים לבקש הרשאה שוב אוטומטית אחרי שהמשתמש כבר ענה (Allow/Block) - זו מגבלת אבטחה של הדפדפן, לא באג שלנו.
- **כפתור "שלח התראת בדיקה"** — מוצג במסך הבית כשההרשאה כבר granted, מאפשר לוודא שהתראות עובדות בפועל בלי לעבור את כל תהליך "התחל קנייה + הוסף מוצר".
- **תוקן:** notifications ב-Chrome (במיוחד אנדרואיד) דרשו מעבר דרך Service Worker רשום במפורש (`web/notification-sw.js`) - Flutter לא תמיד רושם Service Worker משלו במצב `flutter run`/debug. גם נוסף icon+tag להתראות לשיפור איכות מול מסווג ה-spam של Chrome.

### שינוי שם - Home Manager ← LeeHome
- `lib/app/config/app_config.dart`, `lib/app/config/app_strings.dart` — `appName` שונה ל-**LeeHome**, נוסף `appTagline` = "ניהול הבית שלכם". מוצג ב-Login ו-Splash מתחת לשם, לא בכל באנר (למניעת עומס ויזואלי).
- **תהליך בחירת השם:** נבדקו ונדחו ~19 שמות (Homey, Housy, Dwelly, Nestwell, HomeHub, WeHome, CasaOS/Casafy/Casahub, MiCasa, iCasa, Tidely, Sortio, Sorta ועוד) - כולם כבר בשימוש ע"י אפליקציות אמיתיות באותו תחום או תחום סמוך. LeeHome ו-Casanest היו היחידים שעברו בדיקה נקייה; LeeHome נבחר לבסוף.

### כמה רשימות קניות (לא רק אחת)
- **שינוי ארכיטקטוני משמעותי:** בוטלה ההנחה "household אחד = רשימה אחת" (`household.shoppingListId` + `getOrCreateDefaultListId`). עכשיו household יכול להכיל **כמה רשימות שונות** (למשל "קניות שבועיות", "קניות לשבת", רשימה עם תאריך עתידי).
- `lib/models/shopping_list_model.dart` — נוסף שדה `date` אופציונלי (לתכנון קנייה לתאריך עתידי).
- `lib/services/firebase/shopping_service.dart`, `lib/repositories/shopping_repository.dart` — נוספו `watchLists()` (כל הרשימות) ו-`createList()` (יצירת רשימה עם שם+תאריך אופציונלי). `getOrCreateDefaultListId` נשאר בקוד אך אינו בשימוש יותר (backward-compat בלבד, לא הוסר).
- `lib/providers/shopping_provider.dart` — הוחלף `shoppingListIdProvider` (הניח רשימה יחידה) ב-`shoppingListsProvider` (כל הרשימות) ו-`activeSessionListIdProvider` (מוצא את הרשימה שיש לה session פעיל כרגע, אם יש, מבין כל הרשימות - לצורך התראות).
- `lib/features/shopping/shopping_lists_screen.dart` — מסך חדש: רשימת כל רשימות הקניות של ה-household, כפתור + ליצירת רשימה חדשה (דיאלוג עם שם + בורר תאריך אופציונלי), לחיצה על רשימה פותחת אותה.
- `lib/features/shopping/shopping_list_screen.dart` — עודכן לקבל `listId` כפרמטר חובה במקום לחשב רשימת ברירת מחדל; מציג את שם הרשימה הספציפית ב-AppBar.
- `lib/features/home/home_modules.dart` — האריח "רשימת קניות" פותח עכשיו את `ShoppingListsScreen` (בחירה/יצירה) במקום ישר לרשימה ספציפית.
- `lib/features/shopping/shopping_notifications_listener.dart` — עודכן לעבוד עם `activeSessionListIdProvider` (מוצא דינמית איזו רשימה, מבין כולן, יש לה session פעיל) במקום הנחת רשימה יחידה קבועה.
- **מגבלה מודעת:** אם יש בו-זמנית שתי קניות פעילות על שתי רשימות שונות (נדיר), ההתראות יעבדו רק על אחת מהן (`activeSessionListIdProvider` מחזיר את הראשונה שנמצאה) - פשטות מכוונת, לא נבנה תמיכה בכמה sessions מקבילים בו-זמנית.

### עדכון: זרימת "קנייה נוכחית / קנייה חדשה" עם לוח שנה
- **בוטל** המסך `shopping_lists_screen.dart` (רשימת כל הרשימות + כפתור "+" ליצירה) - הוחלף בזרימה דו-שלבית ברורה יותר.
- `lib/features/shopping/shopping_choice_screen.dart` — מסך כניסה חדש: שתי כרטיסיות גדולות "קנייה נוכחית" ו"קנייה חדשה".
- `lib/features/shopping/existing_shopping_lists_screen.dart` — רשימת קניות **קיימות** בלבד לבחירה (בלי אפשרות יצירה כאן).
- `lib/features/shopping/new_shopping_calendar_screen.dart` — **לוח שנה אמיתי** של החודש הנוכחי (grid 7 עמודות, מיושר לפי ימי השבוע האמיתיים, ראשון=עמודה ראשונה), לחיצה על יום מסמנת אותו, "אישור" יוצר רשימה חדשה עם שם=התאריך ופותח אותה ישירות.
- `lib/features/home/home_modules.dart` עודכן — האריח "רשימת קניות" פותח עכשיו את `ShoppingChoiceScreen`.
- **תוקנו מקומות ששכחו את שינוי השם:** `AppStrings.inviteMessageTitle`, הודעת השיתוף ב-`invite_partner_screen.dart`, והודעת "הזמן חבר לאפליקציה" ב-`home_screen.dart` - כולם השתמשו עדיין ב-"Home Manager" הקשיח במקום `AppStrings.appName`. גם `web/index.html` (title) ו-`web/manifest.json` (name/short_name) עודכנו לשם החדש.
- **עיצוב כותרת מסך הבית:** חזרה למבנה אנכי (אייקון מעל השם, לא לצידו), עם השם ואז הטאגליין מתחתיו, אך נשאר קומפקטי בהרבה מהגרסה המקורית (padding מינימלי) כדי לא לתפוס יותר מדי מהמסך.

### שדרוג טיפוגרפי לטאגליין + צמצום מרווחים
- **הערה חשובה שהתגלתה:** **אין גופני כתב-יד/קליגרפיה אמיתיים לעברית** ב-Google Fonts כרגע (יש בקשה פתוחה ולא-פתורה ב-GitHub של הפרויקט לכך) - עברית רהוטה היא סט אותיות שונה לגמרי, לא רק הטיה (איטליק) של הדפוס הרגיל כמו באנגלית. לכן לא ניתן היה לספק כתב-יד אמיתי כמו בתמונת ההשראה שהמשתמש שלח.
- **הפתרון שיושם:** נוסף `google_fonts` (^6.2.1) ל-`pubspec.yaml`, ונוסף `AppTextStyles.tagline()` המשתמש בגופן Frank Ruhl Libre - גופן סריף עברי אלגנטי ומוכר, קירוב טוב לתחושה "מעוצבת" בלי להתחזות לכתב-יד.
- מיושם ב: `login_screen.dart`, `splash_screen.dart`, `home_screen.dart` (הטאגליין "ניהול הבית שלכם" בכל שלושתם).
- **צומצמו מרווחים** בין האייקון לשם ובין השם לטאגליין (הוסרו ה-`SizedBox` המפרידים) בכל שלושת המסכים, לתחושה קומפקטית ומאוחדת יותר.

### עוד צמצום מקום + העברת סימון ההתראות ל-AppBar
- אייקון "התראות" (כשההרשאה כבר granted) עבר מהגוף (שורה שתפסה מקום קבוע) ל-`leading` של ה-AppBar - בעברית (RTL) זה מציג אותו בפינה הימנית העליונה, בדיוק כמו שהתבקש. לחיצה שולחת התראת בדיקה; לחיצה ארוכה/hover מציגה את הסבר ה-tooltip (מנגנון native של `IconButton.tooltip`, במקום אייקון ⓘ נפרד - פישוט קל כדי להתאים לשטח הסטנדרטי של leading).
- הבאנר "הפעל התראות" (למי שעדיין לא אישר) נשאר בגוף המסך כרגיל, כי הוא כולל טקסט הסבר וכפתור שלא נכנסים ל-AppBar.
- אייקון הבית בבאנר העליון הוקרב עוד יותר לטקסט "LeeHome" מתחתיו באמצעות `Transform.translate` (מפצה על הריפוד הפנימי הטבעי שיש לגליפים של Material Icons).

### שדרוג עיצובי גדול ל-Dashboard (בהשראת תמונות שהמשתמש שלח)
- **הוחלט מראש עם המשתמש (consultation):** רק עיצוב/UI ברמה הזו עכשיו, **לא** נבנו בפועל: מזג אוויר, "מצב הבית", ניווט המבורגר+bottom-nav (שינוי ארכיטקטוני), מסך onboarding עם שקפים. כל אלה נדחו במפורש לעתיד לפי בחירת המשתמש.
- `lib/features/home/home_modules.dart` פוצל לשניים: `buildFeaturedModules()` (4 כרטיסיות מומלצות: קניות/משימות/רכבים/לוח שנה) ו-`buildHomeModules()` (5 המודולים הנותרים: ביטוחים/רישיונות/חוגים/חשבונות/מסמכים, עדיין "בקרוב").
- **"הוצאות" הוחלף ב"רכבים"** בכרטיסיות המומלצות, לפי בקשת המשתמש (רכבים כבר היה מודול עתידי קיים; "הוצאות" לא היה קיים כלל כמודול, לא הוסר שום דבר אמיתי).
- `lib/providers/shopping_provider.dart` — נוספו `totalPendingItemsCountProvider` (סך פריטים "ממתינים" בכל הרשימות יחד, לתג המספר על כרטיסיית "קניות") ו-`upcomingShoppingDatesProvider` (רשימות עם תאריך עתידי/היום, ממוינות) - **שניהם מבוססים על נתונים אמיתיים שכבר קיימים**, לא מוצאים.
- `lib/features/home/home_screen.dart` עבר שכתוב משמעותי: נוסף באנר ברכה ("שלום, משפחת X! הנה מה שקורה בבית היום"), רשת 2x2 של כרטיסיות סטטיסטיקה צבעוניות (`_StatCard` - אייקון בעיגול צבעוני + תג מספר אמיתי או "בקרוב"), כרטיס "לוח שנה" חדש (`_UpcomingCalendarCard` - לוח חודשי אמיתי עם סימון ימים שיש בהם קנייה מתוכננת + רשימת "האירועים הקרובים"), ומתחת לזה כותרת "בקרוב באפליקציה" עם רשת שאר המודולים (`_ModuleTile` פושט - כולם "בקרוב" עכשיו, אין יותר ענף "available" כי קניות עברה לכרטיסיות המומלצות).
- **הערה על "לוח שנה":** זה **לא** מודול עצמאי אמיתי (אין collection של "events" ב-Firestore) - זו תצוגה חכמה שממחזרת נתונים קיימים (תאריכי `ShoppingList`). ברגע שיתווסף בעתיד מודול "משימות" או "אירועים" אמיתי, אפשר להרחיב את אותו כרטיס לאגד גם את הנתונים שלו.
- `lib/core/utils/product_categorizer.dart` — נוסף `categoryIcons` (מיפוי קטגוריה → אייקון Material), מוצג עכשיו ליד שם כל מוצר ברשימת הקניות (`shopping_list_screen.dart`).

### שינוי ארכיטקטוני גדול: ניווט תחתון קבוע (5 טאבים)
- **הוחלט אחרי כמה סבבי דיוק עם המשתמש** (זו הייתה בהתחלה "לא" מפורש, ואז שונתה) - `lib/features/home/home_screen.dart` הישן **הוסר לגמרי**, הוחלף ב-`lib/features/home/main_shell_screen.dart`.
- **מבנה קבוע:** לוגו + ברכה + כרטיסיית household + באנר התראות - **תמיד גלויים**, לא בתוך גלילה, בכל הטאבים. מתחת לזה - `NavigationBar` (Material 3) קבוע עם 5 יעדים: בית | קניות | לוח שנה | משימות | עוד. הטאב הפעיל תמיד מודגש.
- **גוף המסך מוחלף (לא נפתח כ-route חדש)** לפי הטאב שנבחר - כל טאב הוא widget נפרד תחת `lib/features/home/tabs/`:
  - `home_tab_content.dart` - רשת 4 חלונות (קניות/לוח שנה/משימות/רכבים), לחיצה על קניות/לוח שנה/משימות **מחליפה טאב** (לא פותחת מסך חדש) דרך callback `onSelectTab`.
  - `shopping_tab_content.dart` - אותו תוכן שהיה ב-`ShoppingChoiceScreen` (שתי כרטיסיות קנייה נוכחית/חדשה), רק מוטמע ישירות בלי Scaffold/AppBar משלו.
  - `calendar_tab_content.dart` - **מסך לוח שנה מלא**: גלילה בין חודשים (חצים), לחיצה על יום מציגה מתחת מה מתוכנן בו (עם לינק לפתוח את הרשימה), "אירועים קרובים" ל-**3 ימים** קדימה בלבד (היה "כל העתיד" קודם). **תוקן הבאג המקורי:** רק רשימות עם מוצרים בפועל נספרות/מסומנות - רשימות ריקות (משאריות בדיקות) לא מופיעות יותר.
  - `tasks_tab_content.dart` - "בקרוב" פשוט.
  - `more_tab_content.dart` - רשת שאר המודולים (ביטוחים/רישיונות/חוגים/חשבונות/מסמכים - **לא** כולל רכבים, כי הוא כבר נגיש דרך טאב "בית").
- **נשמרו ללא שינוי:** הזמנת בן/בת זוג (קוד), שיתוף כללי לאפליקציה (וואטסאפ/מייל), החלפת household - כולם בתוך ה-shell הקבוע.
- **נוסף:** דיאלוג אישור לפני התנתקות ("להתנתק? תצטרך להתחבר שוב") - לא היה קיים קודם, ההתנתקות הייתה מיידית בלי אישור.
- `lib/features/home/home_modules.dart` — `buildFeaturedModules()` סודר מחדש לסדר קניות/לוח שנה/משימות/רכבים (תואם את סדר הטאבים).
- `lib/app/household_gate.dart` — מצביע עכשיו על `MainShellScreen` במקום `HomeScreen`.

### פיצ'ר אמיתי ראשון: ועד בית (חשבונות)
- **תשתית חדשה: Firebase Storage** - נוסף `firebase_storage` ל-`pubspec.yaml`, קובץ `storage.rules` חדש (בדיקת חברות ב-household דרך `firestore.get()`, תואם ל-`firestore.rules`), ו-`firebase.json` עודכן עם מקטע `storage`.
- **החלטת עיצוב מכוונת:** **בלי** זיהוי אוטומטי של תקופת התשלום מתוך הקבלה (OCR/AI) - לא אמין מספיק (פורמטים שונים לגמרי בין ספקים). המשתמש **תמיד בוחר ידנית** לאיזו תקופה שייכת קבלה.
- `lib/models/bill_payment_model.dart` — `BillCategory` enum (vaadBayit/electricity/waterAndTax - רק הראשון פעיל כרגע), `BillPayment` עם תקופה (year+periodStartMonth), סכום, אמצעי תשלום, קובץ קבלה.
- `lib/services/files/file_picker_service.dart` (+web/stub) — בחירת קובץ (PDF/תמונה) מהדיסק, אותה תבנית conditional-export כמו שירותי ההתראות/שיתוף.
- `lib/services/firebase/receipt_storage_service.dart` — העלאת קובץ ל-Storage, מחזיר URL.
- `lib/services/firebase/bills_service.dart`, `lib/repositories/bills_repository.dart`, `lib/providers/bills_provider.dart` — CRUD ב-Firestore לרשומות תשלום; מזהה מסמך קבוע (למשל `vaadBayit_2026_9`) כדי לתמוך ב-get-or-create בלי חיפוש מקדים.
- `lib/features/bills/vaad_bayit_screen.dart` — טבלת 12 חודשי השנה הנוכחית, כל שורה מראה שולם/לא שולם. לחיצה פותחת חלונית: הזנת סכום, בחירת אמצעי תשלום (ביט/פייבוקס/העברה בנקאית/מזומן/אחר), והעלאת קבלה - **העלאת קבלה מסמנת אוטומטית את התקופה כ"שולם"**.
- `lib/features/home/tabs/home_tab_content.dart` — נוסף כרטיס רחב "חשבונות" מתחת לרשת 4 החלונות, עם 3 עמודות: ועד בית (פעיל, מוביל למסך הטבלה), חשמל ומים+ארנונה (עדיין "בקרוב" - שלב הבא בעתיד, לפי בחירת המשתמש להתחיל רק עם ועד בית).
- **פעולה נדרשת מהמשתמש לפני שזה יעבוד:** להפעיל Firebase Storage בקונסולה (Databases & Storage → Storage → Get started) ולפרוס את storage.rules (`firebase deploy --only storage`).

### עדכון קריטי: בוטל Firebase Storage לגמרי, קבלות נשמרות ב-Firestore (base64)
- **התגלה באמצע הפיתוח:** מאז פברואר 2026, גוגל דורשת Blaze **תמיד** לשימוש ב-Firebase Storage, גם ב-$0 בפועל - אין יותר "שכבה חינמית" אמיתית ל-Storage כמו שהייתה קודם. זו מדיניות שונה לגמרי מהמקרה של Push Notifications (שם היה אפשר לעקוף עם Cloud Functions/Blaze נמנע).
- **ההחלטה:** במקום Blaze, קבלות (תמונה/PDF) מקודדות ל-**base64** ונשמרות **ישירות בתוך מסמך Firestore** (שכבר בשימוש, חינמי, בלי Blaze). **בוטלו לגמרי:** `firebase_storage` מ-`pubspec.yaml`, `storage.rules`, ה-`storage` block ב-`firebase.json`, וקובץ `receipt_storage_service.dart`.
- **מגבלה מודעת:** Firestore מגביל מסמך ל-1MB; קובץ גולמי מוגבל ל-**700KB** (base64 מנפח ~33%, נשאר מרווח בטוח). קבצים גדולים יותר נדחים עם הודעת שגיאה ברורה שמנחה לצלם שוב באיכות נמוכה יותר. מתאים היטב לתמונה אחת (צילום קבלה/צילום מסך מביט) - **לא** מתאים ל-PDF רב-עמודים כבד.
- `lib/models/bill_payment_model.dart` — `receiptUrl` הוחלף ב-`receiptData` (base64) + `receiptMimeType`. `isPaid` בודק `receiptData != null` במקום `receiptUrl != null`.
- **ממשק ה-UI לא השתנה בכלל** (`vaad_bayit_screen.dart`, `bill_period_table_screen.dart`) - קריאות ל-`uploadReceiptAndMarkPaid()` נשארו זהות; רק המימוש הפנימי ב-repository השתנה משליחה ל-Storage לקידוד base64 ישיר.
- **לא נבנה עדיין:** תצוגה חוזרת של הקבלה (פתיחה/הצגה של התמונה שהועלתה) - כרגע רק מסומן "קבלה הועלתה: שם קובץ", אין preview. שיפור אפשרי לעתיד: `Image.memory(base64Decode(...))`.

### תיקוני מעקב אחר משוב ראשוני
- **תוקן באג קריטי:** לחיצה על "שלם עכשיו" הייתה מאפסת את כל אפליקציית ה-Flutter (הדפדפן ניווט את **אותו** חלון לאתר החיצוני). התיקון: `url_launcher`'s `launchUrl(..., webOnlyWindowName: '_blank')` - פותח כרטיסייה **חדשה**, לא מנווט את הקיימת.
- **חשמל:** הוסר לגמרי שדה "אמצעי תשלום" (ביט/פייבוקס/וכו') מחלונית העריכה - נשאר רק סכום + העלאת קבלה, כי חשמל תמיד משולם דרך אתר החברה, לא "שיטת" תשלום. יושם דרך פרמטר חדש `showPaymentMethod` ב-`BillPeriodEditSheet`/`BillPeriodTableScreen` (ברירת מחדל `true`, `false` רק לחשמל).
- **נוספה עריכת קישור** לכל המסכים (חשמל, מים+ארנונה בשני המצבים) - אייקון עיפרון ב-AppBar פותח דיאלוג עם השדה כבר ממולא בקישור הקיים, שמירה מעדכנת.
- **נוסף קישור תשלום אופציונלי גם לועד בית** (`vaadBayitUrl`) - בשונה מחשמל/מים, זה **לא חוסם** את הטבלה (אין מסך "הגדרה חד-פעמית" מכריח) - מוצג כפתור "הוסף קישור תשלום" קטן למעלה אם עוד לא הוגדר, או "שלם עכשיו"+עריכה אם כן. שימושי למי שמשלם לוועד דרך קישור תשלום קבוע (ביט/פייבוקס לטלפון של הגזבר, למשל).
- `vaad_bayit_screen.dart` עבר ריפקטור: הוסרה הכפילות (`_MonthEditSheet` הפרטי) לטובת שימוש ב-`BillPeriodEditSheet` המשותף - הניקיון שצוין קודם כ"אפשרי לעתיד" בוצע בפועל.

### עדכון נוסף: ביט/פייבוקס פותחים את האפליקציה בפועל
- **שונה מהגישה הקודמת** (כפתור "הוסף קישור תשלום" כללי למעלה במסך ועד בית) - **בוטל**. במקום זאת, ההתנהגות עברה **לתוך חלונית העריכה עצמה**: כשבוחרים "ביט" או "פייבוקס" מתוך רשימת אמצעי התשלום (רק אצל ועד בית - היחיד שעדיין מציג את הבחירה הזו), מופיע כפתור "פתח את ביט/פייבוקס" שפותח את הקישור השמור. בפעם הראשונה שבוחרים כל שיטה, נשאלים לקישור (וזה נשמר להבא) - ולכן יש שני קישורים נפרדים (`bitUrl`, `payboxUrl`) ב-`BillLinkSettings`, במקום קישור כללי אחד.
- **חשמל, מים, ארנונה (בכל הצורות) - `showPaymentMethod: false` עכשיו בכל מקום** - אין שום בחירת "אמצעי תשלום" (ביט/פייבוקס/וכו') אצלם בכלל, רק כפתור פתיחת האתר בכרטיסייה חדשה. זה תוקן במפורש עבור מים+ארנונה (בעדכון הקודם רק חשמל קיבל את זה, מים/ארנונה נשארו בטעות עם ברירת המחדל `true`).

### עדכון סופי לועד בית: כפתור "שלם עכשיו" יחיד במקום רשימה נפתחת
- **שונה שוב** לפי בקשה מפורשת - בוטלה לגמרי הרשימה הנפתחת של אמצעי תשלום בחלונית העריכה של ועד בית. במקומה: כפתור בודד **"שלם עכשיו"**, שבלחיצה פותח bottom sheet עם 3 אפשרויות: ביט / פייבוקס / מזומן.
- בחירת **ביט/פייבוקס** - שומר את אמצעי התשלום **וגם** פותח את הקישור השמור (שואל בפעם הראשונה, בדיוק כמו קודם).
- בחירת **מזומן** - רק שומר את אמצעי התשלום, בלי לנסות לפתוח שום קישור.
- לאחר הבחירה, מוצג טקסט קטן מתחת לכפתור עם השיטה שנבחרה (למשל "אמצעי תשלום: ביט"), לפני השמירה הסופית של הרשומה.

### תוקן: חסימת חלונות קופצים (popup blocker) + צפייה/מחיקת קבלות
- **הסיבה האמיתית שקישורי התשלום לא פתחו כרטיסייה חדשה:** דפדפנים חוסמים `window.open` אם יש **כל עיכוב** (כולל `await`) בין הלחיצה בפועל לפתיחה - `url_launcher` על Flutter Web נתקל בזה גם כשנראה שהקריאה "ישירה". **הוסר `url_launcher` לגמרי** מהפרויקט, הוחלף בקריאה סינכרונית ישירה ל-`dart:html`'s `window.open()` (`openPaymentLink()` הפכה מ-`Future<void>` ל-`void` רגיל).
- **לבחירת ביט/פייבוקס בועד בית**, המבנה שונה כך שפתיחת הקישור קורית **בתוך** ה-`onTap` של השורה שנלחצה בפועל (לפני ה-`await` של סגירת ה-bottom sheet), לא אחרי - זה שומר על "מחוות משתמש ישירה" מבחינת הדפדפן ומונע חסימה.
- **נוספה צפייה בקבלה** - כפתור "צפה בקבלה" בחלונית העריכה (כשכבר שולם) פותח דיאלוג עם `Image.memory` (לתמונות) או הודעה + שם קובץ (ל-PDF, שאין לו תצוגה מקדימה מובנית ב-Flutter בלי ספריה נוספת).
- **נוספה מחיקת קבלה** - כפתור "מחק קבלה" (`BillsService.deleteReceipt`) מאפס את שדות הקבלה ב-Firestore, מחזיר את התקופה למצב "לא שולם".
- **תוקן:** `upcomingShoppingDatesProvider` (התג המספרי על כרטיסיית "לוח שנה" ב-Dashboard) לא סינן רשימות ריקות, בניגוד לתיקון שכבר בוצע במקומות אחרים (מסך "קנייה נוכחית", כרטיס לוח השנה המפורט) - הוצג "8" במקום המספר האמיתי, כי נספרו גם רשימות-בדיקה ישנות בלי מוצרים. עודכן לאותה לוגיקת סינון (בודק גם `shoppingItemsProvider` לכל רשימה, לא רק תאריך).
- **נוסף:** אייקון עריכה (עיפרון) ליד ביט/פייבוקס בתפריט "שלם עכשיו" של ועד בית - מוצג רק אם כבר יש קישור שמור לאותה שיטה, מאפשר להחליף אותו בלי למחוק ולהתחיל מחדש.

### תוקן: באג טיימינג אמיתי + נוספה מחיקת קישור מפורשת
- **הסבר למה נראה כאילו "לא זוכר" קישור שכבר נשמר:** `billLinkSettingsProvider` (StreamProvider) לא היה מ-`watch` בשום מקום לפני שנפתחת חלונית התשלום - ב-Riverpod, provider כזה לא מתחיל להאזין ל-Firestore עד שמישהו עושה לו `watch`, כך ש-`ref.read(...).value` יכל להחזיר `null` **גם אם** בפועל קיים ערך שמור, סתם כי ה-listener עוד לא הספיק "להתעורר". **התיקון:** נוסף `ref.watch(billLinkSettingsProvider(...))` בתחילת ה-`build()` של `BillPeriodEditSheet`, כך שההאזנה כבר פעילה ברגע שהחלונית נפתחת.
- **נוספה יכולת מחיקה אמיתית**: בכל מסך עריכת קישור (חשמל, מים, ארנונה, ביט, פייבוקס) - אם משתמש **מרוקן** את השדה ולוחץ "שמור", זה נשמר כמחרוזת ריקה ב-Firestore, מה שגורם ל-`is...Configured` להחזיר `false` שוב ומחזיר את המסך למצב "עדיין לא הוגדר" - במקום להתעלם בשקט מערך ריק כמו קודם.
- **הערה חשובה שהוסברה למשתמש:** אין קישור "פתח סתם את ביט" אוניברסלי ומתועד רשמית ע"י הבנקים - חובה קישור אמיתי (מבקשת תשלום קונקרטית באפליקציה, למשל), שנשמר פעם אחת. זה לא "באג" בקוד - זו מגבלה אמיתית של האקוסיסטם.

### פישוט סופי: ברירות מחדל אמיתיות (Google Play) + "שולם" בשמירה
- **אחרי מסע חיפוש ארוך** (כולל בדיקת "קבוצות איסוף כספים" בביט/פייבוקס, שדורשות הקמת קבוצה מראש) - **הוחלט על הפתרון הפשוט ביותר**: קישורי ברירת מחדל קבועים לדפי האפליקציות ב-Google Play (`_kBitDefaultUrl`, `_kPayboxDefaultUrl`) - אם האפליקציה כבר מותקנת בטלפון, גוגל פליי מציג כפתור "פתח" ולא "התקן", כך שזה בפועל כמעט זהה לפתיחה ישירה, בלי תלות בקישור-משתמש שצריך למצוא/להזין.
- **אין יותר "שאלה בפעם הראשונה"** - הקישורים תמיד קיימים כברירת מחדל; אייקון העריכה עדיין זמין תמיד (לא רק כשיש כבר קישור מותאם אישית) למי שירצה לדרוס עם deep-link טוב יותר בעתיד (למשל אם יגלה שקיים `bit://`/`paybox://` בטלפון שלו - הוצע לו לבדוק זאת ידנית בדפדפן).
- **"שולם" כבר לא תלוי בהעלאת קבלה בלבד** - נוסף שדה `paidManually` (bool) ל-`BillPayment`. `isPaid` בודק `receiptData != null || paidManually`. `saveBillDetails()` מקבל פרמטר `markPaid` חדש; `BillPeriodEditSheet`/`BillPeriodTableScreen` מקבלים `markPaidOnSave` (ברירת מחדל `false`) - **רק ועד בית מפעיל את זה** (`true`), כך שלחיצה על "שמור" שם (עם סכום+אמצעי תשלום) מספיקה לסימון "שולם", בלי חובת קבלה. **חשמל/מים/ארנונה נשארו ללא שינוי** - עדיין דורשים קבלה בפועל לסימון "שולם", לפי ההבחנה המקורית בין הקטגוריות.
- **נוסף כפתור "בטל"** ליד "שמור" בחלונית העריכה (בכל הקטגוריות) - סוגר בלי לשמור.

### שינוי גדול: הוסר לגמרי מנגנון הקבלות, נוסף ביטול-בהחלקה
- **הוסר לחלוטין, לפי בקשה מפורשת:** כל מנגנון הקבלות - העלאה, צפייה, מחיקה. כולל: שדות `receiptData`/`receiptMimeType`/`receiptFileName` מ-`BillPayment`, `lib/services/files/` (כל התיקייה - `FilePickerService` היה משמש רק לזה), `BillsService.attachReceipt`/`deleteReceipt`, ו-`firebase_storage`/`file_picker` מה-imports.
- **"שולם" עכשיו תלוי אך ורק בשדה `paidManually`** - כל שמירה (בכל קטגוריה - ועד בית/חשמל/מים/ארנונה) מסמנת אוטומטית `paidManually: true`. אין יותר הבחנה בין קטגוריות לגבי "איך מסמנים שולם" - זה אחיד עכשיו.
- **נוסף ביטול תשלום בהחלקה (swipe)** - כל שורת חודש/תקופה עטופה ב-`Dismissible` (`DismissDirection.startToEnd`, פעיל רק אם `isPaid`). החלקה קוראת ל-`cancelPayment()` (מאפס `paidManually`+`paidAt`) ומחזירה `confirmDismiss: false` תמיד - השורה **לא** נעלמת מהרשימה, רק הסטטוס (החוג הירוק) משתנה. רקע אדום עם הטקסט "בטל תשלום" מוצג בזמן ההחלקה.
- שורות **לא-משולמות** אינן ניתנות להחלקה כלל (`DismissDirection.none`) - אין מה לבטל.

### נוסף: סריקת ברקוד לחשמל/מים/ארנונה (לא לועד בית)
- נוסף `mobile_scanner` (^6.0.2) כתלות - מאפשר סריקת ברקוד/QR דרך מצלמת המכשיר, כולל תמיכה ב-Flutter Web (מסתמך על ה-API של הדפדפן, נתמך היטב ב-Chrome).
- `lib/features/bills/barcode_scan_screen.dart` - מסך מצלמה חדש, מחזיר את הערך הנסרק בלבד (`Navigator.pop`) - **לא** מנסה "לפענח" סכום/פרטים מהברקוד עצמו, כי פורמטים של שוברי תשלום שונים מאוד בין ספקים (חברת חשמל/רשות מקומית/תאגיד מים) ופענוח אמין ידרוש טיפול ייעודי לכל ספק.
- נוסף `showBarcodeScan` (bool, ברירת מחדל `false`) ל-`BillPeriodTableScreen`/`BillPeriodEditSheet`, **מופעל רק** בחשמל ובמים/ארנונה (`electricity_screen.dart`, `water_and_tax_screen.dart`) - **לא** בועד בית (שם יש כבר את בחירת ביט/פייבוקס/מזומן, וברקוד לא רלוונטי לתשלום בין אנשים).
- כפתור "סרוק ברקוד משובר תשלום" מוצג **בנוסף** לכפתור "שלם עכשיו" (האתר) - שתי אפשרויות משלימות, לא סותרות. לאחר סריקה מוצלחת, אמצעי התשלום מסומן כ"נסרק מברקוד" ומוצג למשתמש (הצגת "אמצעי תשלום" הופרדה מ-`showPaymentMethod` הישן, כדי שתעבוד גם כשהבחירה מגיעה מסריקה ולא מה-Pay Now chooser).

### תוקן: ביטול תשלום מנקה גם את הסכום, לא רק את הסימון
- `BillsService.cancelPayment()` עודכן לאפס גם `amount` ו-`paymentMethod` (לא רק `paidManually`/`paidAt`) - השורה חוזרת למראה "ריק לגמרי" אחרי ביטול, לא רק "לא שולם עם מחיר ישן עדיין מוצג". חל אוטומטית על **כל** הקטגוריות (ועד בית/חשמל/מים/ארנונה), כי זו פונקציה משותפת אחת.
- **הבהרה:** ההחלקה-לביטול (`Dismissible`) כבר הייתה קיימת גם בחשמל **וגם** במים/ארנונה מההתחלה - שלושתם חולקים את אותו קומפוננטה (`BillPeriodTableScreen`), אז אין צורך "להוסיף" אותה בנפרד לכל קטגוריה.

### נוסף: תזכורת תשלום (תאריך+שעה) לכל קטגוריות החשבונות
- **אותה מגבלה שכבר הוסברה למשתמש עם התראות קניות:** תזכורת תעבוד רק אם האפליקציה פתוחה (גם ברקע) בזמן שהיא אמורה "לצלצל" - אין שרת שמפעיל את זה כשהאפליקציה סגורה (זו הייתה בחירה מודעת של המשתמש נגד Blaze).
- `BillPayment` הורחב עם `reminderAt` (DateTime?) ו-`reminderShown` (bool) - נשמרים על אותו מסמך תקופה שכבר קיים.
- `BillsService`/`BillsRepository`: `saveReminder()`, `clearReminder()`, `markReminderShown()`, ו-`watchAllReminders()` (שאילתה על כל הקטגוריות ביחד לפי `reminderAt != null`, מסננת `reminderShown` בצד הלקוח כדי להימנע מ-composite index ב-Firestore).
- `lib/features/bills/bill_reminder_listener.dart` - widget "שקוף" חדש (בדומה ל-`ShoppingNotificationsListener`), עוטף את כל האפליקציה דרך `household_gate.dart`. משתמש ב-`Timer.periodic` (כל 60 שניות) שבודק אם הגיע זמנה של תזכורת כלשהי, ואם כן - מציג התראת דפדפן ומסמן `reminderShown: true` כדי לא לחזור על עצמה.
- ב-`BillPeriodEditSheet` (המשותפת לכל הקטגוריות, כולל ועד בית) - נוסף כפתור "הוסף תזכורת לתשלום", פותח `showDatePicker`+`showTimePicker` רגילים של Flutter, עם בדיקה שהתאריך/שעה שנבחרו לא כבר עברו. לאחר הגדרה, מוצג התאריך+שעה עם אפשרויות "ערוך"/"בטל".
- **תוקן:** `saveBillDetails()` סימן "שולם" (`paidManually: true`) **בכל** שמירה, גם אם לא הוזן סכום (למשל כשרק שומרים תזכורת ואז לוחצים "שמור" בסוף) - עכשיו מסמן שולם **רק אם `amount != null`**, כלומר רק אם המשתמש באמת הזין סכום.

### תזכורות תשלום מוצגות גם בלוח השנה (לא רק כהתראה)
- **לפי בקשה מפורשת: שני המנגנונים ביחד**, לא אחד-או-השני - גם התראת דפדפן (Timer, דורש אפליקציה פתוחה) **וגם** הופעה חזותית בלוח השנה (אמינה יותר - לא תלויה בתזמון מדויק).
- `BillsService.watchAllScheduledReminders()` - כמו `watchAllReminders()` אבל **בלי** לסנן `reminderShown`, כי בלוח השנה רוצים להמשיך להראות תזכורת גם אחרי שההתראה כבר "צלצלה" פעם.
- `billCategoryDisplayName()` נוסף ל-`bill_payment_model.dart` - שם עברי קצר לכל קטגוריה (ועד בית/חשמל/מים/ארנונה/מים וארנונה), לתצוגה בלוח השנה.
- `lib/features/home/tabs/calendar_tab_content.dart` עודכן - משלב תזכורות תשלום **לצד** תאריכי רשימות קניות (לא מחליף): מסמן ימים בלוח החודשי, מופיע ב"אירועים קרובים" (3 ימים), ומופיע בפירוט היום הנבחר - עם אייקון "alarm" נפרד (כתום) כדי להבדיל חזותית מ"קניות" (כחול).

### הרחבה: חשמל + מים/ארנונה (קישור תשלום, בלי ניחוש עיר)
- **נדחתה בכוונה** האפשרות "בחר עיר → אתר אוטומטי" - אין מאגר אמין של מאות רשויות מקומיות שאפשר לשמור בקוד בלי שיתיישן/יהיה לא מדויק. **נבחרה הגדרה חד-פעמית ידנית** במקום.
- `lib/models/bill_link_settings_model.dart` + `lib/services/firebase/bill_settings_service.dart` — הגדרות קישורי תשלום, נשמר במסמך יחיד `households/{id}/settings/billLinks`. חשמל תמיד נפרד; מים+ארנונה עם דגל `waterAndTaxCombined` (יחד = קישור אחד, בנפרד = שני קישורים+שתי טבלאות עצמאיות).
- `lib/models/bill_payment_model.dart` — `BillCategory` הורחב עם `water` ו-`tax` (לתמיכה במקרה "בנפרד").
- `lib/features/bills/bill_period_table_screen.dart` — מסך טבלה **גנרי** (חודשיים, 6 תקופות בשנה), בשימוש חוזר לחשמל/מים/ארנונה/מים+ארנונה-ביחד. **הערה לניקיון עתידי:** `vaad_bayit_screen.dart` (חודשי) לא עבר ריפקטור לשימוש בקומפוננטה המשותפת - יש כפילות קוד מכוונת כדי לא לסכן קוד שכבר עבד, ניתן לאחד בעתיד.
- `lib/features/bills/electricity_screen.dart`, `lib/features/bills/water_and_tax_screen.dart` — בפעם הראשונה מציגים טופס הגדרה (URL בלבד לחשמל; שאלת יחד/בנפרד + URL/ים למים+ארנונה), אחר כך תמיד מציגים ישר את הטבלה + כפתור "שלם עכשיו" שפותח את הקישור השמור (`url_launcher`, נוסף כתלות חדשה).
- `lib/features/home/tabs/home_tab_content.dart` — כרטיס "חשבונות" עודכן: **כל שלוש** העמודות (ועד בית/חשמל/מים+ארנונה) פעילות עכשיו.
- **תוקן:** מייל חסר לחברי household ישנים - `ensureMemberEmail()` "מתקן" ברקע את שדה ה-email של המשתמש הנוכחי בכל כניסה לאפליקציה (ב-`household_gate.dart`), כך שגם households שנוצרו לפני הוספת השדה מתמלאים בהדרגה (כל משתמש מתקן את הרשומה של עצמו בכניסה הבאה שלו).
- **הערה אופציונלית לכל מוצר** — שדה `note` נוסף ל-`ShoppingItem`, זמין בטופס ההוספה/עריכה (שדה טקסט רב-שורות, אופציונלי), ומוצג בכרטיס המוצר ברשימה בפונט נטוי מתחת לפרטים הרגילים (רק אם קיים).

### שיתוף (WhatsApp/Email)
- `lib/services/sharing/share_service.dart` (+ web/stub) — שיתוף ישיר דרך קישורי `wa.me`/`mailto`, אותו תבנית conditional-export כמו שירות ההתראות.
- `lib/app/config/app_config.dart` — נוסף `AppConfig.publicUrl` (כתובת ה-Hosting הקבועה), כדי שהודעות שיתוף תמיד יפנו לכתובת היציבה, לא לכתובת הזמנית של ה-Codespace.
- **שני שימושים נפרדים, בכוונה:**
  1. `invite_partner_screen.dart` — שיתוף **קוד הזמנה ל-household קיים** (כולל הקוד הספציפי בהודעה).
  2. `home_screen.dart` (כפתור שיתוף ב-AppBar) — הזמנה **כללית** לאפליקציה, בלי שום קוד household, מיועד לחברים שירצו ליצור household **משלהם**.

### תמיכה בכמה Households למשתמש אחד
- `lib/providers/household_provider.dart` — נוספו `myHouseholdsProvider` (Stream<List<Household>>, כל ה-households), `selectedHouseholdIdProvider` (StateProvider, "פעיל כרגע", לא persist בין sessions), ו-`currentHouseholdProvider` (Household? בפועל - הנבחר, או הראשון כברירת מחדל).
- `lib/services/firebase/household_service.dart`, `lib/repositories/household_repository.dart` — נוסף `watchMyHouseholds()` (אותה שאילתה כמו הישן, רק בלי `.limit(1)`).
- `lib/app/household_gate.dart` עודכן — משתמש ב-`myHouseholdsProvider`; אם ריק → מסך יצירה/הצטרפות; אחרת → `currentHouseholdProvider` (מטפל גם ב"מצב ביניים" רגעי לפני שהבחירה מתייצבת).
- `lib/features/household/add_household_screen.dart` — מסך חדש (בשונה מ-`create_household_screen.dart` שמשמש רק כ"שער" הראשוני): נפתח כ-push רגיל עם כפתור חזרה, מיועד להוספת household **נוסף** כשכבר יש לפחות אחד. בהצלחה, בוחר אוטומטית את ה-household החדש כ"פעיל" (`selectedHouseholdIdProvider`) וסוגר את המסך.
- `lib/features/home/home_screen.dart` עודכן — שם ה-household בכרטיסייה העליונה הפך ללחיץ (עם אייקון ⇕ קטן), פותח bottom sheet עם רשימת כל ה-households (רדיו-בחירה) + כפתור "הצטרף/צור משק בית נוסף".
- **החלטה:** בחירת ה-household הפעיל נשמרת רק בזיכרון (לא ב-Firestore/local storage) - מתאפסת לברירת המחדל (household ראשון) בכל טעינה מחדש של האפליקציה. זה מספיק ל-MVP; אם יתברר שזה מציק, אפשר להוסיף persist מקומי (shared_preferences) בעתיד.

### מחיקת Household
- `lib/services/firebase/household_service.dart` — `deleteHousehold()` מוחק באופן ידני ורקורסיבי את כל תת-האוספים (members, shoppingLists+items+sessions, shoppingHistory) ולבסוף את מסמך ה-household עצמו. Firestore לא מוחק subcollections אוטומטית.
- **הגבלת הרשאה מכוונת - שונה מהסרת חבר:** בעוד שכל חבר יכול להסיר חבר אחר, מחיקת household **שלם** מוגבלת רק ל-`createdBy` (הבעלים המקורי) - גם ב-UI (`isOwner` מוזרק מ-`home_screen.dart`) וגם ב-Security Rules (`allow delete: if request.auth.uid == resource.data.createdBy`). זו פעולה הרסנית משמעותית יותר מהסרת חבר בודד.
- כפתור "מחק משק בית" מופיע בתחתית `household_members_screen.dart`, רק אם `isOwner == true`, עם דיאלוג אישור מפורש.

### פירוט קנייה בהיסטוריה
- `lib/models/shopping_history_model.dart` הורחב — נוספו `purchasedItemNames`, `carriedOverItemNames`, `droppedItemNames` (מפרידים בין "הועבר לקנייה הבאה" ל"נמחק", מה שלא היה קיים קודם - `notFoundItemNames` הישן שילב את שניהם יחד).
- `lib/services/firebase/shopping_service.dart` — `finishShopping()` שומר עכשיו את הפירוט המלא, לא רק ספירות.
- `lib/features/shopping/shopping_history_detail_screen.dart` — מסך חדש: לחיצה על קנייה בהיסטוריה פותחת אותו, מציג 3 קטגוריות (נקנו / לא נמצאו-הועברו / לא נמצאו-נמחקו) עם רשימת שמות מלאה בכל אחת.
- **תמיכה לאחור:** רשומות היסטוריה ישנות (לפני העדכון) לא יכילו את 3 השדות החדשים - המסך מזהה זאת אוטומטית ונופל חזרה להצגת `notFoundItemNames` הישן כקטגוריה כללית אחת.

### עדכון מיתוג - לוגו וצבעים כחולים
- **החלטת המשתמש:** מעבר מירוק לכחול (`#00A3DA` עם גרדיאנט לכהה יותר `#0075AA`), בהתאם ללוגו "Smart Home" (בית + גל Wi-Fi) שהמשתמש בחר.
- `lib/app/config/app_colors.dart` — `primary` שונה לכחול, נוסף `primaryDark` לגרדיאנטים. **צבעים סמנטיים נשארו כפי שהיו במכוון:** `itemPurchased` (ירוק - הצלחה) ו-`itemNotFound` (כתום - אזהרה) לא השתנו, כי אלה משמעות קבועה ולא צבעי מותג. `itemNewBadge` שונה לסגול (היה כחול) כדי לא להתבלבל עם הכחול הראשי החדש.
- הבאנרים הירוקים ב-`login_screen.dart`, `create_household_screen.dart`, `home_screen.dart` הפכו לגרדיאנט (primary→primaryDark) במקום צבע שטוח, בהשראת הגרדיאנט שבלוגו המקורי.
- אייקוני האפליקציה (`web/icons/*.png`, `web/favicon.png`) הוחלפו בלוגו "בית + Wi-Fi" כחול, נוצר עם Python/Pillow בהתאמה לצבעים המדויקים מהתמונה שהמשתמש שלח.
- **שיפור עיצוב עדין ("קצת יותר מגניב, לא יותר מדי"):** `app.dart` - עודכן ה-theme הכללי: כפתורים עם צל עדין (elevation), פינות מעוגלות יותר (14 במקום 12), שדות טופס עם border ברור ו-focus כחול, snackbar מעוגל. `splash_screen.dart` - רקע גרדיאנט (היה צבע שטוח). `home_screen.dart` - אריחי המודולים קיבלו צל עדין ורקע גרדיאנט קליל לאייקון (היה צבע שטוח אחיד).
- **תוקן באג ארכיטקטוני:** ההאזנה להתראות עברה מ-`shopping_list_screen.dart` (שם היא פעלה **רק** כשמסך רשימת הקניות עצמו היה פתוח) ל-`lib/features/shopping/shopping_notifications_listener.dart` - widget "שקוף" (בלי UI משלו) שעוטף את כל האפליקציה דרך `household_gate.dart` ברגע שיש household. עכשיו ההתראות פועלות בכל מסך באפליקציה (Dashboard, היסטוריה וכו'), כל עוד הטאב פתוח - לא רק כשנמצאים ספציפית ברשימת הקניות.

### שכחת סיסמה (Login)
- `lib/services/firebase/firebase_auth_service.dart`, `lib/repositories/auth_repository.dart` — נוסף `sendPasswordResetEmail()`.
- `lib/features/auth/login_screen.dart` — קישור "שכחת סיסמה?" שפותח דיאלוג להזנת אימייל (מלא מראש משדה האימייל בטופס אם כבר הוזן), שולח קישור איפוס דרך Firebase Auth.

### ניהול חברי Household
- `lib/models/household_member_model.dart` — נוסף שדה `email` (לא היה קיים קודם - היה רק role+joinedAt, בלי דרך להציג את זהות החבר בפועל).
- `lib/services/firebase/household_service.dart` — `createHousehold`/`joinHousehold` מקבלים כעת גם email ושומרים אותו על מסמך ה-member. נוספו `watchMembers()` ו-`removeMember()` (batch: מוחק את מסמך החברות + מוציא מ-memberIds).
- `lib/features/household/household_members_screen.dart` — מסך חדש: רשימת חברים עם email, תפקיד (בעלים/חבר), וכפתור הסרה לכל חבר חוץ מעצמך.
- `firestore.rules` עודכן — `allow delete` על מסמך `members/{memberId}` שונה מ-`false` ל-`isHouseholdMember(householdId)`, כדי לאפשר הסרת חברים.
- **החלטת הרשאות:** כל חבר יכול להסיר כל חבר אחר (כולל את מי שיצר את ה-household) - פשטות מכוונת למשק בית משפחתי קטן, לא היררכיית תפקידים מורכבת. אין עדיין פיצ'ר "עזיבה עצמית" (לא ניתן להסיר את עצמך מהמסך הזה).
- גישה למסך: לחיצה על "X חברים במשק הבית" בכרטיסיית ה-household במסך הבית (הפך ללחיץ, עם קו תחתון).

### Firebase Hosting - כתובת קבועה
- `firebase.json` עודכן עם קונפיגורציית `hosting` (public: `build/web`, rewrite ל-SPA).
- נפרס בהצלחה עם `flutter build web` + `firebase deploy --only hosting` - כתובת קבועה: `https://home-manager-9407a.web.app`.
- **הבדל חשוב מ-`flutter run`:** זו "תמונת מצב קפואה", לא live-reload. כל שינוי עתידי בקוד דורש בנייה ופריסה מחדש (`flutter build web` + `firebase deploy --only hosting`) כדי להתעדכן בכתובת הציבורית. שימושי לשיתוף עם משתמשים אחרים (לא רק לבדיקות פיתוח).

### דרישות מתועדות לשלב 8 (Push Notifications) - מהמשתמש
1. **בזמן קנייה פעילה:** כשמוסיפים מוצר, שאר חברי ה-household (לא כולל מי שהוסיף) מקבלים Push "🔔 מוצר חדש נוסף".
2. **בסיום קנייה:** Push נוסף לשאר החברים עם רשימת `notFoundItemNames` (כבר נשמר בהיסטוריה) - "🛒 הקנייה הסתיימה, לא נמצאו: X, Y".
3. **כלל מפתח:** הנמען תמיד "חברי ה-household חוץ מהמשתמש שביצע את הפעולה" - לא כולם, ולא רק מי שהתחיל את ה-session. אצל household עם 2 חברים (המקרה הנפוץ), זה תמיד "הצד השני".
4. שני סוגי ההתראות ישתמשו באותה תשתית Cloud Function גנרית, מובחנות ע"י `type` בפיילוד - כפי שכבר תוכנן בארכיטקטורה המקורית.

### Shopping Completion + History (שלב 9)
- `lib/models/shopping_history_model.dart` — רשומת סיכום קנייה (תאריך, סה"כ מוצרים, כמה נקנו, כמה לא נמצאו, שמות המוצרים שלא נמצאו).
- `lib/services/firebase/shopping_service.dart` — `finishShopping()` מבצע הכל ב-**WriteBatch אחד אטומי**: מוחק פריטים שנקנו, מטפל בפריטים שלא נמצאו (מחזיר ל"ממתין" את מה שסומן להעברה, מוחק את השאר), ושומר רשומת היסטוריה. גם `watchHistory()` (stream, ordered by date).
- `lib/features/shopping/shopping_summary_screen.dart` — מסך סיכום: סטטיסטיקות (סה"כ/נקנו/לא נמצאו), רשימת "לא נמצאו" עם checkbox לכל פריט (ברירת מחדל: מסומן = יועבר לקנייה הבאה) + כפתורי "בחר הכל"/"נקה הכל", ורשימת "נקנו" למידע.
- `lib/features/shopping/shopping_history_screen.dart` — רשימת קניות עבר, פורמט "תאריך - X מוצרים - Y נקנו - Z לא נמצאו".
- `lib/features/shopping/shopping_list_screen.dart` עודכן — 2 כפתורים חדשים ב-AppBar: היסטוריה (🕐) וסיום קנייה (✓✓, מושבת אם אין פריטים שנקנו/לא נמצאו).

### Home Dashboard - עיצוב מחדש
- `lib/features/home/home_module.dart` — מודל `HomeModule` (title, subtitle, icon, isAvailable, screenBuilder).
- `lib/features/home/home_modules.dart` — **המקום היחיד** להוספת מודולים עתידיים (רכבים, ביטוחים, רישיונות, חוגים, חשבונות, מסמכים, משימות/תזכורות). מודול חדש = תוספת אחת ברשימה כאן, לא צריך לגעת ב-home_screen.dart.
- `lib/features/home/home_screen.dart` עוצב מחדש כ-Dashboard: כרטיסיית household עליונה (שם, מספר חברים, כפתור הזמנה עגול), ומתחתיה רשת (grid) של אריחי מודולים - "רשימת קניות" פעיל ולחיץ, שאר המודולים מוצגים מעומעמים עם תווית "בקרוב".

---

## מה עדיין לא עובד / לא קיים
- טרם נבדק בפועל: שכחת סיסמה, ניהול/הסרת חברים.
- **מגבלה ידועה:** ההתראות עובדות רק כשהאפליקציה פתוחה (טאב פתוח, גם ברקע) - לא כשהיא סגורה לגמרי. זו החלטה מודעת (ר' החלטות ארכיטקטוניות).
- אין פיצ'ר "עזיבת household" עצמית (אפשר רק שמישהו אחר יסיר אותך).
- household-ים ישנים (שנוצרו/הצטרפו לפני העדכון הזה) לא יציגו email במסך ניהול החברים - השדה לא היה קיים אז. לא נבנה migration script לזה.
- Android/iOS עדיין לא הוגדרו ב-flutterfire (רק Web).

## בעיה ידועה - Cache ישן בדפדפן על מכשירים נוספים
כשבודקים גרסה חדשה על מכשיר נוסף (טלפון וכו') שכבר ביקר בכתובת בעבר, הדפדפן עלול "לזכור" קובצי JavaScript ישנים (Flutter web service worker), מה שגורם לשגיאות כמו "משהו השתבש" גם כשהקוד בפועל תקין ועודכן. **פתרון:** לפתוח בחלון גלישה בסתר (Incognito/Private) בכל פעם שבודקים גרסה חדשה על מכשיר שכבר ביקר בכתובת.

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
10. **רשימה אחת בלבד ל-household ב-MVP** — `household.shoppingListId` נשמר ישירות על מסמך ה-household (ולא כשאילתה נפרדת), כדי לבטל כל race condition/צורך ביצירה כפולה. נוצרת אוטומטית בזמן `createHousehold`, ובאופן retroactive (lazy) עבור households ישנים יותר שנוצרו לפני השלב הזה.
11. **addedDuringShopping נכלל כבר עכשיו** — למרות ש"קנייה פעילה" היא שלב 7, השדה כבר קיים במודל (ברירת מחדל false) כדי להימנע ממיגרציית נתונים עתידית על מסמכים קיימים.
12. **מערכת מודולים לדף הבית (HomeModule)** — נבחרה כדי לממש את הדרישה "בעתיד להוסיף מודולים בלי לשכתב את האפליקציה" ברמת ה-UI, במקביל לעיקרון שכבר יושם ב-branding. כל מודול עתידי (ביטוחים, רישיונות, חוגים...) הוא רשומה אחת ב-`home_modules.dart`; אם `isAvailable: false` הוא מוצג "בקרוב" בלי מימוש בפועל. זה מאפשר "להראות" את חזון המוצר המלא במסך הבית מהיום הראשון.
13. **שלב 7 (Active Shopping) נבנה בנפרד משלב 8 (Push Notifications), בניגוד לכוונה הראשונית** — בזמן המימוש הסתבר ש-Push Notifications דורש שדרוג ל-Firebase Blaze plan (כרטיס אשראי) ופריסת Cloud Functions - החלטה משמעותית שראוי לאשר במפורש מול המשתמש לפני שמתחילים, ולא "לגלוש" אליה כחלק מ-session פיתוח רגיל. לכן שלב 7 (session state, UI, "חדש" badge) נבנה ונבדק באופן עצמאי; שלב 8 ימתין לאישור מפורש.
14. **finishShopping כ-WriteBatch אטומי** — כל הפעולות של סיום קנייה (מחיקת פריטים שנקנו, טיפול בלא-נמצאו, שמירת היסטוריה) מתבצעות ב-batch אחד, כדי שלא יהיה מצב ביניים לא עקבי (למשל: פריטים נמחקו אבל ההיסטוריה לא נשמרה) אם החיבור נופל באמצע.
15. **Push Notifications: חלופה חינמית מבוססת-לקוח, לא Cloud Functions** — המשתמש בחר במפורש להימנע משדרוג Blaze (דורש כרטיס אשראי, גם אם ללא חיוב צפוי בפועל). במקום זאת, האפליקציה מזהה שינויים חדשים ב-Firestore streams שכבר קיימים (אותו מנגנון של real-time sync) ומציגה Web Notification ישירות מהדפדפן. מגבלה מודעת: עובד רק כשהאפליקציה פתוחה. הקוד בנוי עם conditional export (web/stub) כך שאפשר להוסיף בעתיד מימוש Cloud Functions + FCM אמיתי (למובייל, ולכיסוי "אפליקציה סגורה") בלי לשכתב את השכבות הקיימות - רק להוסיף שכבה נוספת.

---

## הוראות הפעלה (למשתמש)
ראה קובץ `SETUP_INSTRUCTIONS.md` שנשלח יחד עם קבצי הפרויקט.

HMEOF
cat > 'lib/services/firebase/bills_service.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bill_payment_model.dart';

/// שירות Firestore לרשומות תשלום חשבונות (ועד בית/חשמל/מים+ארנונה).
/// כל רשומה מזוהה באמצעות מזהה קבוע (לא auto-id) - כך אפשר
/// לכתוב עליה מחדש (get-or-create) בלי לחפש קודם.
class BillsService {
  final FirebaseFirestore _firestore;

  BillsService(this._firestore);

  CollectionReference<Map<String, dynamic>> _billsCollection(String householdId) {
    return _firestore.collection('households').doc(householdId).collection('bills');
  }

  String _docId(BillCategory category, int year, int periodStartMonth) {
    return '${billCategoryToString(category)}_${year}_$periodStartMonth';
  }

  Stream<List<BillPayment>> watchBills({
    required String householdId,
    required BillCategory category,
    required int year,
  }) {
    return _billsCollection(householdId)
        .where('category', isEqualTo: billCategoryToString(category))
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BillPayment.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// שומר סכום+אמצעי תשלום, ותמיד מסמן את התקופה כ"שולם" (אין
  /// יותר מנגנון קבלות - השמירה עצמה היא אישור התשלום).
  /// שומר סכום+אמצעי תשלום. מסמן "שולם" (paidManually) **רק אם**
  /// הוזן סכום בפועל - שמירה בלי סכום (למשל רק כדי לשמור תזכורת)
  /// לא אמורה לסמן וי ירוק.
  Future<void> saveBillDetails({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
    double? amount,
    String? paymentMethod,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    final data = <String, dynamic>{
      'category': billCategoryToString(category),
      'year': year,
      'periodStartMonth': periodStartMonth,
      if (amount != null) 'amount': amount,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };
    if (amount != null) {
      data['paidManually'] = true;
      data['paidAt'] = FieldValue.serverTimestamp();
    }
    await _billsCollection(householdId).doc(id).set(data, SetOptions(merge: true));
  }

  /// מבטל תשלום שכבר סומן - מחזיר את התקופה למצב "לא שולם" (ה-חוג
  /// הירוק נעלם), **וגם מנקה את הסכום ואמצעי התשלום** (לא רק את
  /// סטטוס "שולם") - כך שהשורה חוזרת למראה "ריק לגמרי", לא רק
  /// "לא שולם עם סכום ישן שמור".
  Future<void> cancelPayment({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    await _billsCollection(householdId).doc(id).update({
      'paidManually': false,
      'paidAt': null,
      'amount': null,
      'paymentMethod': null,
    });
  }

  /// שומר תזכורת לתאריך+שעה עתידיים לתקופה מסוימת.
  Future<void> saveReminder({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
    required DateTime reminderAt,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    await _billsCollection(householdId).doc(id).set({
      'category': billCategoryToString(category),
      'year': year,
      'periodStartMonth': periodStartMonth,
      'reminderAt': Timestamp.fromDate(reminderAt),
      'reminderShown': false,
    }, SetOptions(merge: true));
  }

  Future<void> clearReminder({
    required String householdId,
    required BillCategory category,
    required int year,
    required int periodStartMonth,
  }) async {
    final id = _docId(category, year, periodStartMonth);
    await _billsCollection(householdId).doc(id).update({
      'reminderAt': null,
      'reminderShown': false,
    });
  }

  Future<void> markReminderShown({
    required String householdId,
    required String billDocId,
  }) async {
    await _billsCollection(householdId).doc(billDocId).update({'reminderShown': true});
  }

  /// כמו watchAllReminders, אבל **בלי** לסנן reminderShown - משמש
  /// לתצוגה בלוח השנה (רוצים להראות תזכורות גם אחרי שכבר "צלצלו").
  Stream<List<BillPayment>> watchAllScheduledReminders(String householdId) {
    return _billsCollection(householdId)
        .where('reminderAt', isNull: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BillPayment.fromFirestore(doc.id, doc.data())).toList());
  }

  /// מאזין לכל התזכורות שהוגדרו ב-household (בכל הקטגוריות יחד) -
  /// משמש כדי לבדוק ברקע אילו תזכורות "הגיע זמנן". הסינון של
  /// reminderShown נעשה בצד הלקוח (לא בשאילתה) כדי להימנע מהצורך
  /// ב-composite index ב-Firestore.
  Stream<List<BillPayment>> watchAllReminders(String householdId) {
    return _billsCollection(householdId)
        .where('reminderAt', isNull: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BillPayment.fromFirestore(doc.id, doc.data()))
            .where((bill) => !bill.reminderShown)
            .toList());
  }

  String billDocId(BillCategory category, int year, int periodStartMonth) =>
      _docId(category, year, periodStartMonth);
}

HMEOF
echo 'DONE - paid checkmark only shows when an amount is actually entered!'
