// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

/// עטיפה דקה סביב ה-Web Speech API המובנה בדפדפן (חינמי לגמרי,
/// בלי שרת ובלי עלות) - מאפשרת הכתבה קולית ישירות בתוך האפליקציה.
///
/// חשוב: זו טכנולוגיה של הדפדפן עצמו, לא שלנו - **עובדת מצוין בכרום
/// (מחשב ואנדרואיד), אבל לא נתמכת בכלל ב-Safari של אייפון**. בגלל
/// זה [isSupported] בודקת מראש אם יש תמיכה, כדי שנציג את כפתור
/// ההקלטה רק כשהוא באמת יעבוד, ולא נבלבל עם כפתור שלא עושה כלום.
class WebSpeechRecognition {
  dynamic _recognition;
  bool _isListening = false;

  bool get isListening => _isListening;

  static dynamic get _constructor =>
      js_util.getProperty(html.window, 'webkitSpeechRecognition') ??
      js_util.getProperty(html.window, 'SpeechRecognition');

  /// true אם הדפדפן הנוכחי תומך בהכתבה קולית מובנית בכלל.
  static bool get isSupported => _constructor != null;

  /// מתחילה האזנה. [onResult] נקרא בכל פעם שזוהתה "חתיכת" דיבור
  /// סופית (משפט/הפסקה) - לא כל האזנה בבת אחת - כדי שאפשר יהיה
  /// להוסיף אותה כשורה חדשה לטקסט הקיים במקום להחליף אותו.
  /// [onEnd] נקרא כשההאזנה נעצרת (בין אם המשתמשת עצרה, ובין אם
  /// הדפדפן עצר לבד אחרי שתיקה ארוכה). [onError] נקרא במקרה של
  /// תקלה (למשל הרשאת מיקרופון נדחתה).
  void start({
    required void Function(String text) onResult,
    required void Function() onEnd,
    void Function(String error)? onError,
  }) {
    if (_isListening) return;

    final ctor = _constructor;
    if (ctor == null) {
      onError?.call('not-supported');
      return;
    }

    final recognition = js_util.callConstructor(ctor, const []);
    js_util.setProperty(recognition, 'lang', 'he-IL');
    js_util.setProperty(recognition, 'continuous', true);
    js_util.setProperty(recognition, 'interimResults', false);

    js_util.setProperty(
      recognition,
      'onresult',
      js_util.allowInterop((dynamic event) {
        final resultIndex = js_util.getProperty(event, 'resultIndex') as int;
        final results = js_util.getProperty(event, 'results');
        final length = js_util.getProperty(results, 'length') as int;
        for (var i = resultIndex; i < length; i++) {
          final result = js_util.callMethod(results, 'item', [i]);
          final isFinal = js_util.getProperty(result, 'isFinal') as bool? ?? false;
          if (!isFinal) continue;
          final alternative = js_util.callMethod(result, 'item', [0]);
          final transcript = (js_util.getProperty(alternative, 'transcript') as String? ?? '').trim();
          if (transcript.isNotEmpty) onResult(transcript);
        }
      }),
    );

    js_util.setProperty(
      recognition,
      'onerror',
      js_util.allowInterop((dynamic event) {
        _isListening = false;
        final error = js_util.getProperty(event, 'error') as String? ?? 'unknown';
        onError?.call(error);
      }),
    );

    js_util.setProperty(
      recognition,
      'onend',
      js_util.allowInterop((dynamic event) {
        _isListening = false;
        onEnd();
      }),
    );

    _recognition = recognition;
    _isListening = true;
    js_util.callMethod(recognition, 'start', const []);
  }

  /// עוצרת האזנה יזומה (למשל כשהמשתמשת לוחצת שוב על כפתור המיקרופון,
  /// או כשהמסך נסגר). לא זורקת שגיאה אם ממילא לא מאזינה.
  void stop() {
    final recognition = _recognition;
    if (recognition != null && _isListening) {
      js_util.callMethod(recognition, 'stop', const []);
    }
  }
}

