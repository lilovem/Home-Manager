#!/bin/bash
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
cat > 'lib/core/utils/product_categorizer.dart' << 'HMEOF'
import 'package:flutter/material.dart';

/// קטגוריות מוצרים אפשריות לרשימת קניות של הבית.
enum ProductCategory {
  produce,
  dairy,
  meatFishPoultry,
  bakery,
  frozen,
  pantry,
  spicesAndSauces,
  beverages,
  snacks,
  cleaning,
  toiletries,
  other,
}

/// מסווג מוצרים אוטומטית לקטגוריה, לפי מילות מפתח בשם המוצר.
///
/// זהו סיווג מבוסס טקסט (לא AI) - פשוט, צפוי, וניתן להרחבה בקלות
/// ע"י הוספת מילות מפתח ל-_keywords. אינו נשמר ב-Firestore בכוונה -
/// מחושב תמיד מחדש משם המוצר, כך שעריכת שם מוצר קיים מעדכנת
/// אוטומטית גם את הקטגוריה שלו.
class ProductCategorizer {
  ProductCategorizer._();

  static const Map<ProductCategory, String> categoryNames = {
    ProductCategory.produce: 'ירקות ופירות',
    ProductCategory.dairy: 'מוצרי חלב',
    ProductCategory.meatFishPoultry: 'בשר, עוף ודגים',
    ProductCategory.bakery: 'לחם ומאפים',
    ProductCategory.frozen: 'קפואים',
    ProductCategory.pantry: 'מזון יבש ושימורים',
    ProductCategory.spicesAndSauces: 'תבלינים ורטבים',
    ProductCategory.beverages: 'משקאות',
    ProductCategory.snacks: 'חטיפים וממתקים',
    ProductCategory.cleaning: 'ניקיון',
    ProductCategory.toiletries: 'טואלטיקה וטיפוח',
    ProductCategory.other: 'שונות',
  };

  /// סדר תצוגה קבוע - בערך לפי סדר מדפים אופייני בסופרמרקט.
  static const List<ProductCategory> displayOrder = [
    ProductCategory.produce,
    ProductCategory.dairy,
    ProductCategory.meatFishPoultry,
    ProductCategory.bakery,
    ProductCategory.frozen,
    ProductCategory.pantry,
    ProductCategory.spicesAndSauces,
    ProductCategory.beverages,
    ProductCategory.snacks,
    ProductCategory.cleaning,
    ProductCategory.toiletries,
    ProductCategory.other,
  ];

  /// אייקון קטן לכל קטגוריה, מוצג ליד שם המוצר ברשימה.
  static const Map<ProductCategory, IconData> categoryIcons = {
    ProductCategory.produce: Icons.eco_outlined,
    ProductCategory.dairy: Icons.icecream_outlined,
    ProductCategory.meatFishPoultry: Icons.set_meal_outlined,
    ProductCategory.bakery: Icons.bakery_dining_outlined,
    ProductCategory.frozen: Icons.ac_unit,
    ProductCategory.pantry: Icons.rice_bowl_outlined,
    ProductCategory.spicesAndSauces: Icons.liquor_outlined,
    ProductCategory.beverages: Icons.local_drink_outlined,
    ProductCategory.snacks: Icons.cookie_outlined,
    ProductCategory.cleaning: Icons.cleaning_services_outlined,
    ProductCategory.toiletries: Icons.soap_outlined,
    ProductCategory.other: Icons.shopping_bag_outlined,
  };

