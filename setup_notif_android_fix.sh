#!/bin/bash
set -e
cat > 'lib/services/notifications/browser_notification_service_web.dart' << 'HMEOF'
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// מימוש אמיתי של התראות דפדפן, פועל רק על Flutter Web.
/// לא נטען כלל בבנייה למובייל (Android/iOS) - ראה את קובץ ה-stub.
class BrowserNotificationService {
  Future<bool> requestPermission() async {
    if (!html.Notification.supported) return false;
    final permission = await html.Notification.requestPermission();
    return permission == 'granted';
  }

  bool get isPermissionGranted =>
      html.Notification.supported && html.Notification.permission == 'granted';

  /// 'granted' | 'denied' | 'default' (עדיין לא נשאל) | 'unsupported'
  String get permissionStatus =>
      html.Notification.supported ? (html.Notification.permission ?? 'default') : 'unsupported';

  void show({required String title, String? body}) async {
    if (!isPermissionGranted) return;

    // אנדרואיד Chrome חוסם את הבנאי הישיר Notification() - חובה
    // לעבור דרך Service Worker. זה עובד גם בדסקטופ (Flutter web
    // כבר רושם Service Worker משלו כברירת מחדל), אז זו הדרך
    // הבטוחה ביותר בכל הפלטפורמות.
    final registration = await html.window.navigator.serviceWorker?.ready;
    if (registration != null) {
      registration.showNotification(title, {'body': body ?? ''});
    } else {
      // נפילה חזרה לבנאי הישיר - עובד בדפדפנים ללא Service Worker.
      html.Notification(title, body: body ?? '');
    }
  }
}

HMEOF
echo 'DONE - notifications now route through Service Worker (fixes Android Chrome)!'
