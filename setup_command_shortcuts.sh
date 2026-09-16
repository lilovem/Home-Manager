#!/bin/bash
set -e
mkdir -p .vscode
cat > '.vscode/tasks.json' << 'HMEOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "🚀 הרץ אפליקציה (Flutter Web)",
      "type": "shell",
      "command": "flutter run -d web-server --web-port=8000 --web-hostname=0.0.0.0",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "💾 שמור ל-Git (add + commit + push)",
      "type": "shell",
      "command": "git add . && git commit -m \"${input:commitMessage}\" && git push",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "📦 בנה ופרוס לאתר (build + deploy hosting)",
      "type": "shell",
      "command": "flutter build web && firebase deploy --only hosting --project home-manager-9407a",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "🔒 פרוס כללי אבטחה (Firestore Rules)",
      "type": "shell",
      "command": "firebase deploy --only firestore:rules --project home-manager-9407a",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "📥 התקן תלויות (flutter pub get)",
      "type": "shell",
      "command": "flutter pub get",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ],
  "inputs": [
    {
      "id": "commitMessage",
      "type": "promptString",
      "description": "הודעת ה-commit",
      "default": "עדכון"
    }
  ]
}

HMEOF
cat > 'COMMANDS.md' << 'HMEOF'
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

HMEOF
echo 'DONE - task shortcuts installed! Use Terminal -> Run Task... in VS Code menu.'
