#!/bin/bash
set -e
mkdir -p web/icons
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
cat > 'lib/app/config/app_colors.dart' << 'HMEOF'
import 'package:flutter/material.dart';

/// פלטת הצבעים המרכזית של האפליקציה.
///
/// אף widget לא אמור להשתמש בצבע "קשיח" (כמו Colors.blue ישירות).
/// במקום זאת, תמיד יש להשתמש בקבועים מהמחלקה הזו.
/// כך שינוי "צבע המותג" בעתיד יהיה שינוי במקום אחד בלבד.
class AppColors {
  AppColors._();

  // צבעי בסיס - עודכן לכחול לפי הלוגו (Smart Home) שנבחר.
  static const Color primary = Color(0xFF00A3DA); // כחול ראשי
  static const Color primaryDark = Color(0xFF0075AA); // כחול כהה - לגרדיאנטים
  static const Color primaryLight = Color(0xFFE1F5FB);
  static const Color background = Color(0xFFFFFFFF); // לבן
  static const Color surface = Color(0xFFF5F5F5); // אפור בהיר

  // טקסט
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  // סטטוסים של מוצרים ברשימת הקניות - אלה צבעים סמנטיים (משמעות
  // קבועה: הצלחה/אזהרה), לא צבעי מותג - נשארים גם אחרי שינוי הצבע הראשי.
  static const Color itemPurchased = Color(0xFF2E7D5B); // ירוק - נקנה
  static const Color itemNotFound = Color(0xFFE65100); // כתום - לא נמצא
  static const Color itemNewBadge = Color(0xFF7B1FA2); // סגול - "חדש" (שונה מהכחול הראשי כדי לא להתבלבל)

