import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

// הערה: בשלב 2 (חיבור Firebase) נוסיף כאן:
// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// לפני runApp. כרגע האפליקציה עוד לא תלויה ב-Firebase כדי שנוכל
// להריץ ולבדוק שהמבנה הבסיסי עובד.

void main() {
  runApp(
    const ProviderScope(
      child: HomeManagerApp(),
    ),
  );
}
