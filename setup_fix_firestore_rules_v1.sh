#!/bin/bash
set -e
echo "=== מתקן את קובץ כללי האבטחה (firestore.rules) ==="

echo "כותב firestore.rules..."
cat > firestore.rules << 'FIX_RULES_EOF'
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // כלל אבטחה כללי: כל מי שמחובר (מאומת) לאפליקציה - יכול לקרוא
    // ולכתוב לכל מסמך. זה לא פתוח לכולם (צריך התחברות), אבל גם לא
    // דורש בדיקת שייכות מפורטת ל-household - מתאים לאפליקציה
    // פרטית למשפחה/חברים כרגע. אפשר להדק בהמשך אם צריך.
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
FIX_RULES_EOF

echo ""
echo "=== הקובץ תוקן! ==="
echo "עכשיו חובה להריץ כדי שהתיקון באמת ייכנס לתוקף:"
echo "firebase deploy --only firestore:rules --project home-manager-9407a"
