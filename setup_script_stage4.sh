#!/bin/bash
set -e
mkdir -p lib/models lib/services/firebase lib/repositories lib/providers lib/features/household lib/features/home
cat > 'PROJECT_STATUS.md' << 'HMEOF'
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
      // 1. המשתמש כבר חבר (לעדכונים כלליים בעתיד).
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
        allow read: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/households/$(householdId)).data.memberIds;
        allow create: if request.auth != null && request.auth.uid == memberId;
        allow update: if request.auth != null && request.auth.uid == memberId;
        allow delete: if false;
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
  }
}

HMEOF
cat > 'firestore.indexes.json' << 'HMEOF'
{
  "indexes": [],
  "fieldOverrides": []
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

  // Shopping
  static const String shoppingList = 'רשימת קניות';
  static const String addProduct = 'הוספת מוצר';
  static const String productName = 'שם המוצר';
  static const String quantity = 'כמות';
  static const String noItemsYet = 'אין עדיין מוצרים ברשימה';
  static const String startShopping = 'התחל קנייה';
  static const String finishShopping = 'סיום קנייה';
}

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
import '../features/splash/splash_screen.dart';
import '../providers/household_provider.dart';

/// "שומר" שני, שרץ אחרי AuthGate (כלומר המשתמש כבר מחובר).
///
/// מאזין ל-household של המשתמש הנוכחי ומציג את המסך המתאים:
/// - עדיין בודק → Splash
/// - אין household → מסך יצירה/הצטרפות
/// - יש household → מסך הבית
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
        return const HomeScreen();
      },
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

  const Household({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.memberIds,
  });

  factory Household.fromFirestore(String id, Map<String, dynamic> data) {
    return Household(
      id: id,
      name: data['name'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
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
cat > 'lib/services/firebase/household_service.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
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
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await docRef.get();
    return Household.fromFirestore(snapshot.id, snapshot.data()!);
  }

  Future<void> joinHousehold({
    required String householdId,
    required String uid,
  }) async {
    final docRef = _households.doc(householdId);

    await docRef.update({
      'memberIds': FieldValue.arrayUnion([uid]),
    });

    await docRef.collection('members').doc(uid).set({
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }
}

HMEOF
cat > 'lib/repositories/household_repository.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/failures.dart';
import '../models/household_model.dart';
import '../services/firebase/household_service.dart';

/// השכבה שה-UI קורא לה בפועל ליצירה/הצטרפות ל-Household.
class HouseholdRepository {
  final HouseholdService _service;

  HouseholdRepository(this._service);

  Stream<Household?> watchMyHousehold(String uid) {
    return _service.watchMyHousehold(uid);
  }

  Future<Household> createHousehold({
    required String name,
    required String creatorUid,
  }) async {
    try {
      return await _service.createHousehold(name: name, creatorUid: creatorUid);
    } on FirebaseException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> joinHousehold({
    required String householdId,
    required String uid,
  }) async {
    try {
      await _service.joinHousehold(householdId: householdId.trim(), uid: uid);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw const PermissionFailure('קוד ההזמנה לא נמצא, בדקו שהעתקתם אותו נכון');
      }
      throw _mapError(e);
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
cat > 'lib/providers/household_provider.dart' << 'HMEOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(householdRepositoryProvider);
      if (_showJoinForm) {
        await repo.joinHousehold(householdId: _textController.text, uid: uid);
      } else {
        await repo.createHousehold(
          name: _textController.text.trim(),
          creatorUid: uid,
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
                  const Icon(Icons.home_rounded, size: 56, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text(
                    AppStrings.noHouseholdYet,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 32),
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
cat > 'lib/features/home/home_screen.dart' << 'HMEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../household/invite_partner_screen.dart';

/// מסך הבית הראשי - מוצג רק כשלמשתמש יש household.
/// בשלב זה עדיין placeholder יחסית, אבל כבר מציג מידע אמיתי
/// (שם ה-household, מספר חברים) ומאפשר להזמין בן/בת זוג.
/// בשלבים הבאים (Shopping List) זה יהפוך למסך המרכזי האמיתי.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(myHouseholdProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(household?.name ?? AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.signOut,
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(household?.name ?? '', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.membersCount}: ${household?.memberIds.length ?? 0}',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.group_add),
              label: const Text(AppStrings.invitePartner),
              onPressed: household == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InvitePartnerScreen(
                            householdId: household.id,
                            householdName: household.name,
                          ),
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
