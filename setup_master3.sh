bash setup_master3.sh#!/bin/bash
set -e
echo 'Building complete Home Manager project...'
mkdir -p lib/app/config lib/core/errors lib/core/utils lib/core/widgets lib/models lib/services/firebase lib/services/notifications lib/services/external lib/repositories lib/providers lib/features/splash lib/features/auth lib/features/household lib/features/home lib/features/shopping
rm -f lib/main.dart lib/app.dart lib/state.dart
cat > 'pubspec.yaml' << 'HMEOF'
name: home_manager
description: "מערכת לניהול משק הבית עבור זוגות ומשפחות."
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1

  # Navigation
  go_router: ^14.2.0

  # Firebase (יחוברו בפועל בשלב 2)
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.4
  cloud_firestore: ^5.2.1
  firebase_messaging: ^15.0.4

  # עזרים כלליים
  intl: ^0.19.0
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true

HMEOF
cat > 'analysis_options.yaml' << 'HMEOF'
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_single_quotes: true

HMEOF
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
cat > 'SETUP_INSTRUCTIONS.md' << 'HMEOF'
# הוראות הפעלה — שלב 1

הסביבה שבה אני עובד לא כוללת Flutter SDK מותקן, ולכן לא הרצתי בעצמי
`flutter create` — יצרתי את כל קבצי הקוד ידנית בהתאם למבנה שסיכמנו.
הפעולות הבאות הן עליך לבצע פעם אחת, אצלך במחשב:

## 1. ודא ש-Flutter מותקן
```
flutter --version
```
אם אין לך, התקן מכאן: https://docs.flutter.dev/get-started/install

## 2. צור פרויקט Flutter ריק (כדי לקבל את קבצי android/ios/web הנדרשים)
```
flutter create home_manager
```

## 3. החלף את תוכן תיקיית lib/ ואת pubspec.yaml
מתוך קובץ ה-zip שקיבלת ממני (`home_manager_stage1.zip`):
- מחק את התיקייה `home_manager/lib` שנוצרה אוטומטית ב-`flutter create`.
- העתק במקומה את התיקייה `lib/` מתוך ה-zip.
- החלף את `pubspec.yaml` בקובץ מתוך ה-zip.
- העתק גם את `PROJECT_STATUS.md`, `SETUP_INSTRUCTIONS.md` ו-`analysis_options.yaml` לתיקיית השורש של הפרויקט.

## 4. התקן את התלויות
```
cd home_manager
flutter pub get
```

## 5. הרץ את האפליקציה
```
flutter run
```
אמור להיפתח מסך ירוק פשוט עם הכיתוב "Home Manager" — זהו מסך ה-Splash.
זה כל מה שנבנה בשלב 1 (עדיין בלי Firebase, בלי Login).

## אם יש שגיאות
העתק לי את הודעת השגיאה המדויקת מה-terminal, ואני אעזור לך לפתור.

## מומלץ מאוד: Git
```
git init
git add .
git commit -m "Stage 1: project structure + branding config"
```
כך שיהיה לך תיעוד של כל שינוי, כולל עריכות ידניות שתעשה בעתיד.

---
לאחר שהפעלת בהצלחה ותרצה להמשיך — תגיד לי "שלב 1 עבד, בוא נעבור לשלב 2"
ואתחיל בחיבור Firebase (Auth + Firestore + FCM).

HMEOF
cat > 'firestore.rules' << 'HMEOF'
rules_version = '2';

// כללי האבטחה של Firestore.
//
// עקרון מפתח: משתמש יכול לקרוא/לכתוב רק מידע של household שהוא חבר בו.
// ה-invite flow (הצטרפות ל-household) מבוסס על "הכרת ה-ID" של ה-household
// (שמתפקד כקוד ההזמנה) - זהו מזהה אקראי וארוך של Firestore, ששקול
// ברמת האבטחה שלו לקישור שיתוף (כמו ב-Google Drive).
service cloud.firestore {
  match /databases/{database}/documents {

    // פונקציית עזר: האם המשתמש חבר ב-household הנתון?
    // משמשת בכל מקום שדורש בדיקת חברות (members, shoppingLists, items).
    function isHouseholdMember(householdId) {
      return request.auth != null &&
        request.auth.uid in get(/databases/$(database)/documents/households/$(householdId)).data.memberIds;
    }

    // מסמך המשתמש עצמו - רק הוא יכול לקרוא/לכתוב אליו.
    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;
    }

    match /households/{householdId} {
      // קריאה פתוחה לכל משתמש מחובר - כדי לאפשר לו "לראות" household
      // לפני שהוא מצטרף אליו (לפי קוד ההזמנה). המידע שנחשף (שם, מספר
      // חברים) אינו רגיש.
      allow read: if request.auth != null;

      // יצירת household חדש - רק אם היוצר מגדיר את עצמו כחבר היחיד.
      allow create: if request.auth != null
        && request.resource.data.createdBy == request.auth.uid
        && request.resource.data.memberIds is list
        && request.resource.data.memberIds.size() == 1
        && request.resource.data.memberIds[0] == request.auth.uid;

      // עדכון household קיים מותר בשני מקרים:
      // 1. המשתמש כבר חבר (לעדכונים כלליים, כמו shoppingListId).
      // 2. המשתמש "מצטרף" - השינוי היחיד הוא הוספת ה-uid שלו למערך memberIds.
      allow update: if request.auth != null && (
        request.auth.uid in resource.data.memberIds
        ||
        (
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['memberIds'])
          && request.resource.data.memberIds == resource.data.memberIds.concat([request.auth.uid])
        )
      );

      allow delete: if false;

      // מסמך "חברות" אישי בתוך household - כל משתמש יכול ליצור/לעדכן
      // רק את המסמך של עצמו. קריאה מותרת רק לחברי אותו household.
      match /members/{memberId} {
        allow read: if isHouseholdMember(householdId);
        allow create: if request.auth != null && request.auth.uid == memberId;
        allow update: if request.auth != null && request.auth.uid == memberId;
        allow delete: if isHouseholdMember(householdId);
      }

      // רשימות קניות - רק חברי ה-household יכולים לקרוא/לכתוב.
      match /shoppingLists/{listId} {
        allow read, write: if isHouseholdMember(householdId);

        // פריטים בתוך רשימה - אותה הרשאה: רק חברי ה-household.
        match /items/{itemId} {
          allow read, write: if isHouseholdMember(householdId);
        }

        // sessions של קנייה פעילה - אותה הרשאה: רק חברי ה-household.
        match /sessions/{sessionId} {
          allow read, write: if isHouseholdMember(householdId);
        }
      }

      // היסטוריית קניות - רק חברי ה-household יכולים לקרוא/לכתוב.
      match /shoppingHistory/{historyId} {
        allow read, write: if isHouseholdMember(householdId);
      }
    }
  }
}

HMEOF
cat > 'firebase.json' << 'HMEOF'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}

HMEOF
cat > 'firestore.indexes.json' << 'HMEOF'
{
  "indexes": [],
  "fieldOverrides": []
}

HMEOF
cat > 'lib/main.dart' << 'HMEOF'
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'firebase_options.dart';

/// נקודת הכניסה של האפליקציה.
///
/// לפני הרצת ה-UI, מאתחלים חיבור בפועל לפרויקט Firebase שלנו
/// (Home Manager). ה-`DefaultFirebaseOptions` נוצר אוטומטית על ידי
/// `flutterfire configure` ומכיל את מפתחות/הגדרות הפרויקט הספציפי שלנו.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: HomeManagerApp(),
    ),
  );
}

HMEOF
cat > 'lib/app/app.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/app_colors.dart';
import 'config/app_config.dart';
import 'router.dart';

/// ה-Widget הראשי של האפליקציה.
/// אחראי על: theme כללי, שפה/כיווניות (RTL), וחיבור ה-router.
class HomeManagerApp extends StatelessWidget {
  const HomeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,

