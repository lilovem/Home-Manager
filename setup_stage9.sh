bash setup_stage9.shgit add .
git commit -m "Stage 9: Shopping completion + history with atomic batch writes"
git push#!/bin/bash
set -e
cat > 'PROJECT_STATUS.md' << 'HMEOF'
# PROJECT_STATUS.md — Home Manager

> קובץ זה מתעדכן אחרי כל שלב משמעותי. אם פותחים שיחה/session חדש/ה,
> יש לקרוא קובץ זה **וגם** את הקוד הקיים לפני שממשיכים לפתח.

---

## שלב נוכחי
**שלב 9 — Shopping Completion + History** ✅ הושלם בקוד (טרם נבדק בפועל)

## השלב הבא
**שלב 7+8 יחד — Active Shopping + Push Notifications** (מצב "קנייה פעילה" עם התראות בזמן אמת כשמוסיפים מוצר - שני השלבים יחד כי הערך האמיתי הוא השילוב ביניהם)

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
- טרם נבדק בפועל אצל המשתמש (סיום קנייה, בחירת פריטים להעברה, היסטוריה).
- אין עדיין "קנייה פעילה" (Active Shopping) ואין Push Notifications - שלב 7+8 יבואו יחד.
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
13. **שלבים 7+8 (Active Shopping + Push Notifications) ממוזגים** — שלב 9 (Shopping Completion) נבנה לפני 7/8 כי הוא עומד בפני עצמו ונותן ערך מיידי. "קנייה פעילה" בלי התראות היא רק דגל טכני חסר תועלת מורגשת - נבנה את שניהם יחד כדי שהערך (התראה בזמן אמת) יהיה מורגש מהרגע הראשון.
14. **finishShopping כ-WriteBatch אטומי** — כל הפעולות של סיום קנייה (מחיקת פריטים שנקנו, טיפול בלא-נמצאו, שמירת היסטוריה) מתבצעות ב-batch אחד, כדי שלא יהיה מצב ביניים לא עקבי (למשל: פריטים נמחקו אבל ההיסטוריה לא נשמרה) אם החיבור נופל באמצע.

---

## הוראות הפעלה (למשתמש)
ראה קובץ `SETUP_INSTRUCTIONS.md` שנשלח יחד עם קבצי הפרויקט.

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
        allow delete: if false;
      }

      // רשימות קניות - רק חברי ה-household יכולים לקרוא/לכתוב.
      match /shoppingLists/{listId} {
        allow read, write: if isHouseholdMember(householdId);

        // פריטים בתוך רשימה - אותה הרשאה: רק חברי ה-household.
        match /items/{itemId} {
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

  const ShoppingHistoryEntry({
    required this.id,
    required this.date,
    required this.totalItems,
    required this.purchasedCount,
    required this.notFoundCount,
    required this.notFoundItemNames,
  });

  factory ShoppingHistoryEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return ShoppingHistoryEntry(
      id: id,
      date: (data['date'] as Timestamp?)?.toDate(),
      totalItems: (data['totalItems'] as num?)?.toInt() ?? 0,
      purchasedCount: (data['purchasedCount'] as num?)?.toInt() ?? 0,
      notFoundCount: (data['notFoundCount'] as num?)?.toInt() ?? 0,
      notFoundItemNames: List<String>.from(data['notFoundItemNames'] as List? ?? []),
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required int totalItems,
    required int purchasedCount,
    required int notFoundCount,
    required List<String> notFoundItemNames,
  }) {
    return {
      'date': FieldValue.serverTimestamp(),
      'totalItems': totalItems,
      'purchasedCount': purchasedCount,
      'notFoundCount': notFoundCount,
      'notFoundItemNames': notFoundItemNames,
    };
  }
}

HMEOF
cat > 'lib/services/firebase/shopping_service.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/household_model.dart';
import '../../models/shopping_history_model.dart';
import '../../models/shopping_item_model.dart';
import '../../models/shopping_list_model.dart';

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
  }) {
    return _itemsCollection(householdId, listId).add(
      ShoppingItem.toFirestoreForCreate(
        name: name,
        quantity: quantity,
        unit: unit,
        addedBy: addedBy,
        addedByName: addedByName,
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
      batch.update(itemsRef.doc(item.id), ShoppingItem.statusUpdate(ItemStatus.pending));
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
cat > 'lib/repositories/shopping_repository.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failures.dart';
import '../models/household_model.dart';
import '../models/shopping_history_model.dart';
import '../models/shopping_item_model.dart';
import '../services/firebase/shopping_service.dart';

class ShoppingRepository {
  final ShoppingService _service;

  ShoppingRepository(this._service);

  Future<String> getOrCreateDefaultListId(Household household) {
    return _service.getOrCreateDefaultListId(household);
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
  }) async {
    try {
      await _service.finishShopping(
        householdId: householdId,
        listId: listId,
        purchasedItems: purchasedItems,
        notFoundItemsToCarryOver: notFoundItemsToCarryOver,
        notFoundItemsToDrop: notFoundItemsToDrop,
        totalItemsCount: totalItemsCount,
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
cat > 'lib/providers/shopping_provider.dart' << 'HMEOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_history_model.dart';
import '../models/shopping_item_model.dart';
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

HMEOF
cat > 'lib/features/shopping/shopping_summary_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../models/shopping_item_model.dart';
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

  const ShoppingSummaryScreen({
    super.key,
    required this.householdId,
    required this.listId,
    required this.purchasedItems,
    required this.notFoundItems,
    required this.totalItemsCount,
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

    try {
      await ref.read(shoppingRepositoryProvider).finishShopping(
            householdId: widget.householdId,
            listId: widget.listId,
            purchasedItems: widget.purchasedItems,
            notFoundItemsToCarryOver: toCarryOver,
            notFoundItemsToDrop: toDrop,
            totalItemsCount: widget.totalItemsCount,
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

/// מסך רשימת הקניות הראשי.
/// מציג את הפריטים בזמן אמת (StreamProvider), עם אפשרות
/// להוסיף/לערוך/למחוק/לשנות סטטוס - הכל מתעדכן מיידית אצל
/// כל חברי ה-household בזכות Firestore streams.
class ShoppingListScreen extends ConsumerWidget {
  final String householdId;

  const ShoppingListScreen({super.key, required this.householdId});

  Future<void> _openAddProduct(BuildContext context, WidgetRef ref, String listId) async {
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

  Future<void> _openFinishShopping(
    BuildContext context,
    WidgetRef ref,
    String listId,
    List<ShoppingItem> items,
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
                : () => _openFinishShopping(context, ref, listId, currentItems),
          ),
        ],
      ),
      body: listIdAsync.when(
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
      floatingActionButton: listIdAsync.maybeWhen(
        data: (listId) => listId == null
            ? null
            : FloatingActionButton(
                onPressed: () => _openAddProduct(context, ref, listId),
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
      title: Text(
        item.name,
        style: AppTextStyles.body.copyWith(
          color: _statusColor,
          decoration:
              item.status == ItemStatus.purchased ? TextDecoration.lineThrough : null,
        ),
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
echo 'DONE - Shopping Completion + History added!'
