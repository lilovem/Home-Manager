// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// זוג קואורדינטות פשוט - קו רוחב/אורך.
class WebLatLng {
  final double latitude;
  final double longitude;
  const WebLatLng(this.latitude, this.longitude);
}

/// עטיפה דקה סביב Geolocation API של הדפדפן - מבקשת את המיקום
/// הנוכחי של המשתמש/ת כדי להציג מזג אוויר רלוונטי בדף הבית.
///
/// כמו WebSpeechRecognition - זו טכנולוגיה של הדפדפן עצמו, ודורשת
/// אישור מפורש של המשתמש/ת (חלונית הרשאה מובנית של הדפדפן) בפעם
/// הראשונה. אם המשתמש/ת מסרבים להרשאה, או שהדפדפן לא תומך בכלל,
/// getCurrentPosition זורקת שגיאה - הקוד שקורא לה אמור לטפל בזה
/// בשקט (ר' weather_provider.dart), בלי להציג הודעת שגיאה בולטת.
class WebGeolocation {
  /// true אם לדפדפן הנוכחי יש בכלל תמיכה ב-Geolocation API.
  static bool get isSupported {
    try {
      // ignore: unnecessary_null_comparison
      return html.window.navigator.geolocation != null;
    } catch (_) {
      return false;
    }
  }

  /// מחזירה את המיקום הנוכחי, או זורקת אם המשתמש/ת סירבו להרשאה
  /// או שהדפדפן לא תומך.
  static Future<WebLatLng> getCurrentPosition() async {
    final position = await html.window.navigator.geolocation.getCurrentPosition();
    final coords = position.coords;
    if (coords == null) {
      throw Exception('no-coordinates');
    }
    return WebLatLng(
      (coords.latitude as num).toDouble(),
      (coords.longitude as num).toDouble(),
    );
  }
}