      // תמיכה בעברית ו-RTL
      locale: const Locale('he'),
      supportedLocales: const [Locale('he'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

HMEOF
cat > 'lib/app/router.dart' << 'HMEOF'
import 'package:go_router/go_router.dart';
import '../features/auth/register_screen.dart';
import 'auth_gate.dart';

/// כל הניתוב (routes) של האפליקציה מרוכז כאן.
///
/// המסך הראשי ('/') הוא AuthGate - הוא זה שמחליט אם להציג
/// Login או Home, לפי מצב ההתחברות. '/register' הוא מסך נפרד
/// שנפתח (push) מעל מסך ה-Login.
///
/// בשלבים הבאים נוסיף כאן routes נוספים כמו
/// '/create-household', '/shopping-list/:listId' וכו'.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'root',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);

HMEOF
cat > 'lib/app/auth_gate.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/error_view.dart';
import '../features/auth/login_screen.dart';
import '../features/splash/splash_screen.dart';
import '../providers/auth_provider.dart';
import 'household_gate.dart';

/// "השומר" הראשון של האפליקציה.
///
/// מאזין למצב ההתחברות (authStateChangesProvider) ומציג אוטומטית
/// את המסך המתאים:
/// - עדיין בודק (loading) → Splash
/// - לא מחובר (null) → Login
/// - מחובר (User) → HouseholdGate (שבודק אם יש לו household)
///
/// כך שכל שינוי במצב ההתחברות (login/register/signOut) מתעדכן
/// אוטומטית בכל האפליקציה, בלי ניווט ידני.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (error, stack) => const Scaffold(
        body: ErrorView(message: 'שגיאה בבדיקת מצב ההתחברות'),
      ),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        return const HouseholdGate();
      },
    );
  }
}

HMEOF
cat > 'lib/app/household_gate.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/error_view.dart';
import '../features/home/home_screen.dart';
import '../features/household/create_household_screen.dart';
import '../features/shopping/shopping_notifications_listener.dart';
import '../features/splash/splash_screen.dart';
import '../providers/household_provider.dart';

/// "שומר" שני, שרץ אחרי AuthGate (כלומר המשתמש כבר מחובר).
///
/// מאזין ל-household של המשתמש הנוכחי ומציג את המסך המתאים:
/// - עדיין בודק → Splash
/// - אין household → מסך יצירה/הצטרפות
/// - יש household → מסך הבית, עטוף ב-ShoppingNotificationsListener
///   כדי שההאזנה להתראות תפעל בכל מסך באפליקציה, לא רק ברשימת
///   הקניות עצמה.
class HouseholdGate extends ConsumerWidget {
  const HouseholdGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdState = ref.watch(myHouseholdProvider);

    return householdState.when(
      loading: () => const SplashScreen(),
      error: (error, stack) => const Scaffold(
        body: ErrorView(message: 'שגיאה בטעינת משק הבית'),
      ),
      data: (household) {
        if (household == null) {
          return const CreateOrJoinHouseholdScreen();
        }
        return ShoppingNotificationsListener(
          householdId: household.id,
          child: const HomeScreen(),
        );
      },
    );
  }
}

HMEOF
cat > 'lib/app/config/app_config.dart' << 'HMEOF'
/// כל ההגדרות הכלליות של האפליקציה מרוכזות כאן.
///
/// זהו המקום היחיד ששם המותג, הגדרות ברירת המחדל וכדומה מוגדרים בו.
/// אם בעתיד נרצה לשנות את שם האפליקציה (למשל ל-"Domira"),
/// צריך לשנות רק את הקובץ הזה — לא לחפש בכל הפרויקט.
class AppConfig {
  AppConfig._(); // מונע יצירת מופע של המחלקה - זו מחלקת קבועים בלבד

  /// שם האפליקציה כפי שהוא מוצג למשתמש
  static const String appName = 'Home Manager';

  /// גרסת האפליקציה (מוצגת במסך הגדרות)
  static const String appVersion = '0.1.0';

  /// גודל ברירת מחדל של רשימת קניות חדשה
  static const String defaultShoppingListName = 'קניות שבועיות';

  /// כמה זמן (בימים) לשמור מוצרים ב"רשימת להשלים" לפני שמנקים אוטומטית
  /// (לא בשימוש עדיין - מוכן לעתיד)
  static const int missingItemsRetentionDays = 30;
}

HMEOF
cat > 'lib/app/config/app_colors.dart' << 'HMEOF'
import 'package:flutter/material.dart';

/// פלטת הצבעים המרכזית של האפליקציה.
///
/// אף widget לא אמור להשתמש בצבע "קשיח" (כמו Colors.green ישירות).
/// במקום זאת, תמיד יש להשתמש בקבועים מהמחלקה הזו.
/// כך שינוי "צבע המותג" בעתיד יהיה שינוי במקום אחד בלבד.
class AppColors {
  AppColors._();

  // צבעי בסיס
  static const Color primary = Color(0xFF2E7D5B); // ירוק ראשי
  static const Color primaryLight = Color(0xFFE8F5EE);
  static const Color background = Color(0xFFFFFFFF); // לבן
  static const Color surface = Color(0xFFF5F5F5); // אפור בהיר

  // טקסט
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  // סטטוסים של מוצרים ברשימת הקניות
  static const Color itemPurchased = Color(0xFF2E7D5B); // ירוק - נקנה
  static const Color itemNotFound = Color(0xFFE65100); // כתום - לא נמצא
  static const Color itemNewBadge = Color(0xFF1976D2); // כחול - "חדש"

  // מצבי שגיאה/אזהרה
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);

  // גבולות וחלוקות
  static const Color divider = Color(0xFFE0E0E0);
}

HMEOF
cat > 'lib/app/config/app_text_styles.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// סגנונות טקסט מרכזיים.
/// כל שינוי בגופן/גודל/משקל של האפליקציה נעשה כאן בלבד.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Rubik'; // גופן תומך עברית, יתווסף בשלב עיצוב

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

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
  static const String membersCount = 'חברים במשק הבית';
  static const String comingSoon = 'בקרוב';
  static const String manageMembers = 'ניהול חברים';
  static const String removeMember = 'הסר מהמשק בית';
  static const String confirmRemoveMemberTitle = 'להסיר את החבר?';
  static const String confirmRemoveMemberMessage = 'הם לא יראו יותר את הרשימה ואת פרטי משק הבית';
  static const String ownerLabel = 'בעלים';
  static const String memberLabel = 'חבר';

  // Shopping
  static const String shoppingList = 'רשימת קניות';
  static const String addProduct = 'הוספת מוצר';
  static const String editProduct = 'עריכת מוצר';
  static const String productName = 'שם המוצר';
  static const String quantity = 'כמות';
  static const String unit = 'יחידת מידה (אופציונלי)';
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
}

HMEOF
cat > 'lib/core/errors/failures.dart' << 'HMEOF'
/// מחלקת בסיס לכל השגיאות באפליקציה.
///
/// המטרה: כל שגיאה שמגיעה מ-Repository תהיה מסוג Failure ידוע,
/// כך שה-UI תמיד יודע איך להציג אותה למשתמש (בלי try/catch
/// גנרי בכל מסך שתופס Exception לא צפוי).
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// שגיאת רשת / חוסר חיבור לאינטרנט
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'אין חיבור לאינטרנט']);
}

/// שגיאת הרשאה (המשתמש לא חבר ב-household, וכו')
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'אין לך הרשאה לבצע פעולה זו']);
}

/// שגיאת אימות (Auth) - התחברות/הרשמה נכשלה
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// שגיאה כללית שלא סווגה
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'משהו השתבש, נסו שוב']);
}

HMEOF
cat > 'lib/core/utils/validators.dart' << 'HMEOF'
/// פונקציות ולידציה לשימוש בטפסים (Login, Register, Add Product וכו').
/// כל פונקציה מחזירה null אם הקלט תקין, או הודעת שגיאה בעברית אם לא.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'יש להזין אימייל';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-\.]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'כתובת אימייל לא תקינה';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'יש להזין סיסמה';
    }
    if (value.length < 6) {
      return 'הסיסמה חייבת להכיל לפחות 6 תווים';
    }
    return null;
  }

  static String? requiredText(String? value, {String fieldName = 'שדה זה'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName הוא שדה חובה';
    }
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'יש להזין כמות';
    }
    final number = num.tryParse(value);
    if (number == null || number <= 0) {
      return 'יש להזין מספר חיובי';
    }
    return null;
  }
}

HMEOF
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
}

HMEOF
cat > 'lib/core/utils/product_categorizer.dart' << 'HMEOF'
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
cat > 'lib/core/widgets/loading_indicator.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';

/// אינדיקטור טעינה אחיד לכל האפליקציה.
/// שימוש: כאשר מסך/רשימה ממתינים לנתונים (מ-Firestore וכו').
class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            message ?? AppStrings.loading,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

HMEOF
cat > 'lib/core/widgets/empty_state.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_text_styles.dart';

/// מצג "ריק" אחיד - למשל כשרשימת הקניות ריקה.
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

