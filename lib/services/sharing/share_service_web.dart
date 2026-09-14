// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// שיתוף ישיר דרך קישורי wa.me / mailto - עובד בכל דפדפן, בלי
/// צורך בהרשאות מיוחדות (בשונה מ-Web Share API שלא נתמך בכל מקום).
class ShareService {
  void shareViaWhatsApp(String text) {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    html.window.open(url, '_blank');
  }

  void shareViaEmail({required String subject, required String body}) {
    final url = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    html.window.open(url, '_blank');
  }
}

