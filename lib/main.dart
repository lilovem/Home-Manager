import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'firebase_options.dart';

/// נקודת הכניסה של האפליקציה.
///
/// לפני הרצת ה-UI, מאתחלים חיבור בפועל לפרויקט Firebase שלנו
/// (Home Manager). ה-`DefaultFirebaseOptions` נוצר אוטומטית על ידי
/// `flutterfire configure` ומכיל את מפתחות/הגדרות הפרויקט הספציפי שלנו.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: HomeManagerApp(),
    ),
  );
}
