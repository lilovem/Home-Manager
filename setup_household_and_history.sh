
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

      // מחיקה מותרת רק למי שיצר את ה-household (הבעלים) - פעולה
      // הרסנית, לא לכל חבר.
      allow delete: if request.auth != null && request.auth.uid == resource.data.createdBy; בתוך household - כל משתמש יכול ליצור/לעדכן
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

  /// מאזין לכל ה-households שהמשתמש חבר בהם.
  Stream<List<Household>> watchMyHouseholds(String uid) {
    return _households.where('memberIds', arrayContains: uid).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Household.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
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

  /// מוחקת household לגמרי - כולל כל תת-האוספים שלו (members,
  /// shoppingLists + items + sessions, shoppingHistory). מיועד
  /// לשימוש רק ע"י הבעלים (createdBy) - נאכף גם ב-Security Rules.
  Future<void> deleteHousehold(String householdId) async {
    final docRef = _households.doc(householdId);

    // מוחקים את כל מסמכי members.
    final membersSnapshot = await docRef.collection('members').get();
    for (final doc in membersSnapshot.docs) {
      await doc.reference.delete();
    }

    // מוחקים כל shoppingList, כולל items ו-sessions שבתוכו.
    final listsSnapshot = await docRef.collection('shoppingLists').get();
    for (final listDoc in listsSnapshot.docs) {
      final itemsSnapshot = await listDoc.reference.collection('items').get();
      for (final item in itemsSnapshot.docs) {
        await item.reference.delete();
      }
      final sessionsSnapshot = await listDoc.reference.collection('sessions').get();
      for (final session in sessionsSnapshot.docs) {
        await session.reference.delete();
      }
      await listDoc.reference.delete();
    }

    // מוחקים את היסטוריית הקניות.
    final historySnapshot = await docRef.collection('shoppingHistory').get();
    for (final doc in historySnapshot.docs) {
      await doc.reference.delete();
    }

    // לבסוף, מוחקים את מסמך ה-household עצמו.
    await docRef.delete();
  }

  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return _households.doc(householdId).collection('members').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => HouseholdMember.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// משלים/מעדכן את שדה ה-email על מסמך החברות של המשתמש הנוכחי.
  /// נועד לתקן households ישנים שנוצרו לפני שהשדה הזה נוסף - כל
  /// משתמש "מתקן" את הרשומה של עצמו בפעם הבאה שהוא נכנס לאפליקציה.
  Future<void> ensureMemberEmail({
    required String householdId,
    required String uid,
    required String email,
  }) {
    return _households.doc(householdId).collection('members').doc(uid).set(
      {'email': email},
      SetOptions(merge: true),
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

  Stream<List<Household>> watchMyHouseholds(String uid) {
    return _service.watchMyHouseholds(uid);
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

  Future<void> deleteHousehold(String householdId) async {
    try {
      await _service.deleteHousehold(householdId);
    } on FirebaseException {
      throw const UnknownFailure('שגיאה במחיקת משק הבית');
    }
  }

  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return _service.watchMembers(householdId);
  }

  Future<void> ensureMemberEmail({
    required String householdId,
    required String uid,
    required String email,
  }) async {
    try {
      await _service.ensureMemberEmail(householdId: householdId, uid: uid, email: email);
    } on FirebaseException {
      // שגיאה בתיקון רקע לא קריטית - לא מציגים למשתמש.
    }
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
///
/// מחיקת household בשלמותו כן מוגבלת רק לבעלים (isOwner) - זו פעולה
/// הרסנית יותר (מוחקת גם רשימות/היסטוריה), לכן ההגבלה מחמירה יותר.
class HouseholdMembersScreen extends ConsumerWidget {
  final String householdId;
  final bool isOwner;

  const HouseholdMembersScreen({
    super.key,
    required this.householdId,
    this.isOwner = false,
  });

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

  Future<void> _confirmDeleteHousehold(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.confirmDeleteHouseholdTitle),
        content: const Text(AppStrings.confirmDeleteHouseholdMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.deleteHousehold, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(householdRepositoryProvider).deleteHousehold(householdId);
      // ה-household נעלם אוטומטית מ-myHouseholdsProvider; חוזרים
      // למסך הבית (currentHouseholdProvider יבחר household אחר או
      // יעביר למסך יצירה/הצטרפות אם לא נשאר אף אחד).
      if (context.mounted) Navigator.of(context).pop();
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
      body: Column(
        children: [
          Expanded(
            child: membersAsync.when(
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
          ),
          if (isOwner)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _confirmDeleteHousehold(context, ref),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text(
                  AppStrings.deleteHousehold,
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
        ],
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
  final List<String> purchasedItemNames;
  final List<String> carriedOverItemNames;
  final List<String> droppedItemNames;

  const ShoppingHistoryEntry({
    required this.id,
    required this.date,
    required this.totalItems,
    required this.purchasedCount,
    required this.notFoundCount,
    required this.notFoundItemNames,
    required this.completedBy,
    required this.completedByName,
    this.purchasedItemNames = const [],
    this.carriedOverItemNames = const [],
    this.droppedItemNames = const [],
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
      purchasedItemNames: List<String>.from(data['purchasedItemNames'] as List? ?? []),
      carriedOverItemNames: List<String>.from(data['carriedOverItemNames'] as List? ?? []),
      droppedItemNames: List<String>.from(data['droppedItemNames'] as List? ?? []),
    );
  }

  static Map<String, dynamic> toFirestoreForCreate({
    required int totalItems,
    required int purchasedCount,
    required int notFoundCount,
    required List<String> notFoundItemNames,
    required String completedBy,
    required String completedByName,
    List<String> purchasedItemNames = const [],
    List<String> carriedOverItemNames = const [],
    List<String> droppedItemNames = const [],
  }) {
    return {
      'date': FieldValue.serverTimestamp(),
      'totalItems': totalItems,
      'purchasedCount': purchasedCount,
      'notFoundCount': notFoundCount,
      'notFoundItemNames': notFoundItemNames,
      'completedBy': completedBy,
      'completedByName': completedByName,
      'purchasedItemNames': purchasedItemNames,
      'carriedOverItemNames': carriedOverItemNames,
      'droppedItemNames': droppedItemNames,
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
    String? note,
  }) {
    return _itemsCollection(householdId, listId).add(
      ShoppingItem.toFirestoreForCreate(
        name: name,
        quantity: quantity,
        unit: unit,
        addedBy: addedBy,
        addedByName: addedByName,
        addedDuringShopping: addedDuringShopping,
        note: note,
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
    String? note,
  }) {
    final data = ShoppingItem(
      id: itemId,
      name: '',
      quantity: 0,
      status: ItemStatus.pending,
      addedBy: '',
      addedByName: '',
      addedAt: null,
    ).toFirestoreForUpdate(name: name, quantity: quantity, unit: unit, note: note);

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
        purchasedItemNames: purchasedItems.map((e) => e.name).toList(),
        carriedOverItemNames: notFoundItemsToCarryOver.map((e) => e.name).toList(),
        droppedItemNames: notFoundItemsToDrop.map((e) => e.name).toList(),
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
cat > 'lib/features/shopping/shopping_history_detail_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/shopping_history_model.dart';

/// מסך פירוט קנייה בודדת מההיסטוריה - מציג את כל המוצרים לפי קטגוריה:
/// מה נקנה, מה לא נמצא והועבר לקנייה הבאה, ומה לא נמצא ונמחק.
class ShoppingHistoryDetailScreen extends StatelessWidget {
  final ShoppingHistoryEntry entry;

  const ShoppingHistoryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    // תמיכה לאחור: רשומות ישנות לא הפרידו בין "הועבר" ל"נמחק" -
    // אם שני השדות החדשים ריקים אבל יש notFoundItemNames ישן,
    // מציגים אותו כקטגוריה אחת כללית של "לא נמצא".
    final hasDetailedBreakdown =
        entry.carriedOverItemNames.isNotEmpty || entry.droppedItemNames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(DateFormatter.short(entry.date))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: AppStrings.itemsCountLabel,
                  value: entry.totalItems.toString(),
                ),
              ),
              Expanded(
                child: _StatCard(
                  label: AppStrings.purchasedItemsLabel,
                  value: entry.purchasedCount.toString(),
                  color: AppColors.itemPurchased,
                ),
              ),
              Expanded(
                child: _StatCard(
                  label: AppStrings.notFoundItemsLabel,
                  value: entry.notFoundCount.toString(),
                  color: AppColors.itemNotFound,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (entry.purchasedItemNames.isNotEmpty)
            _ItemSection(
              title: AppStrings.purchasedItemsLabel,
              items: entry.purchasedItemNames,
              icon: Icons.check_circle_outline,
              color: AppColors.itemPurchased,
            ),
          if (hasDetailedBreakdown) ...[
            if (entry.carriedOverItemNames.isNotEmpty)
              _ItemSection(
                title: AppStrings.carriedOverSectionTitle,
                items: entry.carriedOverItemNames,
                icon: Icons.arrow_forward,
                color: AppColors.itemNotFound,
              ),
            if (entry.droppedItemNames.isNotEmpty)
              _ItemSection(
                title: AppStrings.droppedSectionTitle,
                items: entry.droppedItemNames,
                icon: Icons.close,
                color: AppColors.textSecondary,
              ),
          ] else if (entry.notFoundItemNames.isNotEmpty)
            _ItemSection(
              title: AppStrings.notFoundItemsLabel,
              items: entry.notFoundItemNames,
              icon: Icons.error_outline,
              color: AppColors.itemNotFound,
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatCard({required this.label, required this.value, this.color});

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

class _ItemSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _ItemSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${items.length})',
            style: AppTextStyles.heading2.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (name) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
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
import 'shopping_history_detail_screen.dart';

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
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShoppingHistoryDetailScreen(entry: entry),
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
echo 'DONE - delete household (owner-only) + shopping history detail view!'