HMEOF
cat > 'lib/core/widgets/error_view.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';

/// מצג שגיאה אחיד, עם אפשרות ל"נסה שוב".
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.message = AppStrings.errorGeneric,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(AppStrings.retry, style: AppTextStyles.button),
            ),
          ],
        ],
      ),
    );
  }
}

HMEOF
cat > 'lib/models/household_model.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל של Household - "משק בית" (למשל "משפחת כהן").
///
/// memberIds נשמר גם כשדה ישיר על המסמך (ולא רק כ-subcollection)
/// כדי לאפשר שאילתה מהירה: "מצא את כל ה-households שאני חבר בהם"
/// (households.where('memberIds', arrayContains: myUid)).
class Household {
  final String id;
  final String name;
  final String createdBy;
  final DateTime? createdAt;
  final List<String> memberIds;
  final String? shoppingListId;

  const Household({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.memberIds,
    this.shoppingListId,
  });

  factory Household.fromFirestore(String id, Map<String, dynamic> data) {
    return Household(
      id: id,
      name: data['name'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      shoppingListId: data['shoppingListId'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreForCreate(String creatorUid) {
    return {
      'name': name,
      'createdBy': creatorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'memberIds': [creatorUid],
    };
  }
}

HMEOF
cat > 'lib/models/household_member_model.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל של חבר household - נשמר כמסמך נפרד בתוך members subcollection.
class HouseholdMember {
  final String uid;
  final String email;
  final String role; // 'owner' | 'member'
  final DateTime? joinedAt;

  const HouseholdMember({
    required this.uid,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory HouseholdMember.fromFirestore(String uid, Map<String, dynamic> data) {
    return HouseholdMember(
      uid: uid,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }
}

HMEOF
cat > 'lib/models/shopping_list_model.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל של רשימת קניות. ב-MVP לכל household יש רשימה אחת בלבד
/// (ה-id שלה נשמר על מסמך ה-household עצמו כ-shoppingListId).
class ShoppingList {
  final String id;
  final String name;
  final DateTime? createdAt;
  final String? activeSessionId;

  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.activeSessionId,
  });

  factory ShoppingList.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingList(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      activeSessionId: data['activeSessionId'] as String?,
    );
  }

  static Map<String, dynamic> toFirestoreForCreate(String name) {
    return {
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

HMEOF
cat > 'lib/models/shopping_item_model.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/product_categorizer.dart';

/// סטטוס של מוצר ברשימת הקניות.
enum ItemStatus { pending, purchased, notFound }

ItemStatus _statusFromString(String? value) {
  switch (value) {
    case 'purchased':
      return ItemStatus.purchased;
    case 'notFound':
      return ItemStatus.notFound;
    default:
      return ItemStatus.pending;
  }
}

String _statusToString(ItemStatus status) {
  switch (status) {
    case ItemStatus.purchased:
      return 'purchased';
    case ItemStatus.notFound:
      return 'notFound';
    case ItemStatus.pending:
      return 'pending';
  }
}

/// מודל של מוצר ברשימת קניות.
///
/// `addedDuringShopping` כבר כלול כאן מראש (ברירת מחדל false) כדי
/// שהמבנה יהיה מוכן לשלב 7 (Active Shopping) בלי צורך במיגרציה.
class ShoppingItem {
  final String id;
  final String name;
  final double quantity;
  final String? unit;
  final ItemStatus status;
  final String addedBy;
  final String addedByName;
  final DateTime? addedAt;
  final bool addedDuringShopping;
  final DateTime? purchasedAt;
  final DateTime? notFoundAt;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit,
    required this.status,
    required this.addedBy,
    required this.addedByName,
    required this.addedAt,
    this.addedDuringShopping = false,
    this.purchasedAt,
    this.notFoundAt,
  });

  /// הקטגוריה מחושבת תמיד מחדש משם המוצר - לא נשמרת ב-Firestore,
  /// כך שעריכת שם מוצר מעדכנת אוטומטית גם את הקטגוריה שלו.
  ProductCategory get category => ProductCategorizer.categorize(name);

  factory ShoppingItem.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingItem(
      id: id,
      name: data['name'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1,
      unit: data['unit'] as String?,
      status: _statusFromString(data['status'] as String?),
      addedBy: data['addedBy'] as String? ?? '',
      addedByName: data['addedByName'] as String? ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
      addedDuringShopping: data['addedDuringShopping'] as bool? ?? false,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
      notFoundAt: (data['notFoundAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required String name,
    required double quantity,
    String? unit,
    required String addedBy,
    required String addedByName,
    bool addedDuringShopping = false,
  }) {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'status': _statusToString(ItemStatus.pending),
      'addedBy': addedBy,
      'addedByName': addedByName,
      'addedAt': FieldValue.serverTimestamp(),
      'addedDuringShopping': addedDuringShopping,
      'purchasedAt': null,
      'notFoundAt': null,
    };
  }

  Map<String, dynamic> toFirestoreForUpdate({
    String? name,
    double? quantity,
    String? unit,
  }) {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (quantity != null) map['quantity'] = quantity;
    if (unit != null) map['unit'] = unit;
    return map;
  }

  static Map<String, dynamic> statusUpdate(ItemStatus newStatus) {
    final map = <String, dynamic>{'status': _statusToString(newStatus)};
    switch (newStatus) {
      case ItemStatus.purchased:
        map['purchasedAt'] = FieldValue.serverTimestamp();
        map['notFoundAt'] = null;
        break;
      case ItemStatus.notFound:
        map['notFoundAt'] = FieldValue.serverTimestamp();
        map['purchasedAt'] = null;
        break;
      case ItemStatus.pending:
        map['purchasedAt'] = null;
        map['notFoundAt'] = null;
        break;
    }
    return map;
  }
}

HMEOF
cat > 'lib/models/shopping_session_model.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';

/// מודל "קנייה פעילה" - נוצר כשמישהו לוחץ "התחל קנייה",
/// ונסגר כשלוחצים "סיום קנייה".
class ShoppingSession {
  final String id;
  final DateTime? startedAt;
  final String startedBy;
  final String startedByName;
  final DateTime? endedAt;
  final String status; // 'active' | 'completed'

  const ShoppingSession({
    required this.id,
    required this.startedAt,
    required this.startedBy,
    required this.startedByName,
    this.endedAt,
    required this.status,
  });

  factory ShoppingSession.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingSession(
      id: id,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      startedBy: data['startedBy'] as String? ?? '',
      startedByName: data['startedByName'] as String? ?? '',
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      status: data['status'] as String? ?? 'active',
    );
  }

  static Map<String, dynamic> toFirestoreForStart({
    required String startedBy,
    required String startedByName,
  }) {
    return {
      'startedAt': FieldValue.serverTimestamp(),
      'startedBy': startedBy,
      'startedByName': startedByName,
      'endedAt': null,
      'status': 'active',
    };
  }

  static Map<String, dynamic> toFirestoreForEnd() {
    return {
      'endedAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    };
  }
}

HMEOF
cat > 'lib/models/shopping_history_model.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';

/// רשומת היסטוריה של קנייה שהושלמה - סיכום, לא הפריטים המלאים.
class ShoppingHistoryEntry {
  final String id;
  final DateTime? date;
  final int totalItems;
  final int purchasedCount;
  final int notFoundCount;
  final List<String> notFoundItemNames;
  final String completedBy;
  final String completedByName;

  const ShoppingHistoryEntry({
    required this.id,
    required this.date,
    required this.totalItems,
    required this.purchasedCount,
    required this.notFoundCount,
    required this.notFoundItemNames,
    required this.completedBy,
    required this.completedByName,
  });

  factory ShoppingHistoryEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingHistoryEntry(
      id: id,
      date: (data['date'] as Timestamp?)?.toDate(),
      totalItems: (data['totalItems'] as num?)?.toInt() ?? 0,
      purchasedCount: (data['purchasedCount'] as num?)?.toInt() ?? 0,
      notFoundCount: (data['notFoundCount'] as num?)?.toInt() ?? 0,
      notFoundItemNames: List<String>.from(data['notFoundItemNames'] as List? ?? []),
      completedBy: data['completedBy'] as String? ?? '',
      completedByName: data['completedByName'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required int totalItems,
    required int purchasedCount,
    required int notFoundCount,
    required List<String> notFoundItemNames,
    required String completedBy,
    required String completedByName,
  }) {
    return {
      'date': FieldValue.serverTimestamp(),
      'totalItems': totalItems,
      'purchasedCount': purchasedCount,
      'notFoundCount': notFoundCount,
      'notFoundItemNames': notFoundItemNames,
      'completedBy': completedBy,
      'completedByName': completedByName,
    };
  }
}

HMEOF
cat > 'lib/services/firebase/firebase_auth_service.dart' << 'HMEOF'
import 'package:firebase_auth/firebase_auth.dart';

/// עטיפה דקה סביב FirebaseAuth.
///
/// זו שכבת ה-Service - היא רק "מדברת" עם Firebase, לא מכילה
/// שום לוגיקה עסקית ולא יודעת כלום על הודעות שגיאה בעברית.
/// זה תפקידו של ה-Repository (השכבה שמעליה).
class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}

HMEOF
cat > 'lib/services/firebase/household_service.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/household_member_model.dart';
import '../../models/household_model.dart';

/// עטיפה דקה סביב קריאות Firestore הקשורות ל-Household.
/// שכבת Service - רק "מדברת" עם Firebase, בלי לוגיקה עסקית.
class HouseholdService {
  final FirebaseFirestore _firestore;

  HouseholdService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _households =>
      _firestore.collection('households');

  /// מאזין ל-household הראשון שהמשתמש חבר בו.
  /// (בשלב ה-MVP מניחים משתמש אחד = household אחד; הארכיטקטורה
  /// תומכת בעתיד בכמה households לפי אותה שאילתה בלי limit(1)).
  Stream<Household?> watchMyHousehold(String uid) {
    return _households
        .where('memberIds', arrayContains: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return Household.fromFirestore(doc.id, doc.data());
    });
  }

  Future<Household> createHousehold({
    required String name,
    required String creatorUid,
    required String creatorEmail,
  }) async {
    final docRef = await _households.add(
      Household(
        id: '',
        name: name,
        createdBy: creatorUid,
        createdAt: null,
        memberIds: const [],
      ).toFirestoreForCreate(creatorUid),
    );

    await docRef.collection('members').doc(creatorUid).set({
      'role': 'owner',
      'email': creatorEmail,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await docRef.get();
    return Household.fromFirestore(snapshot.id, snapshot.data()!);
  }

  Future<void> joinHousehold({
    required String householdId,
    required String uid,
    required String email,
  }) async {
    final docRef = _households.doc(householdId);

    await docRef.update({
      'memberIds': FieldValue.arrayUnion([uid]),
    });

    await docRef.collection('members').doc(uid).set({
      'role': 'member',
      'email': email,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return _households.doc(householdId).collection('members').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => HouseholdMember.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// מסיר חבר מה-household: מוחק את מסמך החברות שלו, ומוציא אותו
  /// ממערך memberIds. myHouseholdProvider אצל המשתמש שהוסר יזהה
  /// את זה אוטומטית (השאילתה לא תחזיר יותר את ה-household הזה עבורו).
  Future<void> removeMember({
    required String householdId,
    required String memberUid,
  }) async {
    final batch = _firestore.batch();
    final docRef = _households.doc(householdId);

    batch.delete(docRef.collection('members').doc(memberUid));
    batch.update(docRef, {
      'memberIds': FieldValue.arrayRemove([memberUid]),
    });

    await batch.commit();
  }
}

HMEOF
cat > 'lib/services/firebase/shopping_service.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/household_model.dart';
import '../../models/shopping_history_model.dart';
import '../../models/shopping_item_model.dart';
import '../../models/shopping_list_model.dart';
import '../../models/shopping_session_model.dart';

/// עטיפה דקה סביב קריאות Firestore הקשורות לרשימת קניות.
class ShoppingService {
  final FirebaseFirestore _firestore;

  ShoppingService(this._firestore);

  DocumentReference<Map<String, dynamic>> _householdDoc(String householdId) =>
      _firestore.collection('households').doc(householdId);

  CollectionReference<Map<String, dynamic>> _listsCollection(String householdId) =>
      _householdDoc(householdId).collection('shoppingLists');

  CollectionReference<Map<String, dynamic>> _itemsCollection(
    String householdId,
    String listId,
  ) =>
      _listsCollection(householdId).doc(listId).collection('items');

  CollectionReference<Map<String, dynamic>> _historyCollection(String householdId) =>
      _householdDoc(householdId).collection('shoppingHistory');

  CollectionReference<Map<String, dynamic>> _sessionsCollection(
    String householdId,
    String listId,
  ) =>
      _listsCollection(householdId).doc(listId).collection('sessions');

  /// מאזין למידע של הרשימה עצמה (כולל activeSessionId) בזמן אמת -
  /// כך שכל חברי ה-household רואים מיידית אם קנייה פעילה החלה/הסתיימה.
  Stream<ShoppingList> watchListMeta(String householdId, String listId) {
    return _listsCollection(householdId).doc(listId).snapshots().map(
          (doc) => ShoppingList.fromFirestore(doc.id, doc.data() ?? {}),
        );
  }

  Future<void> startShoppingSession({
    required String householdId,
    required String listId,
    required String startedBy,
    required String startedByName,
  }) async {
    final sessionRef = _sessionsCollection(householdId, listId).doc();
    await sessionRef.set(
      ShoppingSession.toFirestoreForStart(
        startedBy: startedBy,
        startedByName: startedByName,
      ),
    );
    await _listsCollection(householdId).doc(listId).update({
      'activeSessionId': sessionRef.id,
    });
  }

  /// מחזיר את מזהה רשימת הקניות של ה-household.
  /// אם עדיין אין לו רשימה (households שנוצרו לפני שלב זה), יוצר
  /// אחת חדשה ושומר את המזהה שלה על מסמך ה-household.
  Future<String> getOrCreateDefaultListId(Household household) async {
    if (household.shoppingListId != null) {
      return household.shoppingListId!;
    }

    final listRef = await _listsCollection(household.id).add(
      ShoppingList.toFirestoreForCreate('קניות שבועיות'),
    );

    await _householdDoc(household.id).update({
      'shoppingListId': listRef.id,
    });

    return listRef.id;
  }

  Stream<List<ShoppingItem>> watchItems(String householdId, String listId) {
    return _itemsCollection(householdId, listId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingItem.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> addItem({
    required String householdId,
    required String listId,
    required String name,
    required double quantity,
    String? unit,
    required String addedBy,
    required String addedByName,
    bool addedDuringShopping = false,
  }) {
    return _itemsCollection(householdId, listId).add(
      ShoppingItem.toFirestoreForCreate(
        name: name,
        quantity: quantity,
        unit: unit,
        addedBy: addedBy,
        addedByName: addedByName,
        addedDuringShopping: addedDuringShopping,
      ),
    );
  }

  Future<void> updateItem({
    required String householdId,
    required String listId,
    required String itemId,
    String? name,
    double? quantity,
    String? unit,
  }) {
    final data = ShoppingItem(
      id: itemId,
      name: '',
      quantity: 0,
      status: ItemStatus.pending,
      addedBy: '',
      addedByName: '',
      addedAt: null,
    ).toFirestoreForUpdate(name: name, quantity: quantity, unit: unit);

    return _itemsCollection(householdId, listId).doc(itemId).update(data);
  }

  Future<void> updateStatus({
    required String householdId,
    required String listId,
    required String itemId,
    required ItemStatus status,
  }) {
    return _itemsCollection(householdId, listId)
        .doc(itemId)
        .update(ShoppingItem.statusUpdate(status));
  }

  Future<void> deleteItem({
    required String householdId,
    required String listId,
    required String itemId,
  }) {
    return _itemsCollection(householdId, listId).doc(itemId).delete();
  }

  /// מסיים קנייה: מוחק את כל הפריטים שנקנו, מטפל בפריטים שלא נמצאו
  /// (מעביר חזרה ל"ממתין" את אלה שנבחרו, מוחק את השאר), ושומר
  /// רשומת סיכום בהיסטוריה - הכל בפעולה אטומית אחת (WriteBatch).
  Future<void> finishShopping({
    required String householdId,
    required String listId,
    required List<ShoppingItem> purchasedItems,
    required List<ShoppingItem> notFoundItemsToCarryOver,
    required List<ShoppingItem> notFoundItemsToDrop,
    required int totalItemsCount,
    required String completedBy,
    required String completedByName,
    String? activeSessionId,
  }) async {
    final batch = _firestore.batch();
    final itemsRef = _itemsCollection(householdId, listId);

    for (final item in purchasedItems) {
      batch.delete(itemsRef.doc(item.id));
    }
    for (final item in notFoundItemsToDrop) {
      batch.delete(itemsRef.doc(item.id));
    }
    for (final item in notFoundItemsToCarryOver) {
      batch.update(itemsRef.doc(item.id), {
        ...ShoppingItem.statusUpdate(ItemStatus.pending),
        // מוצר שהועבר לקנייה הבאה כבר לא "חדש" - הוא לא נוסף
        // בזמן קנייה פעילה נוכחית, אלא הגיע מסבב קודם.
        'addedDuringShopping': false,
      });
    }

    // אם הייתה קנייה פעילה - סוגרים אותה כחלק מאותה פעולה אטומית.
    if (activeSessionId != null) {
      batch.update(
        _sessionsCollection(householdId, listId).doc(activeSessionId),
        ShoppingSession.toFirestoreForEnd(),
      );
      batch.update(_listsCollection(householdId).doc(listId), {
        'activeSessionId': null,
      });
    }

    final historyRef = _historyCollection(householdId).doc();
    batch.set(
      historyRef,
      ShoppingHistoryEntry.toFirestoreForCreate(
        totalItems: totalItemsCount,
        purchasedCount: purchasedItems.length,
        notFoundCount: notFoundItemsToCarryOver.length + notFoundItemsToDrop.length,
        notFoundItemNames: [
          ...notFoundItemsToCarryOver.map((e) => e.name),
          ...notFoundItemsToDrop.map((e) => e.name),
        ],
        completedBy: completedBy,
        completedByName: completedByName,
      ),
    );

    await batch.commit();
  }

  Stream<List<ShoppingHistoryEntry>> watchHistory(String householdId) {
    return _historyCollection(householdId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingHistoryEntry.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}

HMEOF
cat > 'lib/services/notifications/browser_notification_service.dart' << 'HMEOF'
/// בוחר אוטומטית את המימוש הנכון: Web אמיתי, או stub לכל פלטפורמה אחרת.
/// זו הסיבה שבשום מקום אחר בקוד לא מייבאים ישירות את קבצי ה-web/stub -
/// תמיד מייבאים את הקובץ הזה בלבד.
export 'browser_notification_service_stub.dart'
    if (dart.library.html) 'browser_notification_service_web.dart';

HMEOF
cat > 'lib/services/notifications/browser_notification_service_web.dart' << 'HMEOF'
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// מימוש אמיתי של התראות דפדפן, פועל רק על Flutter Web.
/// לא נטען כלל בבנייה למובייל (Android/iOS) - ראה את קובץ ה-stub.
class BrowserNotificationService {
  Future<bool> requestPermission() async {
    if (!html.Notification.supported) return false;
    final permission = await html.Notification.requestPermission();
    return permission == 'granted';
  }

  bool get isPermissionGranted =>
      html.Notification.supported && html.Notification.permission == 'granted';

  /// 'granted' | 'denied' | 'default' (עדיין לא נשאל) | 'unsupported'
  String get permissionStatus =>
      html.Notification.supported ? (html.Notification.permission ?? 'default') : 'unsupported';

  void show({required String title, String? body}) {
    if (!isPermissionGranted) return;
    html.Notification(title, body: body ?? '');
  }
}

HMEOF
cat > 'lib/services/notifications/browser_notification_service_stub.dart' << 'HMEOF'
/// גרסת "לא עושה כלום" - נטענת אוטומטית בבנייה למובייל (Android/iOS),
/// כדי שהקוד ימשיך להתקמפל גם כשנוסיף תמיכה בפלטפורמות האלה בעתיד.
/// התראות מובייל אמיתיות (Push דרך FCM) ייבנו בנפרד כשנגיע לזה.
class BrowserNotificationService {
  Future<bool> requestPermission() async => false;

  bool get isPermissionGranted => false;

  String get permissionStatus => 'unsupported';

  void show({required String title, String? body}) {
    // no-op
  }
}

HMEOF
cat > 'lib/repositories/auth_repository.dart' << 'HMEOF'
import 'package:firebase_auth/firebase_auth.dart';
import '../core/errors/failures.dart';
import '../services/firebase/firebase_auth_service.dart';

/// השכבה שה-UI קורא לה בפועל להתחברות/הרשמה/יציאה.
///
/// אחראית לתרגם שגיאות טכניות של Firebase (קודי שגיאה באנגלית)
/// להודעות ברורות בעברית, דרך מחלקות ה-Failure שכבר הגדרנו ב-core/errors.
/// ה-UI לעולם לא מטפל ב-FirebaseAuthException ישירות.
class AuthRepository {
  final FirebaseAuthService _service;

  AuthRepository(this._service);

  Stream<User?> get authStateChanges => _service.authStateChanges;

  User? get currentUser => _service.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _service.signIn(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapErrorMessage(e.code));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _service.signUp(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapErrorMessage(e.code));
    }
  }

  Future<void> signOut() => _service.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _service.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapErrorMessage(e.code));
    }
  }

  String _mapErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'לא נמצא משתמש עם אימייל זה';
      case 'wrong-password':
      case 'invalid-credential':
        return 'אימייל או סיסמה שגויים';
      case 'email-already-in-use':
        return 'כתובת האימייל כבר בשימוש';
      case 'invalid-email':
        return 'כתובת אימייל לא תקינה';
      case 'weak-password':
        return 'הסיסמה חלשה מדי - נדרשים לפחות 6 תווים';
      case 'too-many-requests':
        return 'יותר מדי ניסיונות. נסו שוב מאוחר יותר';
      default:
        return 'שגיאה בהתחברות, נסו שוב';
    }
  }
}

HMEOF
cat > 'lib/repositories/household_repository.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failures.dart';
import '../models/household_member_model.dart';
import '../models/household_model.dart';
import '../services/firebase/household_service.dart';

/// השכבה שה-UI קורא לה בפועל ליצירה/הצטרפות/ניהול חברי Household.
class HouseholdRepository {
  final HouseholdService _service;

  HouseholdRepository(this._service);

  Stream<Household?> watchMyHousehold(String uid) {
    return _service.watchMyHousehold(uid);
  }

  Future<Household> createHousehold({
    required String name,
    required String creatorUid,
    required String creatorEmail,
  }) async {
    try {
      return await _service.createHousehold(
        name: name,
        creatorUid: creatorUid,
        creatorEmail: creatorEmail,
      );
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> joinHousehold({
    required String householdId,
    required String uid,
    required String email,
  }) async {
    try {
      await _service.joinHousehold(
        householdId: householdId.trim(),
        uid: uid,
        email: email,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw const PermissionFailure('קוד ההזמנה לא נמצא, בדקו שהעתקתם אותו נכון');
      }
      throw _mapError(e);
    }
  }

  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return _service.watchMembers(householdId);
  }

  Future<void> removeMember({
    required String householdId,
    required String memberUid,
  }) async {
    try {
      await _service.removeMember(householdId: householdId, memberUid: memberUid);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בהסרת החבר');
    }
  }

  Failure _mapError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return const PermissionFailure();
    }
    return const UnknownFailure();
  }
}

HMEOF
cat > 'lib/repositories/shopping_repository.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failures.dart';
import '../models/household_model.dart';
import '../models/shopping_history_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../services/firebase/shopping_service.dart';

class ShoppingRepository {
  final ShoppingService _service;

  ShoppingRepository(this._service);

  Future<String> getOrCreateDefaultListId(Household household) {
    return _service.getOrCreateDefaultListId(household);
  }

  Stream<ShoppingList> watchListMeta(String householdId, String listId) {
    return _service.watchListMeta(householdId, listId);
  }

  Future<void> startShoppingSession({
    required String householdId,
    required String listId,
    required String startedBy,
    required String startedByName,
  }) async {
    try {
      await _service.startShoppingSession(
        householdId: householdId,
        listId: listId,
        startedBy: startedBy,
        startedByName: startedByName,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בהתחלת הקנייה');
    }
  }

  Stream<List<ShoppingItem>> watchItems(String householdId, String listId) {
    return _service.watchItems(householdId, listId);
  }

  Future<void> addItem({
    required String householdId,
    required String listId,
    required String name,
    required double quantity,
    String? unit,
    required String addedBy,
    required String addedByName,
    bool addedDuringShopping = false,
  }) async {
    try {
      await _service.addItem(
        householdId: householdId,
        listId: listId,
        name: name,
        quantity: quantity,
        unit: unit,
        addedBy: addedBy,
        addedByName: addedByName,
        addedDuringShopping: addedDuringShopping,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בהוספת המוצר');
    }
  }

  Future<void> updateItem({
    required String householdId,
    required String listId,
    required String itemId,
    String? name,
    double? quantity,
    String? unit,
  }) async {
    try {
      await _service.updateItem(
        householdId: householdId,
        listId: listId,
        itemId: itemId,
        name: name,
        quantity: quantity,
        unit: unit,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בעדכון המוצר');
    }
  }

  Future<void> updateStatus({
    required String householdId,
    required String listId,
    required String itemId,
    required ItemStatus status,
  }) async {
    try {
      await _service.updateStatus(
        householdId: householdId,
        listId: listId,
        itemId: itemId,
        status: status,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בעדכון הסטטוס');
    }
  }

  Future<void> deleteItem({
    required String householdId,
    required String listId,
    required String itemId,
  }) async {
    try {
      await _service.deleteItem(
        householdId: householdId,
        listId: listId,
        itemId: itemId,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה במחיקת המוצר');
    }
  }

  Future<void> finishShopping({
    required String householdId,
    required String listId,
    required List<ShoppingItem> purchasedItems,
    required List<ShoppingItem> notFoundItemsToCarryOver,
    required List<ShoppingItem> notFoundItemsToDrop,
    required int totalItemsCount,
    required String completedBy,
    required String completedByName,
    String? activeSessionId,
  }) async {
    try {
      await _service.finishShopping(
        householdId: householdId,
        listId: listId,
        purchasedItems: purchasedItems,
        notFoundItemsToCarryOver: notFoundItemsToCarryOver,
        notFoundItemsToDrop: notFoundItemsToDrop,
        totalItemsCount: totalItemsCount,
        completedBy: completedBy,
        completedByName: completedByName,
        activeSessionId: activeSessionId,
      );
    } on FirebaseException {
      throw const UnknownFailure('שגיאה בסיום הקנייה');
    }
  }

  Stream<List<ShoppingHistoryEntry>> watchHistory(String householdId) {
    return _service.watchHistory(householdId);
  }
}

HMEOF
cat > 'lib/providers/auth_provider.dart' << 'HMEOF'
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../services/firebase/firebase_auth_service.dart';

/// מספק גישה ל-instance היחיד של FirebaseAuth באפליקציה.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// שכבת ה-Service.
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(ref.watch(firebaseAuthProvider));
});

/// שכבת ה-Repository - זו ש-UI אמור להשתמש בה בפועל.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authServiceProvider));
});

/// Stream של מצב ההתחברות הנוכחי.
/// null = לא מחובר, User = מחובר.
///
/// זהו ה-provider המרכזי ש-AuthGate מאזין לו כדי להחליט
/// איזה מסך להציג (Login / Home).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

HMEOF
cat > 'lib/providers/household_provider.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/household_member_model.dart';
import '../models/household_model.dart';
import '../repositories/household_repository.dart';
import '../services/firebase/household_service.dart';
import 'auth_provider.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final householdServiceProvider = Provider<HouseholdService>((ref) {
  return HouseholdService(ref.watch(firestoreProvider));
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(ref.watch(householdServiceProvider));
});

/// ה-Household של המשתמש המחובר כרגע - null אם עוד אין לו אחד.
///
/// תלוי ב-authStateChangesProvider: אם המשתמש מתנתק, ה-stream הזה
/// מפסיק אוטומטית להאזין ל-household של המשתמש הקודם.
final myHouseholdProvider = StreamProvider<Household?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(null);
  }

  return ref.watch(householdRepositoryProvider).watchMyHousehold(user.uid);
});

/// רשימת החברים בפועל של household מסוים.
final householdMembersProvider =
    StreamProvider.family<List<HouseholdMember>, String>((ref, householdId) {
  return ref.watch(householdRepositoryProvider).watchMembers(householdId);
});

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

/// מזהה רשימת הקניות של ה-household הנוכחי - נוצר אוטומטית אם עדיין
/// לא קיים (households שנוצרו לפני שהרשימה נתמכה).
final shoppingListIdProvider = FutureProvider<String?>((ref) async {
  final household = ref.watch(myHouseholdProvider).value;
  if (household == null) return null;
  return ref.watch(shoppingRepositoryProvider).getOrCreateDefaultListId(household);
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
cat > 'lib/providers/notification_provider.dart' << 'HMEOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notifications/browser_notification_service.dart';

final browserNotificationServiceProvider = Provider<BrowserNotificationService>((ref) {
  return BrowserNotificationService();
});

HMEOF
cat > 'lib/features/splash/splash_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_config.dart';
import '../../app/config/app_text_styles.dart';

/// מסך הפתיחה (Splash).
///
/// בשלב הזה הוא רק מציג את שם האפליקציה.
/// בשלב 3 (Authentication) הוא יבדוק אם המשתמש מחובר,
/// ולפי זה ינווט אוטומטית ל-Login או ל-Home.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_rounded, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              AppConfig.appName,
              style: AppTextStyles.heading1.copyWith(
                color: Colors.white,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

HMEOF
cat > 'lib/features/auth/login_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

/// מסך התחברות. בהצלחה, AuthGate מזהה אוטומטית את השינוי
/// במצב ההתחברות ומעביר את המשתמש למסך הבית - אין צורך בניווט ידני כאן.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on Failure catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = AppStrings.errorGeneric);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final controller = TextEditingController(text: _emailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.resetPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.resetPasswordBody, style: AppTextStyles.bodySecondary),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: AppStrings.email),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text(AppStrings.sendResetLink),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(AppStrings.resetLinkSent)));
      }
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.home_rounded, size: 56, color: Colors.white),
                        const SizedBox(height: 12),
                        const Text(
                          AppStrings.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: AppStrings.email),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: AppStrings.password),
                    validator: Validators.password,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(AppStrings.login, style: AppTextStyles.button),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(AppStrings.forgotPassword),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text(AppStrings.dontHaveAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

HMEOF
cat > 'lib/features/auth/register_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

/// מסך הרשמה. בהצלחה, AuthGate מזהה אוטומטית את השינוי
/// במצב ההתחברות ומעביר את המשתמש למסך הבית.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on Failure catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = AppStrings.errorGeneric);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createAccount)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: AppStrings.email),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: AppStrings.password),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: AppStrings.confirmPassword),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return AppStrings.passwordsDontMatch;
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(AppStrings.createAccount, style: AppTextStyles.button),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

HMEOF
cat > 'lib/features/household/create_household_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';

/// מסך שמוצג כשלמשתמש עדיין אין household.
/// מאפשר לבחור בין יצירת household חדש לבין הצטרפות לקיים
/// באמצעות קוד הזמנה.
class CreateOrJoinHouseholdScreen extends ConsumerStatefulWidget {
  const CreateOrJoinHouseholdScreen({super.key});

  @override
  ConsumerState<CreateOrJoinHouseholdScreen> createState() =>
      _CreateOrJoinHouseholdScreenState();
}

class _CreateOrJoinHouseholdScreenState
    extends ConsumerState<CreateOrJoinHouseholdScreen> {
  bool _showJoinForm = false;
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = ref.read(authStateChangesProvider).value;
    final uid = authUser?.uid;
    if (uid == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(householdRepositoryProvider);
      if (_showJoinForm) {
        await repo.joinHousehold(
          householdId: _textController.text,
          uid: uid,
          email: authUser?.email ?? '',
        );
      } else {
        await repo.createHousehold(
          name: _textController.text.trim(),
          creatorUid: uid,
          creatorEmail: authUser?.email ?? '',
        );
      }
      // בהצלחה - myHouseholdProvider יזהה אוטומטית את השינוי
      // ו-HouseholdGate יעביר למסך הבית.
    } on Failure catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = AppStrings.errorGeneric);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.home_rounded, size: 56, color: Colors.white),
                        const SizedBox(height: 12),
                        const Text(
                          AppStrings.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.noHouseholdYet,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: _showJoinForm
                          ? AppStrings.inviteCode
                          : AppStrings.householdName,
                    ),
                    validator: (value) => Validators.requiredText(
                      value,
                      fieldName: _showJoinForm
                          ? AppStrings.inviteCode
                          : AppStrings.householdName,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _showJoinForm
                                ? AppStrings.joinButton
                                : AppStrings.createHousehold,
                            style: AppTextStyles.button,
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showJoinForm = !_showJoinForm;
                        _errorMessage = null;
                        _textController.clear();
                      });
                    },
                    child: Text(
                      _showJoinForm
                          ? AppStrings.createNewHousehold
                          : AppStrings.haveInviteCode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

HMEOF
cat > 'lib/features/household/invite_partner_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';

/// מסך הזמנת בן/בת זוג. מציג את קוד ההזמנה (מזהה ה-household)
/// עם אפשרות העתקה, כדי לשתף עם בן/בת הזוג בכל ערוץ (וואטסאפ, הודעה וכו').
class InvitePartnerScreen extends StatelessWidget {
  final String householdId;
  final String householdName;

  const InvitePartnerScreen({
    super.key,
    required this.householdId,
    required this.householdName,
  });

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: householdId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.codeCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.invitePartner)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_add, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                householdName,
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.shareThisCode,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  householdId,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _copyCode(context),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text(AppStrings.copyCode, style: AppTextStyles.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

HMEOF
cat > 'lib/features/household/household_members_screen.dart' << 'HMEOF'
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
class HouseholdMembersScreen extends ConsumerWidget {
  final String householdId;

  const HouseholdMembersScreen({super.key, required this.householdId});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(householdMembersProvider(householdId));
    final myUid = ref.watch(authStateChangesProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.manageMembers)),
      body: membersAsync.when(
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
    );
  }
}