  static const Map<ProductCategory, List<String>> _keywords = {
    ProductCategory.dairy: [
      'חלב', 'גבינה', 'גבינת', 'יוגורט', 'קוטג', 'שמנת', 'חמאה',
      'לבן', 'מעדן', 'אשל', 'דנונה', 'קוטג\'', 'לאבנה', 'ריקוטה',
    ],
    ProductCategory.meatFishPoultry: [
      'עוף', 'בשר', 'דג', 'דגים', 'סלמון', 'טונה טרי', 'הודו',
      'נקניק', 'נקניקיה', 'קציצות', 'שניצל', 'סטייק', 'המבורגר',
      'כבד', 'פרגית', 'כרעיים', 'חזה עוף', 'טחון', 'צלעות',
    ],
    ProductCategory.produce: [
      'עגבני', 'מלפפון', 'תפוח', 'בננה', 'תפוז', 'חסה', 'גזר',
      'בצל', 'שום', 'פלפל', 'תפוח אדמה', 'תות', 'אבוקדו', 'לימון',
      'ירק', 'פרי', 'ענבים', 'קישוא', 'ברוקולי', 'כרובית', 'אבטיח',
      'מלון', 'אפרסק', 'שזיף', 'אגס', 'פטריות', 'כרוב', 'סלרי',
    ],
    ProductCategory.bakery: [
      'לחם', 'פיתה', 'בגט', 'חלה', 'לחמניה', 'עוגה', 'עוגיות',
      'קרואסון', 'בורקס', 'טוסט',
    ],
    ProductCategory.frozen: [
      'קפוא', 'קפואה', 'קפואים', 'גלידה', 'ופל',
    ],
    ProductCategory.pantry: [
      'אורז', 'פסטה', 'קמח', 'סוכר', 'שימורי', 'קטניות', 'עדשים',
      'שעועית', 'קורנפלקס', 'דגני בוקר', 'שמן', 'טחינה', 'חומוס יבש',
      'פתיתים', 'קוסקוס', 'בורגול',
    ],
    ProductCategory.spicesAndSauces: [
      'מלח', 'פלפל שחור', 'תבלין', 'רוטב', 'קטשופ', 'מיונז',
      'חרדל', 'סויה', 'שמן זית', 'חומץ', 'פפריקה', 'כמון',
    ],
    ProductCategory.beverages: [
      'מים', 'מיץ', 'קולה', 'סודה', 'בירה', 'יין', 'קפה', 'תה',
      'משקה', 'סיידר',
    ],
    ProductCategory.snacks: [
      'שוקולד', 'חטיף', 'במבה', 'ביסלי', 'צ\'יפס', 'סוכריות',
      'גומי', 'פופקורן', 'בוטנים', 'אגוזים',
    ],
    ProductCategory.cleaning: [
      'סבון כלים', 'אקונומיקה', 'מנקה', 'כביסה', 'מרכך', 'שקיות אשפה',
      'נייר סופג', 'ספוג', 'אבקת כביסה',
    ],
    ProductCategory.toiletries: [
      'שמפו', 'סבון', 'משחת שיניים', 'דאודורנט', 'נייר טואלט',
      'מגבונים', 'טיטול', 'פד', 'קרם', 'מברשת שיניים',
    ],
  };

  /// מזהה את הקטגוריה המתאימה ביותר לשם מוצר נתון.
  /// אם אין התאמה לאף מילת מפתח, מוחזרת הקטגוריה "שונות".
  static ProductCategory categorize(String productName) {
    final normalized = productName.trim();
    if (normalized.isEmpty) return ProductCategory.other;

    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        if (normalized.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return ProductCategory.other;
  }
}

HMEOF
cat > 'lib/providers/shopping_provider.dart' << 'HMEOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_history_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../repositories/shopping_repository.dart';
import '../services/firebase/shopping_service.dart';
import 'household_provider.dart';

final shoppingServiceProvider = Provider<ShoppingService>((ref) {
  return ShoppingService(ref.watch(firestoreProvider));
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(shoppingServiceProvider));
});

/// כל רשימות הקניות של household מסוים.
final shoppingListsProvider =
    StreamProvider.family<List<ShoppingList>, String>((ref, householdId) {
  return ref.watch(shoppingRepositoryProvider).watchLists(householdId);
});

/// מזהה הרשימה שיש לה כרגע session פעיל (אם יש) - בין כל הרשימות
/// של ה-household. משמש להאזנת התראות גלובלית (ShoppingNotificationsListener)
/// בלי לדעת מראש איזו רשימה ספציפית פעילה.
final activeSessionListIdProvider =
    Provider.family<String?, String>((ref, householdId) {
  final lists = ref.watch(shoppingListsProvider(householdId)).value ?? [];
  for (final list in lists) {
    if (list.activeSessionId != null) return list.id;
  }
  return null;
});

