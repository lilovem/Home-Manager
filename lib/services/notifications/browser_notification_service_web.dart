// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// מימוש אמיתי של התראות דפדפן, פועל רק על Flutter Web.
/// לא נטען כלל בבנייה למובייל (Android/iOS) - ראה את קובץ ה-stub.
class BrowserNotificationService {
  BrowserNotificationService() {
    _registerServiceWorker();
  }

  html.ServiceWorkerRegistration? _registration;

  /// רושמים Service Worker משלנו במפורש - לא סומכים על זה ש-Flutter
  /// ירשום אחד משלו (הוא לא תמיד עושה זאת ב-`flutter run` / debug mode).
  /// בלי Service Worker פעיל, אנדרואיד Chrome חוסם התראות לגמרי.
  void _registerServiceWorker() {
    html.window.navigator.serviceWorker
        ?.register('notification-sw.js')
        .then((reg) => _registration = reg)
        .catchError((_) {});
  }

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

    // עדיפות ל-registration שרשמנו בעצמנו (תמיד אמין). נפילה חזרה
    // ל-.ready רק אם משום מה הרישום שלנו נכשל.
    final registration =
        _registration ?? await html.window.navigator.serviceWorker?.ready;

    if (registration != null) {
      registration.showNotification(title, {
        'body': body ?? '',
        'icon': 'icons/Icon-192.png',
        'tag': 'home-manager-notification',
      });
    } else {
      // נפילה חזרה לבנאי הישיר - עובד בדפדפנים ללא Service Worker בכלל.
      html.Notification(title, body: body ?? '');
    }
  }
}