HMEOF
cat > 'lib/features/home/home_module.dart' << 'HMEOF'
import 'package:flutter/material.dart';

/// מודל של "אריח" מודול במסך הבית.
///
/// כל תחום באפליקציה (קניות, רכבים, ביטוחים, חוגים וכו') מיוצג
/// ע"י HomeModule אחד. הוספת מודול חדש בעתיד דורשת רק להוסיף
/// ערך חדש ב-`home_modules.dart` - לא צריך לגעת ב-home_screen.dart.
///
/// אם `screenBuilder` הוא null (או `isAvailable` הוא false), האריח
/// מוצג "מעומעם" עם תווית "בקרוב" ולא מגיב ללחיצה - כך אפשר
/// "להכריז" מראש על מודולים עתידיים בממשק, עוד לפני שהם ממומשים.
class HomeModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAvailable;
  final WidgetBuilder? screenBuilder;

  const HomeModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isAvailable = false,
    this.screenBuilder,
  });
}

HMEOF
cat > 'lib/features/home/home_modules.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'home_module.dart';
import '../shopping/shopping_list_screen.dart';

/// רשימת כל מודולי האפליקציה שמוצגים במסך הבית (Dashboard).
///
/// כדי להוסיף מודול חדש בעתיד (למשל מימוש בפועל של "חוגים"):
/// 1. בונים את המסך שלו תחת lib/features/<module_name>/
/// 2. מוסיפים כאן HomeModule עם isAvailable: true ו-screenBuilder מתאים
///
/// מודולים עם isAvailable: false (ברירת המחדל) מוצגים כ"בקרוב" -
/// כך אפשר להראות כבר עכשיו את כל התוכנית העתידית של האפליקציה
/// למשתמש, בלי לממש את הלוגיקה בפועל.
List<HomeModule> buildHomeModules({required String householdId}) {
  return [
    HomeModule(
      title: 'רשימת קניות',
      subtitle: 'קניות משותפות בזמן אמת',
      icon: Icons.shopping_cart_outlined,
      isAvailable: true,
      screenBuilder: (_) => ShoppingListScreen(householdId: householdId),
    ),
    const HomeModule(
      title: 'רכבים',
      subtitle: 'טסטים, טיפולים וקילומטראז\'',
      icon: Icons.directions_car_outlined,
    ),
    const HomeModule(
      title: 'ביטוחים',
      subtitle: 'פוליסות ותאריכי חידוש',
      icon: Icons.shield_outlined,
    ),
    const HomeModule(
      title: 'רישיונות',
      subtitle: 'תעודות ומסמכים בעלי תוקף',
      icon: Icons.badge_outlined,
    ),
    const HomeModule(
      title: 'חוגים',
      subtitle: 'פעילויות ולוחות זמנים',
      icon: Icons.sports_soccer_outlined,
    ),
    const HomeModule(
      title: 'חשבונות',
      subtitle: 'חשמל, מים, ארנונה ומנויים',
      icon: Icons.receipt_long_outlined,
    ),
    const HomeModule(
      title: 'מסמכים',
      subtitle: 'קבצים ותעודות חשובות',
      icon: Icons.folder_outlined,
    ),
    const HomeModule(
      title: 'משימות ותזכורות',
      subtitle: 'ניהול משק הבית היומיומי',
      icon: Icons.checklist_outlined,
    ),
  ];
}

