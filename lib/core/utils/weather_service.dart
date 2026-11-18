// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

/// נתוני מזג אוויר נוכחי - תת-קבוצה קטנה ממה ש-Open-Meteo מחזיר,
/// רק מה שבאמת מוצג בדף הבית.
class WeatherData {
  final double temperatureCelsius;
  final int weatherCode;

  /// תחזית יומית: היום + הימים הבאים (ראשון ברשימה = היום).
  final List<DailyForecast> daily;

  const WeatherData({
    required this.temperatureCelsius,
    required this.weatherCode,
    this.daily = const [],
  });

  factory WeatherData.fromOpenMeteoJson(Map<String, dynamic> json) {
    final current = json['current_weather'] as Map<String, dynamic>;
    final days = <DailyForecast>[];
    try {
      final d = json['daily'] as Map<String, dynamic>;
      final times = (d['time'] as List).cast<String>();
      final codes = d['weathercode'] as List;
      final maxes = d['temperature_2m_max'] as List;
      final mins = d['temperature_2m_min'] as List;
      for (var i = 0; i < times.length; i++) {
        days.add(DailyForecast(
          date: DateTime.parse(times[i]),
          weatherCode: (codes[i] as num).toInt(),
          maxCelsius: (maxes[i] as num).toDouble(),
          minCelsius: (mins[i] as num).toDouble(),
        ));
      }
    } catch (_) {
      // אין תחזית יומית - מציגים רק את מזג האוויר הנוכחי.
    }
    return WeatherData(
      temperatureCelsius: (current['temperature'] as num).toDouble(),
      weatherCode: (current['weathercode'] as num).toInt(),
      daily: days,
    );
  }
}

class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double maxCelsius;
  final double minCelsius;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.maxCelsius,
    required this.minCelsius,
  });
}

/// שירות מזג אוויר חינמי לגמרי (Open-Meteo) בלי צורך במפתח API -
/// מתאים לאפליקציית Flutter Web סטטית בלי שרת משלנו. הקריאה נעשית
/// ישירות מהדפדפן (dart:html), בדיוק כמו שאר הקוד הספציפי ל-Web
/// בפרויקט הזה (ר' web_speech_recognition.dart).
class WeatherService {
  static Future<WeatherData> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'current_weather': 'true',
      'daily': 'weathercode,temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
      'forecast_days': '14',
    });
    final responseText = await html.HttpRequest.getString(uri.toString());
    final json = jsonDecode(responseText) as Map<String, dynamic>;
    return WeatherData.fromOpenMeteoJson(json);
  }
}