/// סך כל הפריטים ה"ממתינים" (עוד לא נקנו) בכל רשימות ה-household
/// יחד - משמש לתג המספר בכרטיסיית "קניות" ב-Dashboard.
final totalPendingItemsCountProvider = Provider.family<int, String>((ref, householdId) {
  final lists = ref.watch(shoppingListsProvider(householdId)).value ?? [];
  var count = 0;
  for (final list in lists) {
    final items =
        ref.watch(shoppingItemsProvider((householdId: householdId, listId: list.id))).value ??
            const [];
    count += items.where((i) => i.status == ItemStatus.pending).length;
  }
  return count;
});

/// רשימות קניות עם תאריך עתידי (או היום), ממוינות מהקרוב לרחוק -
/// משמש לכרטיסיית "לוח שנה" ב-Dashboard (מבוסס על תאריכים שכבר
/// קיימים במערכת, לא על מודול "לוח שנה" עצמאי).
final upcomingShoppingDatesProvider =
    Provider.family<List<ShoppingList>, String>((ref, householdId) {
  final lists = ref.watch(shoppingListsProvider(householdId)).value ?? [];
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);

  final upcoming = lists.where((l) => l.date != null && !l.date!.isBefore(todayStart)).toList();
  upcoming.sort((a, b) => a.date!.compareTo(b.date!));
  return upcoming;
});

/// פרמטרים ל-watch של פריטי רשימה מסוימת.
typedef ShoppingItemsArgs = ({String householdId, String listId});

final shoppingItemsProvider =
    StreamProvider.family<List<ShoppingItem>, ShoppingItemsArgs>((ref, args) {
  return ref
      .watch(shoppingRepositoryProvider)
      .watchItems(args.householdId, args.listId);
});

/// היסטוריית קניות של household מסוים.
final shoppingHistoryProvider =
    StreamProvider.family<List<ShoppingHistoryEntry>, String>((ref, householdId) {
  return ref.watch(shoppingRepositoryProvider).watchHistory(householdId);
});

/// מידע חי על הרשימה עצמה (כולל activeSessionId) - כדי שכל
/// חברי ה-household יראו מיידית כשקנייה פעילה מתחילה/מסתיימת.
final shoppingListMetaProvider =
    StreamProvider.family<ShoppingList, ShoppingItemsArgs>((ref, args) {
  return ref
      .watch(shoppingRepositoryProvider)
      .watchListMeta(args.householdId, args.listId);
});

HMEOF
cat > 'lib/features/shopping/shopping_list_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/product_categorizer.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../models/shopping_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_provider.dart';
import 'add_edit_product_screen.dart';
import 'shopping_history_screen.dart';
import 'shopping_summary_screen.dart';

/// מסך רשימת קניות ספציפית (יש כמה רשימות אפשריות ל-household,
/// זו מציגה תמיד רשימה אחת מסוימת לפי listId).
///
/// מציג את הפריטים בזמן אמת (StreamProvider), עם אפשרות
/// להוסיף/לערוך/למחוק/לשנות סטטוס - הכל מתעדכן מיידית אצל
/// כל חברי ה-household בזכות Firestore streams.
///
/// כולל גם מצב "קנייה פעילה": כשמישהו לוחץ "התחל קנייה", מוצג
/// באנר לכל חברי ה-household, וכל מוצר שנוסף בזמן הזה מסומן
/// "חדש" (addedDuringShopping). "סיום קנייה" סוגר את ה-session.
class ShoppingListScreen extends ConsumerWidget {
  final String householdId;
  final String listId;

  const ShoppingListScreen({
    super.key,
    required this.householdId,
    required this.listId,
  });

