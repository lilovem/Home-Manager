#!/bin/bash
set -e
mkdir -p .vscode
if [ -f .vscode/settings.json ]; then echo 'WARNING: .vscode/settings.json already exists - backing it up to settings.json.bak, then overwriting. Merge manually if you had other settings there.'; cp .vscode/settings.json .vscode/settings.json.bak; fi
cat > '.vscode/settings.json' << 'HMEOF'
{
  "VsCodeTaskButtons.showCounter": false,
  "VsCodeTaskButtons.tasks": [
    {
      "label": "🚀 הרץ",
      "task": "🚀 הרץ אפליקציה (Flutter Web)",
      "alignment": "left"
    },
    {
      "label": "💾 שמור",
      "task": "💾 שמור ל-Git (add + commit + push)",
      "alignment": "left"
    },
    {
      "label": "📦 פרוס",
      "task": "📦 בנה ופרוס לאתר (build + deploy hosting)",
      "alignment": "left"
    },
    {
      "label": "🔒 כללים",
      "task": "🔒 פרוס כללי אבטחה (Firestore Rules)",
      "alignment": "left"
    },
    {
      "label": "📥 תלויות",
      "task": "📥 התקן תלויות (flutter pub get)",
      "alignment": "left"
    }
  ]
}

HMEOF
echo 'DONE - now install the Task Buttons extension and reload the window!'
