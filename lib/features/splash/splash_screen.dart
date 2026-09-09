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
      backgroundColor: AppColors.primary,
      body: Center(
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
    );
  }
}