HMEOF
cat > 'lib/features/home/home_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/notification_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(myHouseholdProvider).value;

    if (household == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final modules = buildHomeModules(householdId: household.id);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        actions: [
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.home_rounded, size: 44, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    builder: (_) => HouseholdMembersScreen(householdId: household.id),
                  ),
                ),
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

  const _HouseholdCard({
    required this.name,
    required this.membersCount,
    required this.onInvite,
    required this.onManageMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.heading2,
                  overflow: TextOverflow.ellipsis,
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
                        style: AppTextStyles.bodySecondary.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        color: available ? AppColors.primaryLight : AppColors.surface,
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
cat > 'lib/features/shopping/add_edit_product_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../models/shopping_item_model.dart';

/// תוצאת הטופס - שם, כמות ויחידת מידה (אופציונלי).
class ProductFormResult {
  final String name;
  final double quantity;
  final String? unit;

  const ProductFormResult({
    required this.name,
    required this.quantity,
    this.unit,
  });
}

/// מסך הוספה/עריכה של מוצר. משמש גם ליצירה (existingItem == null)
/// וגם לעריכה (existingItem != null), כדי לא לשכפל קוד טופס.
class AddEditProductScreen extends StatefulWidget {
  final ShoppingItem? existingItem;

  const AddEditProductScreen({super.key, this.existingItem});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    _quantityController = TextEditingController(
      text: (widget.existingItem?.quantity ?? 1).toString(),
    );
    _unitController = TextEditingController(text: widget.existingItem?.unit ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      ProductFormResult(
        name: _nameController.text.trim(),
        quantity: double.parse(_quantityController.text),
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editProduct : AppStrings.addProduct),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  decoration: const InputDecoration(labelText: AppStrings.productName),
                  validator: (value) =>
                      Validators.requiredText(value, fieldName: AppStrings.productName),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: AppStrings.quantity),
                  validator: Validators.positiveNumber,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: AppStrings.unit),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(AppStrings.save, style: AppTextStyles.button),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textSecondary)),
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
import '../../models/shopping_list_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_provider.dart';
import 'add_edit_product_screen.dart';
import 'shopping_history_screen.dart';
import 'shopping_summary_screen.dart';