  Future<void> _openAddProduct(
    BuildContext context,
    WidgetRef ref,
    bool isSessionActive,
  ) async {
    final result = await Navigator.of(context).push<ProductFormResult>(
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    );
    if (result == null) return;

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    try {
      await ref.read(shoppingRepositoryProvider).addItem(
            householdId: householdId,
            listId: listId,
            name: result.name,
            quantity: result.quantity,
            unit: result.unit,
            addedBy: user.uid,
            addedByName: user.email ?? '',
            addedDuringShopping: isSessionActive,
            note: result.note,
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openEditProduct(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item,
  ) async {
    final result = await Navigator.of(context).push<ProductFormResult>(
      MaterialPageRoute(builder: (_) => AddEditProductScreen(existingItem: item)),
    );
    if (result == null) return;

    try {
      await ref.read(shoppingRepositoryProvider).updateItem(
            householdId: householdId,
            listId: listId,
            itemId: item.id,
            name: result.name,
            quantity: result.quantity,
            unit: result.unit,
            note: result.note,
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.confirmDeleteTitle),
        content: Text('"${item.name}" - ${AppStrings.confirmDeleteMessage}'),
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

    await ref.read(shoppingRepositoryProvider).deleteItem(
          householdId: householdId,
          listId: listId,
          itemId: item.id,
        );
  }

  Future<void> _setStatus(
    WidgetRef ref,
    ShoppingItem item,
    ItemStatus status,
  ) {
    return ref.read(shoppingRepositoryProvider).updateStatus(
          householdId: householdId,
          listId: listId,
          itemId: item.id,
          status: status,
        );
  }

  Future<void> _startShopping(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    try {
      await ref.read(shoppingRepositoryProvider).startShoppingSession(
            householdId: householdId,
            listId: listId,
            startedBy: user.uid,
            startedByName: user.email ?? '',
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openFinishShopping(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingItem> items,
    String? activeSessionId,
  ) async {
    final purchasedItems = items.where((i) => i.status == ItemStatus.purchased).toList();
    final notFoundItems = items.where((i) => i.status == ItemStatus.notFound).toList();

    if (purchasedItems.isEmpty && notFoundItems.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.nothingToFinish)));
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingSummaryScreen(
          householdId: householdId,
          listId: listId,
          purchasedItems: purchasedItems,
          notFoundItems: notFoundItems,
          totalItemsCount: items.length,
          activeSessionId: activeSessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingItemsProvider((householdId: householdId, listId: listId)));
    final currentItems = itemsAsync.value;

    final listMetaAsync =
        ref.watch(shoppingListMetaProvider((householdId: householdId, listId: listId)));
    final activeSessionId = listMetaAsync.value?.activeSessionId;
    final isSessionActive = activeSessionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(listMetaAsync.value?.name ?? AppStrings.shoppingList),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppStrings.shoppingHistory,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoppingHistoryScreen(householdId: householdId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: AppStrings.finishShopping,
            onPressed: currentItems == null
                ? null
                : () => _openFinishShopping(context, ref, currentItems, activeSessionId),
          ),
        ],
      ),
      body: Column(
        children: [
          // באנר קנייה פעילה / כפתור התחלת קנייה.
          isSessionActive
              ? Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.activeShoppingBanner,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: OutlinedButton.icon(
                    onPressed: () => _startShopping(context, ref),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(AppStrings.startShopping),
                  ),
                ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, st) => const ErrorView(),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    message: AppStrings.noItemsYet,
                    icon: Icons.shopping_cart_outlined,
                  );
                }

                // קיבוץ הפריטים לפי קטגוריה, בסדר תצוגה קבוע.
                // קטגוריה מוצגת רק אם יש בה לפחות פריט אחד.
                final itemsByCategory = <ProductCategory, List<ShoppingItem>>{};
                for (final item in items) {
                  itemsByCategory.putIfAbsent(item.category, () => []).add(item);
                }
                final categoriesToShow = ProductCategorizer.displayOrder
                    .where((category) => itemsByCategory.containsKey(category))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: categoriesToShow.length,
                  itemBuilder: (context, categoryIndex) {
                    final category = categoriesToShow[categoryIndex];
                    final categoryItems = itemsByCategory[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryHeader(category: category),
                        ...categoryItems.map(
                          (item) => Column(
                            children: [
                              _ShoppingItemTile(
                                item: item,
                                onTogglePurchased: () => _setStatus(
                                  ref,
                                  item,
                                  item.status == ItemStatus.purchased
                                      ? ItemStatus.pending
                                      : ItemStatus.purchased,
                                ),
                                onMarkNotFound: () =>
                                    _setStatus(ref, item, ItemStatus.notFound),
                                onBackToPending: () =>
                                    _setStatus(ref, item, ItemStatus.pending),
                                onEdit: () => _openEditProduct(context, ref, item),
                                onDelete: () => _confirmDelete(context, ref, item),
                              ),
                              const Divider(height: 1),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddProduct(context, ref, isSessionActive),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final ProductCategory category;

  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        ProductCategorizer.categoryNames[category] ?? '',
        style: AppTextStyles.heading2.copyWith(fontSize: 14, color: AppColors.primary),
      ),
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onTogglePurchased;
  final VoidCallback onMarkNotFound;
  final VoidCallback onBackToPending;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShoppingItemTile({
    required this.item,
    required this.onTogglePurchased,
    required this.onMarkNotFound,
    required this.onBackToPending,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (item.status) {
      case ItemStatus.purchased:
        return AppColors.itemPurchased;
      case ItemStatus.notFound:
        return AppColors.itemNotFound;
      case ItemStatus.pending:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantityText = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.round().toString()
        : item.quantity.toString();
    final unitText = item.unit != null ? ' ${item.unit}' : '';

    return ListTile(
      leading: Checkbox(
        value: item.status == ItemStatus.purchased,
        activeColor: AppColors.itemPurchased,
        onChanged: (_) => onTogglePurchased(),
      ),
      title: Row(
        children: [
          Icon(
            ProductCategorizer.categoryIcons[item.category],
            size: 18,
            color: _statusColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              item.name,
              style: AppTextStyles.body.copyWith(
                color: _statusColor,
                decoration:
                    item.status == ItemStatus.purchased ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (item.addedDuringShopping && item.status == ItemStatus.pending) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.itemNewBadge,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppStrings.newBadge,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$quantityText$unitText · ${AppStrings.addedByLabel} ${item.addedByName} · '
            '${DateFormatter.short(item.addedAt)}'
            '${item.status == ItemStatus.notFound ? ' · ${AppStrings.statusNotFound}' : ''}',
            style: AppTextStyles.bodySecondary,
          ),
          if (item.note != null && item.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.note!,
                style: AppTextStyles.bodySecondary.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'notFound':
              onMarkNotFound();
              break;
            case 'backToPending':
              onBackToPending();
              break;
            case 'edit':
              onEdit();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          if (item.status != ItemStatus.notFound)
            const PopupMenuItem(value: 'notFound', child: Text(AppStrings.markNotFound)),
          if (item.status != ItemStatus.pending)
            const PopupMenuItem(value: 'backToPending', child: Text(AppStrings.backToPending)),
          const PopupMenuItem(value: 'edit', child: Text(AppStrings.edit)),
          const PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
        ],
      ),
    );
  }
}

HMEOF
cat > 'lib/features/home/home_modules.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'home_module.dart';
import '../shopping/shopping_choice_screen.dart';

/// 4 המודולים ה"מומלצים" שמוצגים בכרטיסיות סטטיסטיקה צבעוניות
/// בראש מסך הבית (בהשראת עיצוב שהמשתמש שלח) - קניות (פעיל), ואז
/// משימות/רכבים/לוח שנה כ"בקרוב" (לוח שנה כן מציג נתון אמיתי,
/// המבוסס על תאריכי רשימות קניות קיימים - ראה home_screen.dart).
List<HomeModule> buildFeaturedModules({required String householdId}) {
  return [
    HomeModule(
      title: 'קניות',
      subtitle: 'פריטים ברשימה',
      icon: Icons.shopping_cart_outlined,
      isAvailable: true,
      screenBuilder: (_) => ShoppingChoiceScreen(householdId: householdId),
    ),
    const HomeModule(
      title: 'משימות',
      subtitle: 'ניהול משק הבית היומיומי',
      icon: Icons.checklist_outlined,
    ),
    const HomeModule(
      title: 'רכבים',
      subtitle: 'טסטים, טיפולים וקילומטראז\'',
      icon: Icons.directions_car_outlined,
    ),
    const HomeModule(
      title: 'לוח שנה',
      subtitle: 'אירועים קרובים',
      icon: Icons.calendar_month_outlined,
    ),
  ];
}

/// שאר מודולי העתיד - מוצגים ברשת הרגילה מתחת לכרטיסיות המומלצות,
/// כולם עדיין "בקרוב". כדי להוסיף מודול חדש בעתיד:
/// 1. בונים את המסך שלו תחת lib/features/<module_name>/
/// 2. מוסיפים כאן HomeModule עם isAvailable: true ו-screenBuilder מתאים
List<HomeModule> buildHomeModules({required String householdId}) {
  return const [
    HomeModule(
      title: 'ביטוחים',
      subtitle: 'פוליסות ותאריכי חידוש',
      icon: Icons.shield_outlined,
    ),
    HomeModule(
      title: 'רישיונות',
      subtitle: 'תעודות ומסמכים בעלי תוקף',
      icon: Icons.badge_outlined,
    ),
    HomeModule(
      title: 'חוגים',
      subtitle: 'פעילויות ולוחות זמנים',
      icon: Icons.sports_soccer_outlined,
    ),
    HomeModule(
      title: 'חשבונות',
      subtitle: 'חשמל, מים, ארנונה ומנויים',
      icon: Icons.receipt_long_outlined,
    ),
    HomeModule(
      title: 'מסמכים',
      subtitle: 'קבצים ותעודות חשובות',
      icon: Icons.folder_outlined,
    ),
  ];
}

HMEOF
cat > 'lib/features/home/home_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_config.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/shopping_list_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/share_provider.dart';
import '../../providers/shopping_provider.dart';
import '../household/add_household_screen.dart';
import '../household/household_members_screen.dart';
import '../household/invite_partner_screen.dart';
import 'home_module.dart';
import 'home_modules.dart';

/// מסך הבית הראשי - Dashboard.
///
/// מבנה: לוגו + באנר ברכה -> כרטיסיית household -> 4 כרטיסיות
/// סטטיסטיקה צבעוניות (קניות/משימות/רכבים/לוח שנה) -> כרטיס לוח
/// שנה עם אירועים קרובים -> רשת "בקרוב באפליקציה" לשאר המודולים.
///
/// כרטיסיית ה"קניות" וה"לוח שנה" מציגות נתונים אמיתיים (מבוססי
/// providers), לא מספרים מומצאים - "משימות" ו"רכבים" עדיין "בקרוב"
/// כי אין להם עדיין נתונים אמיתיים באפליקציה.
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

    final featured = buildFeaturedModules(householdId: household.id);
    final restModules = buildHomeModules(householdId: household.id);
    final pendingCount = ref.watch(totalPendingItemsCountProvider(household.id));
    final upcoming = ref.watch(upcomingShoppingDatesProvider(household.id));

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
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 2),
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
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Text(
                      AppStrings.appName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Text(
                      AppStrings.appTagline,
                      style: AppTextStyles.tagline(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('${AppStrings.greetingPrefix} ${household.name}!',
                style: AppTextStyles.heading1.copyWith(fontSize: 19)),
            const SizedBox(height: 2),
            Text(AppStrings.greetingSubtitle, style: AppTextStyles.bodySecondary),
            const SizedBox(height: 12),
            _HouseholdCard(
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
            if (_permissionStatus == 'default' || _permissionStatus == 'denied') ...[
              const SizedBox(height: 8),
              _NotificationBanner(
                isBlocked: _permissionStatus == 'denied',
                onEnable: _requestPermission,
              ),
            ],
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatCard(
                  module: featured[0],
                  color: AppColors.itemPurchased,
                  badgeCount: pendingCount > 0 ? pendingCount : null,
                ),
                _StatCard(module: featured[1], color: AppColors.itemNewBadge),
                _StatCard(module: featured[2], color: AppColors.itemNotFound),
                _StatCard(
                  module: featured[3],
                  color: AppColors.primary,
                  badgeCount: upcoming.isNotEmpty ? upcoming.length : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _UpcomingCalendarCard(upcoming: upcoming),
            const SizedBox(height: 20),
            Text(AppStrings.comingSoonSectionTitle, style: AppTextStyles.heading2),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemCount: restModules.length,
              itemBuilder: (context, index) => _ModuleTile(module: restModules[index]),
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

/// כרטיסיית סטטיסטיקה צבעונית (בהשראת עיצוב שהמשתמש שלח) - אייקון
/// בעיגול צבעוני, כותרת, ותג מספר אם יש נתון אמיתי. אם המודול לא
/// זמין עדיין, מוצג "בקרוב" במקום התג.
class _StatCard extends StatelessWidget {
  final HomeModule module;
  final Color color;
  final int? badgeCount;

  const _StatCard({required this.module, required this.color, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    final bool available = module.isAvailable && module.screenBuilder != null;

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: available
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: module.screenBuilder!),
                )
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title, style: AppTextStyles.heading2.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    if (badgeCount != null)
                      Text('$badgeCount', style: AppTextStyles.heading1.copyWith(fontSize: 20))
                    else if (!available)
                      Text(AppStrings.comingSoon,
                          style: AppTextStyles.bodySecondary.copyWith(fontSize: 11))
                    else
                      Text(module.subtitle,
                          style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// כרטיס "לוח שנה" - לוח חודשי קומפקטי (מסמן ימים עם קנייה מתוכננת)
/// + רשימת "האירועים הקרובים" מתחתיו. מבוסס על תאריכי רשימות קניות
/// שכבר קיימים במערכת - אין עדיין מודול "אירועים" עצמאי.
class _UpcomingCalendarCard extends StatelessWidget {
  final List<ShoppingList> upcoming;

  const _UpcomingCalendarCard({required this.upcoming});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = month.weekday % 7;
    const weekdayLabels = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
    final markedDays = upcoming
        .where((l) => l.date!.year == month.year && l.date!.month == month.month)
        .map((l) => l.date!.day)
        .toSet();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text('${AppStrings.calendarCardTitle} · ${month.month}/${month.year}',
                  style: AppTextStyles.heading2.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: weekdayLabels
                .map((l) => Expanded(
                      child: Center(
                        child: Text(l,
                            style: AppTextStyles.bodySecondary.copyWith(fontSize: 10)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: leadingEmptyCells + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmptyCells) return const SizedBox.shrink();
              final day = index - leadingEmptyCells + 1;
              final isMarked = markedDays.contains(day);
              final isToday = day == now.day;

              return Container(
                decoration: BoxDecoration(
                  color: isMarked ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday && !isMarked
                      ? Border.all(color: AppColors.primary, width: 1)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMarked ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              );
            },
          ),
          if (upcoming.isNotEmpty) ...[
            const Divider(height: 24),
            Text(AppStrings.upcomingEventsTitle, style: AppTextStyles.heading2.copyWith(fontSize: 13)),
            const SizedBox(height: 6),
            ...upcoming.take(4).map(
                  (l) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(l.name, style: AppTextStyles.body.copyWith(fontSize: 13))),
                        Text(DateFormatter.dateOnly(l.date!),
                            style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(AppStrings.noUpcomingEvents, style: AppTextStyles.bodySecondary),
            ),
        ],
      ),
    );
  }
}

/// אריח מודול בודד ברשת "בקרוב". תמיד מעומעם - כל המודולים
/// שמגיעים לכאן טרם מומשו.
class _ModuleTile extends StatelessWidget {
  final HomeModule module;

  const _ModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Opacity(
        opacity: 0.5,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Icon(module.icon, color: AppColors.textSecondary, size: 24),
                ),
                const SizedBox(height: 12),
                Text(module.title, style: AppTextStyles.heading2.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  module.subtitle,
                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
    );
  }
}

HMEOF
echo 'DONE - dashboard redesign with boosted colors, no background photo yet!'
