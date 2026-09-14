/// גרסת "לא עושה כלום" - נטענת אוטומטית בבנייה למובייל (Android/iOS),
/// כדי שהקוד ימשיך להתקמפל גם כשנוסיף תמיכה בפלטפורמות האלה בעתיד.
/// התראות מובייל אמיתיות (Push דרך FCM) ייבנו בנפרד כשנגיע לזה.
class BrowserNotificationService {
  Future<bool> requestPermission() async => false;

  bool get isPermissionGranted => false;

  String get permissionStatus => 'unsupported';

  void show({required String title, String? body}) {
    // no-op
  }
}