/// מסך רשימת הקניות הראשי.
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

  const ShoppingListScreen({super.key, required this.householdId});

  Future<void> _openAddProduct(
    BuildContext context,
    WidgetRef ref,
    String listId,
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
    String listId,
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
    String listId,
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
    String listId,
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

  Future<void> _startShopping(BuildContext context, WidgetRef ref, String listId) async {
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
    String listId,
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
    final listIdAsync = ref.watch(shoppingListIdProvider);
    final listId = listIdAsync.value;

    final itemsAsync = listId == null
        ? const AsyncValue<List<ShoppingItem>>.loading()
        : ref.watch(shoppingItemsProvider((householdId: householdId, listId: listId)));
    final currentItems = itemsAsync.value;

    final listMetaAsync = listId == null
        ? const AsyncValue<ShoppingList>.loading()
        : ref.watch(shoppingListMetaProvider((householdId: householdId, listId: listId)));
    final activeSessionId = listMetaAsync.value?.activeSessionId;
    final isSessionActive = activeSessionId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.shoppingList),
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
            onPressed: listId == null || currentItems == null
                ? null
                : () => _openFinishShopping(
                      context,
                      ref,
                      listId,
                      currentItems,
                      activeSessionId,
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          // באנר קנייה פעילה / כפתור התחלת קנייה.
          if (listId != null)
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
                      onPressed: () => _startShopping(context, ref, listId),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(AppStrings.startShopping),
                    ),
                  ),
          Expanded(
            child: listIdAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, st) => const ErrorView(),
              data: (listId) {
                if (listId == null) return const LoadingIndicator();

                return itemsAsync.when(
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
                                      listId,
                                      item,
                                      item.status == ItemStatus.purchased
                                          ? ItemStatus.pending
                                          : ItemStatus.purchased,
                                    ),
                                    onMarkNotFound: () =>
                                        _setStatus(ref, listId, item, ItemStatus.notFound),
                                    onBackToPending: () =>
                                        _setStatus(ref, listId, item, ItemStatus.pending),
                                    onEdit: () => _openEditProduct(context, ref, listId, item),
                                    onDelete: () => _confirmDelete(context, ref, listId, item),
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: listIdAsync.maybeWhen(
        data: (listId) => listId == null
            ? null
            : FloatingActionButton(
                onPressed: () => _openAddProduct(context, ref, listId, isSessionActive),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
        orElse: () => null,
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
      subtitle: Text(
        '$quantityText$unitText · ${AppStrings.addedByLabel} ${item.addedByName} · '
        '${DateFormatter.short(item.addedAt)}'
        '${item.status == ItemStatus.notFound ? ' · ${AppStrings.statusNotFound}' : ''}',
        style: AppTextStyles.bodySecondary,
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
cat > 'lib/features/shopping/shopping_summary_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../models/shopping_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_provider.dart';

/// מסך סיכום קנייה - מוצג כשלוחצים "סיום קנייה".
///
/// מציג מה נקנה (למידע בלבד) ומה לא נמצא (עם checkbox לכל פריט -
/// מסומן = יועבר לקנייה הבאה, לא מסומן = יימחק). באישור: כל
/// הפריטים שנקנו נמחקים, הלא-נמצאים מטופלים לפי הבחירה, ונשמרת
/// רשומת סיכום בהיסטוריה - הכל בפעולה אחת אטומית.
class ShoppingSummaryScreen extends ConsumerStatefulWidget {
  final String householdId;
  final String listId;
  final List<ShoppingItem> purchasedItems;
  final List<ShoppingItem> notFoundItems;
  final int totalItemsCount;
  final String? activeSessionId;

  const ShoppingSummaryScreen({
    super.key,
    required this.householdId,
    required this.listId,
    required this.purchasedItems,
    required this.notFoundItems,
    required this.totalItemsCount,
    this.activeSessionId,
  });

  @override
  ConsumerState<ShoppingSummaryScreen> createState() => _ShoppingSummaryScreenState();
}

class _ShoppingSummaryScreenState extends ConsumerState<ShoppingSummaryScreen> {
  late final Map<String, bool> _carryOver;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ברירת מחדל: כל הפריטים שלא נמצאו מסומנים להעברה לקנייה הבאה.
    _carryOver = {for (final item in widget.notFoundItems) item.id: true};
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);

    final toCarryOver =
        widget.notFoundItems.where((item) => _carryOver[item.id] == true).toList();
    final toDrop =
        widget.notFoundItems.where((item) => _carryOver[item.id] != true).toList();

    final user = ref.read(authStateChangesProvider).value;

    try {
      await ref.read(shoppingRepositoryProvider).finishShopping(
            householdId: widget.householdId,
            listId: widget.listId,
            purchasedItems: widget.purchasedItems,
            notFoundItemsToCarryOver: toCarryOver,
            notFoundItemsToDrop: toDrop,
            totalItemsCount: widget.totalItemsCount,
            completedBy: user?.uid ?? '',
            completedByName: user?.email ?? '',
            activeSessionId: widget.activeSessionId,
          );
      if (mounted) Navigator.of(context).pop();
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.shoppingSummary)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStat(
                          label: AppStrings.itemsCountLabel,
                          value: widget.totalItemsCount.toString(),
                        ),
                      ),
                      Expanded(
                        child: _SummaryStat(
                          label: AppStrings.purchasedItemsLabel,
                          value: widget.purchasedItems.length.toString(),
                          color: AppColors.itemPurchased,
                        ),
                      ),
                      Expanded(
                        child: _SummaryStat(
                          label: AppStrings.notFoundItemsLabel,
                          value: widget.notFoundItems.length.toString(),
                          color: AppColors.itemNotFound,
                        ),
                      ),
                    ],
                  ),
                  if (widget.notFoundItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.carryOverHint,
                          style: AppTextStyles.bodySecondary,
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(() {
                                for (final id in _carryOver.keys) {
                                  _carryOver[id] = true;
                                }
                              }),
                              child: const Text(AppStrings.selectAll),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                for (final id in _carryOver.keys) {
                                  _carryOver[id] = false;
                                }
                              }),
                              child: const Text(AppStrings.clearAll),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ...widget.notFoundItems.map(
                      (item) => CheckboxListTile(
                        value: _carryOver[item.id] ?? false,
                        onChanged: (value) =>
                            setState(() => _carryOver[item.id] = value ?? false),
                        title: Text(item.name),
                        activeColor: AppColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                  if (widget.purchasedItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      '${AppStrings.purchasedItemsLabel} (${widget.purchasedItems.length})',
                      style: AppTextStyles.heading2.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    ...widget.purchasedItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '• ${item.name}',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(AppStrings.confirmFinishShopping, style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading1.copyWith(color: color ?? AppColors.textPrimary),
        ),
        Text(label, style: AppTextStyles.bodySecondary),
      ],
    );
  }
}

