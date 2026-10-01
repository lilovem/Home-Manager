import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/weather_service.dart';
import '../core/utils/web_geolocation.dart';

/// מזג האוויר הנוכחי לפי מיקום הדפדפן - נטען כשטאב "בית" נפתח.
///
/// אם המשתמש/ת מסרבים להרשאת מיקום, או שהדפדפן לא תומך ב-
/// Geolocation, ה-provider הזה נכשל (AsyncError) וה-UI (ר.
/// home_tab_content.dart) פשוט מסתיר את הבאנר בשקט - זה פיצ'ר
/// "נחמד שיש", לא קריטי, ולא שווה להציג עליו הודעת שגיאה בולטת.
final currentWeatherProvider = FutureProvider.autoDispose<WeatherData>((ref) async {
  if (!WebGeolocation.isSupported) {
    throw Exception('geolocation-not-supported');
  }
  final position = await WebGeolocation.getCurrentPosition();
  return WeatherService.fetchCurrentWeather(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});
