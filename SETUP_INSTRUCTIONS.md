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