HMEOF
cat > 'lib/features/shopping/shopping_history_screen.dart' << 'HMEOF'
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

/// מסך היסטוריית קניות - רשימת קניות שהושלמו בעבר, לפי household.
class ShoppingHistoryScreen extends ConsumerWidget {
  final String householdId;

  const ShoppingHistoryScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shoppingHistoryProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.shoppingHistory)),
      body: historyAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => const ErrorView(),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              message: AppStrings.noHistoryYet,
              icon: Icons.history,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                title: Text(DateFormatter.short(entry.date)),
                subtitle: Text(
                  '${entry.totalItems} ${AppStrings.itemsCountLabel} · '
                  '${entry.purchasedCount} ${AppStrings.purchasedItemsLabel} · '
                  '${entry.notFoundCount} ${AppStrings.notFoundItemsLabel}',
                  style: AppTextStyles.bodySecondary,
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
cat > 'lib/features/shopping/shopping_notifications_listener.dart' << 'HMEOF'
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_strings.dart';
import '../../models/shopping_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/shopping_provider.dart';

/// עוטף את כל האפליקציה (אחרי שיש household) כדי שההאזנה להתראות
/// תפעל תמיד - לא משנה איזה מסך פתוח כרגע (Dashboard, רשימת קניות,
/// היסטוריה וכו'). בלי זה, ה-listener היה קיים רק כשמסך רשימת
/// הקניות עצמו היה על המסך, ולא היה מתריע אם המשתמש היה במקום אחר
/// באפליקציה.
///
/// לא מרנדר שום UI משלו - רק "יושב" בעץ הווידג'טים ומאזין.
class ShoppingNotificationsListener extends ConsumerWidget {
  final String householdId;
  final Widget child;

  const ShoppingNotificationsListener({
    super.key,
    required this.householdId,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listId = ref.watch(shoppingListIdProvider).value;
    final myUid = ref.watch(authStateChangesProvider).value?.uid;
    final notificationService = ref.watch(browserNotificationServiceProvider);

    if (listId != null) {
      // מוצר חדש שנוסף על ידי מישהו אחר בזמן קנייה פעילה.
      ref.listen(
        shoppingItemsProvider((householdId: householdId, listId: listId)),
        (previous, next) {
          if (previous == null) return;
          final prevIds = (previous.value ?? []).map((e) => e.id).toSet();
          for (final item in next.value ?? <ShoppingItem>[]) {
            if (!prevIds.contains(item.id) &&
                item.addedDuringShopping &&
                item.addedBy != myUid) {
              notificationService.show(
                title: AppStrings.newItemNotificationTitle,
                body: '${item.name} · ${AppStrings.addedByLabel} ${item.addedByName}',
              );
            }
          }
        },
      );

      // קנייה שהסתיימה על ידי מישהו אחר.
      ref.listen(
        shoppingHistoryProvider(householdId),
        (previous, next) {
          if (previous == null) return;
          final prevIds = (previous.value ?? []).map((e) => e.id).toSet();
          for (final entry in next.value ?? []) {
            if (!prevIds.contains(entry.id) && entry.completedBy != myUid) {
              final body = entry.notFoundItemNames.isEmpty
                  ? null
                  : '${AppStrings.notFoundNotificationBody}: ${entry.notFoundItemNames.join(", ")}';
              notificationService.show(
                title: AppStrings.shoppingDoneNotificationTitle,
                body: body,
              );
            }
          }
        },
      );
    }

    return child;
  }
}

HMEOF
echo 'DONE - all files created successfully!'
