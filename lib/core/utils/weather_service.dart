// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

/// נתוני מזג אוויר נוכחי - תת-קבוצה קטנה ממה ש-Open-Meteo מחזיר,
/// רק מה שבאמת מוצג בדף הבית.
class WeatherData {
  final double temperatureCelsius;
  final int weatherCode;

  const WeatherData({required this.temperatureCelsius, required this.weatherCode});

  factory WeatherData.fromOpenMeteoJson(Map<String, dynamic> json) {
    final current = json['current_weather'] as Map<String, dynamic>;
    return WeatherData(
      temperatureCelsius: (current['temperature'] as num).toDouble(),
      weatherCode: (current['weathercode'] as num).toInt(),
    );
  }
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
    });
    final responseText = await html.HttpRequest.getString(uri.toString());
    final json = jsonDecode(responseText) as Map<String, dynamic>;
    return WeatherData.fromOpenMeteoJson(json);
  }
}
