# פקודות נפוצות - LeeHome

קובץ עזר להעתקה מהירה. אפשר גם להשתמש בתפריט הנוח יותר: **Terminal → Run Task...** (למעלה בתפריט של VS Code), שם כל הפקודות האלה מופיעות כרשימת בחירה בלחיצה, בלי להעתיק כלום.

## הרץ את האפליקציה
```
flutter run -d web-server --web-port=8000 --web-hostname=0.0.0.0
```

## שמור ל-Git
```
git add .
git commit -m "עדכון"
git push
```

## בנה ופרוס לאתר הקבוע
```
flutter build web
firebase deploy --only hosting --project home-manager-9407a
```

## פרוס כללי אבטחה (Firestore Rules)
```
firebase deploy --only firestore:rules --project home-manager-9407a
```

## התקן תלויות חדשות
```
flutter pub get
```