  // מצבי שגיאה/אזהרה
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);

  // גבולות וחלוקות
  static const Color divider = Color(0xFFE0E0E0);
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
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.itemPurchased
                : AppColors.background,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.textPrimary,
        ),
      ),
    );
  }
}

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Center(
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
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
    const message = 'בוא תנסה את Home Manager - אפליקציה לניהול משק הבית! 🏠\n'
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
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
                  child: TextButton.icon(
                    onPressed: () => ref.read(browserNotificationServiceProvider).show(
                          title: AppStrings.testNotificationTitle,
                          body: AppStrings.testNotificationBody,
                        ),
                    icon: const Icon(Icons.notifications_active_outlined, size: 18),
                    label: const Text(AppStrings.testNotificationButton),
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
base64 -d > 'web/icons/Icon-192.png' << 'B64EOF'
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
B64EOF
base64 -d > 'web/icons/Icon-512.png' << 'B64EOF'
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
B64EOF
base64 -d > 'web/icons/Icon-maskable-192.png' << 'B64EOF'
iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAYAAABS3GwHAAALp0lEQVR4nO2dTW7k2BGEQ4Kv4kN0z3h+fA7fYbp7/nwDA4Z3NjAHsK9hwPByAF/APgy9aZGPYiQrSb6sYpW+2CQrI0i9xUe1gIDUT/r7fwcNg1Z11NcgrUY6+M0o88NMR99mOvuLVYE/Wxf5o7XffwZ+4O/uz9bnhV+Snldd4LeXJb7NAH+oDvBrGFZeAOC3lyW+zQB/qE7wS9G/AMBvL0t8mwH+UB3hl9wLAPz2ssS3GeAP1Rl+6fULAPz2ssS3GeAPVQC/1L4AwG8vS3ybAf5QRfBLLy8A8NvLEt9mgD9UIfxSjx4A+PO+zQB/qGL4paM9APDnfZsB/lBXgP9YDwD8ed9mgD/UleCX9vYAwJ/3bQb4Q10RfmlPDwD8ed9mgD/UleGXtvYAwJ/3bQb4Q90AfmlLDwD8ed9mgD/UjeCXsj0A8Od9mwH+UDeEX8r0AMCf920G+EPdGH7pUg8A/HnfZoA/1AngX+8BgD/v2wzwhzoJ/FL4LwDwp32bAf5QJ4Jfsi8A8Kd9mwH+UCeDX1q8AMCf9m0G+EOdEH5p9gIAf9q3GeAPdVL4pfEFAP60bzPAH+rE8EvSM/ADf4k/WueFX5KegT/p2wzwh7oD+KXqHqAZZX6YAX4r4J8OMVT2AM0o88MM8FsB/3SIz5GaHqAZZX6YAX4r4J8O0UT69wDNKPPDDPBbAf90iFeRvj1AM8r8MAP8VsA/HcJE+vUAzSjzwwzwWwH/dIgg0qcHaEaZH2aA3wr4p0OsRI73AM0o88MM8FsB/3SIC/we6wGaUeaHGeC3Av7pEIlv7vt7gGaU+WEG+K2AfzpE8iebfT1AM8r8MAP8VsA/HSIJv7SnB2hGmR9mgN8K+KdDbIBf2toDNKPMDzPAbwX80yE2wi9t6QGaUeaHGeC3Av7pEDvgl7I9QDPK/DAD/FbAPx1iJ/xSpgdoRpkfZoDfCvinQxyAX7rUAzSjzA8zwG8F/NMhDsKvYa0HaEaZH2aA3wr4p0N0gF+KeoBmlPlhBvitgH86RCf4JdcDNMPe3MMPM8BvBfzTITrCL73uAZphb+7hhxngtwL+6RCd4ZfaHqAZ9uYefpgBfivgnw5RAL/00gN8zoQ39/DDDPBbAf90iCL4pfF/iFm5uYcfZoDfCvinQxTCLw1rRRjwr39J4C/1rwC/VN0DhBngtwL+6RBXgF9DZQ8QZoDfCvinQ1wJfqmqBwgzwG8F/NMhrgi/VNEDhBngtwL+6RBXhl/q3QOEGeC3Av7pEDeAX+rZA4QZ4LcC/ukQN4Jf6tUDhBngtwL+6RA3hF/q0QOEGeC3Av7pEDeGXzraA4QZ4Lcy8A7fvVv1L93vM8DfjjV/fw8QZoDfagX+4bt3wN/Tb8Ylf18PEGaA3+rSd35Jw4d3m+73GeBvR8bf3gOEGeC3SsA/7j+8T93vM8Dfjqy/rQcIM8BvtQH+0W9fAuDP+83Y4ud7gDAD/FY74B9zH94D/xa/GVv9XA8QZoDf6gD8Y/7j+/j546OBvx17/Ms9QPgA4LfqAP9FAb96wC9d6gHCBwC/VWf4h49fBF8D+NtxxI97gPABwG9V9J1/9hIAv3rCL0U9QPgA4Lcy8PfU8PEL4H/xm9HDX/YA4QOA3yqAv/fP/cMn8+PQ7EsD/x7/ebEF/pw/W9fCPz7305fBGYB/r/+sLfACv1lfB/7x+e1LAPyH/efXOXtzD99mgH+Phk9fAn8nf6UIA36rG8M/fr3vzY9DswDwZ/ygCAN+q5PAP37d738XGMCf8lXdA9gM8PfU4iUA/pz/+bKuB7AZ4K/Q+BIAf85vLmt6AJsB/lIBf85/ddm/B7AZ4K/W8MNXKybwu0updw9gM8B/LdmXAPjt5Yv69QA2A/zX1uwlAH572S779AA2A/y30vDDV8Cf5Pd4D2AzwH9rDT9+vWIC/4uO9QA2A/xnkX0JgH92ub8HsBngP5tmLwHwLy739QA2A/xn1fDj18Af+Nt7AJt5LPgfUcNP36y5bxJ+aWsPYDOPB/8jffdv5V+Ctwu/tKUHsBngvzfNX4K3Db+U7QFsBvjvW8AvZXoA+wDgv2cNP30D/J+13gPYBwD/I2j4+dvIeTPwa1jrAewDgP+RtHwJ3hb8UtQD2AcA/yNqegneHvyS6wHsA4D/kTX8/O2bhF963QPYBwD/W9Dwx99HzsPCL0lP+uU/Qxx4PPiP+PavNZ9UT3/+l7r8WPPA8EvDWhEG/Pct4M/4QREG/Hcv4E/5pggD/scW8Leq7QEWqzuG/yHeC+B//bGuB1is7h3+e38DgN99rOkBFivgv62AP/rYvwdYrID/tgL+tY/PaybwA387yvwwUwu/1LMHWKyA/7YC/rWPL4vfrJmXbo5XwO/09I//pbPDH3577IsB/0pmWhzvARYr4HfaAv+efF7A3+pYD7BYPTD89/4TkSTgX/r7e4DF6tHhv/c3APjdx309wGIF/OcW8Ecft/cAixXwn1vAv/ZxWw+wWAH/uQX8l/x8D7BYAf+5BfwZP/f7AIsV8J9ewJ/yL/cAixXw37eAv9V6D7BYAf99C/hff4x7gMXqjcN/8e/rn13A7z76HmCxAv77FvBHH5c9wCIP/Pct4F/7uPzjuMDfZIA/5YeZc8MvDWtFGPC/1tNf/r1+z0n09Kd/CvhzflCEAf99C/iz/pP+9usA/G3msr/6n1CvqPoXYvjOv91/0l9/XT8R8PfzNVw4Qge/GWV+mLkv+KXqHmC2Bn7gT/o20x9+DZU9wGwN/MCf9G2mBn6pqgeYrYEf+JO+zdTBL1X0ALM18AN/0reZWvil3j3AbA38wJ/0baYefqlnDzBbAz/wJ32buQ78kv2FGOA/5AN/3reZ68EvLX4hBvgP+cCf923muvBLR3uA2Rr4gT/p28z14ddwpAeYrYEf+JO+zdwGfmlvDzBbAz/wJ32buR380p4eYLYGfuBP+jZzW/ilrT3AbA38wJ/0beb28EtbeoDZGviBP+nbzDngl7I9wGwN/MCf9G3mPPBLmR5gtgZ+4E/6NnMu+KVLPcBsDfzAn/Rt5nzwa1jrAWZr4Af+pG8z54RfinqA2T3AD/xJ32bOC7/keoBZAPiBP+nbzLnhl173ALMA8AN/0reZ88Mvhf9DDPADf9K3mfuAX7JFGPADf9K3mfuBX1oUYcAP/EnfZu4LfmlWhAE/8Cd9m7k/+KXqHmC0gL8dZX6YAX6robIHGC3gb0eZH2aA3+rzuqYHGC3gb0eZH2aA36rht38PMFrA344yP8wAv9Urfvv2AKMF/O0o88MM8FsZfvv1AKMF/O0o88MM8FsF/PbpAUYL+NtR5ocZ4Lda4fd4DzBawN+OMj/MAL/VBX6P9QCjBfztKPPDDPBbJb657+8BRgv421Hmhxngt0rAL+3tAUYL+NtR5ocZ4LdKwi/t6QFGC/jbUeaHGeC32gC/tLUHGC3gb0eZH2aA32oj/NKWHmC0gL8dZX6YAX6rHfBL2R5gtIC/HWV+mAF+q53wS5keYLSAvx1lfpgBfqsD8EuXeoDRAv52lPlhBvitDsKvYa0HGO8D/naU+WEG+K06wC9FPcAYAP52lPlhBvitOsEvuR5gDAB/O8r8MAP8Vh3hl8L/IQb421Hmhxngt+oMv2SLMOBvR5kfZoDfqgB+aVGEAX87yvwwA/xWRfBLsyIM+NtR5ocZ4LcqhF8aizDgb0eZH2aA36oYfuloDyABP/D392frOvg1HOkBJOAH/v7+bF0Lv7S3B5CAH/j7+7N1PfzSnh5AAn7g7+/P1teBX9raA0jAD/z9/dn6evBLW3oACfiBv78/W18XfinbA0jAD/z9/dn6+vBLmR5AAn7g7+/P1reBX7rUA0jAD/z9/dn6dvBrWOsBJOAH/v7+bH1b+KWoB5CAH/j7+7P17eGXwr8MB/wpP8wAv9XJ4JdsEQb8KT/MAL/VCeGXFkUY8Kf8MAP8VieFX5oVYcCf8sMM8FudGH5J+j/0HEKQd/HKCQAAAABJRU5ErkJggg==
B64EOF
base64 -d > 'web/icons/Icon-maskable-512.png' << 'B64EOF'
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
B64EOF
base64 -d > 'web/favicon.png' << 'B64EOF'
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAFKElEQVR4nLWXS4gcVRSGv3Pr0fPOJA4+EV8xZlyokIWITqKgITiERDFxJW4kBt0ZyMqNEAz4WLiLbly4chQxaiSCmMQQzUYUERR8orjwMZh59aOq7jkuqqq7umd6ZjR64XbXreq+3z3/+e+pKgFgxgL2i+fAgYi7Dj2N6j2E0RSthgIONcDAyL/LMXSOrXLdusZKWHOkrbM4d4qvvjjCK4+nJVOYmQnYv9/z8pf3smHDIaLaLpbmIWmBCKh2w8vJ1wfPu1eIYqgNQ9o6ydLsixy+70NmZgIB4NVv7qQ2cBbnhKW5FCTII79IePX3ZoqqZ3AkwmdGsznF4e3nhFc/H4f4bYZGd7AwlyASd8n838Ar/9WEgZGY5sIZQtvrIDrI2MQOFudSxP1/8LKLxNTnU4Y37qDFQYeym/qC5rLrP4ILELQha8DLsSoIAY1FxWy38Np3RqsBCNj6cy4C5hVSj4sDVHVtuFWCU4W4hqPV0Hy29cOdgKUZY3HA3deOo/WE0LF+uBXytZrqAPdP4XhPYPD6rhs49eAku7ZsIltIiJx0AKvBaV93rp2/dcqO94gaxx/Yyq5rxvEG7+2Z5P7JCdLFhGglJZbBOzzXWc06DKeKU+P4nq1MXzNOqoYAgvDOnpuZnpwgXUoInKweeaW79W61ECNrZby1ZyvT1+bwyEmektzCHN97M3ddN45vpIRCHzhdx2498MgJ6VLC7psm2F2Bl80JKEYgwrPbrycQUK84pD+ctgKVnPSDL7aY3noJb91/I5kZYQVetlAEb8bUVWMcf/hWxCt4zRXSClwrPMoFLPNBJ7J0rsnOzZt4c3oLToRAhOX4vAUipGpMX7+JN/fdgqYZmvjcvGbdAXYUWClHEGBI4nl02xV88MAkA4FDhL7wspWp2bt5gvOP3c5lgxHiDSnD7vFA2C9HakYUOq4ejXnm/C9EznFo25XUihuoGvjSNwVYzXAinP75Ah9++wcbR2psvnSY336YxUWF2D2eC3v3ZXnRDBJTjpz5CTKFgZAnb7ucWhBgRXqcdOuRGcQCJ77/kxfe/xqGYwgEIof2+quzu3plqYwxoqEIvDJaC5HirACnf6tz+tc6EgqxE56a3JiXY2A0DohGYqLhmGbme+CVIlVs75XhxTjDMG9k3ndF+/6vSzz/6e9QCyB2PHHTOGNF/lWNtNgFq8FzD6x5PwfIHw29WelRRiJHNBQitYCxyLXVyXdadY7V60zYm5PlK81PCzAWh7i2BvmWE4OFTAlE2p4YjoICRB94h9epAyvBzTDLi0mzkXLih1nmE8984mmkWX49zbjjkhr1NGOulfFnPeGjH2cL42mfyDvHwkvnrR+8HAtgmQfJVcCMliqtLAeMxw5TwzBUjcV6krt/lfLeSQGmYK4fPFfBiqcQY76RdGQsKtyFetY1uQscaromHDN1RLHD94f3FipxIF0l0UAEcUUX1oZDHncUO0ez8QlxrJhpf3hpSMVKRbD8ua7tFSumWEt2y1cYxErS+MSBvUtt2KGVjb4ivGeyf/vonkfvqQ06VN51SHaMhdkzDI5GqE/aC/i/4GoJteGIxb/O0JRjeSaf+/hOBgbPIk6oz6WIBMtu1RcFzw2XRz4U5aWyPsXRh845ZmYCDm8/x9KFnZieZHRTRBBV3gv/C7hCEDqGNkSonaQ+v5OjD51jX/lyWn093/LI02h2D0E8RdJQrCh+qh1/lC5uLwyKj0oF1E7kUexIk7Mgp/jgxBE+eyVl30zAG/v931lGLXnMYbcIAAAAAElFTkSuQmCC
B64EOF
echo 'DONE - blue color + design polish, same logo shape!'
