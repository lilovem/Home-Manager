import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../app/config/app_strings.dart';

/// פותח קישור בכרטיסייה חדשה - קריאה **סינכרונית** (בלי await
/// ביניים), כדי שדפדפנים לא יחסמו את זה כפופ-אפ. חייבת לקרות תוך
/// כדי לחיצה אמיתית של המשתמש (onPressed), לא אוטומטית מיד אחרי
/// שהמצלמה מזהה ברקוד - זו לא "לחיצה" מבחינת הדפדפן, ופתיחה
/// אוטומטית באותו רגע כמעט תמיד תיחסם.
///
/// כפילות מכוונת של הפונקציה המקבילה ב-bill_period_table_screen.dart
/// - לא מייבאים אותה משם כדי למנוע import מעגלי (הקובץ ההוא כן
/// מייבא את המסך הזה).
void _openScannedLink(String url) {
  final normalized =
      (url.startsWith('http://') || url.startsWith('https://')) ? url : 'https://$url';
  html.window.open(normalized, '_blank');
}

/// מסך סריקת ברקוד - פותח את המצלמה, סורק ברקוד/QR על שובר תשלום
/// פיזי. ברגע שמזהים ברקוד, מוצג **מיד** דיאלוג עם הקישור שנמצא
/// וכפתור "פתח באתר" גדול - זו הדרך הכי "מיידית" שאפשר להציע:
/// לחיצה אחת בדיוק ברגע הזיהוי, בלי לחזור למסך הקודם ולחפש כפתור.
/// פתיחה אוטומטית לגמרי (בלי שום לחיצה) לא אפשרית בדפדפן - חסימת
/// פופ-אפים דורשת שהפתיחה תקרה תוך כדי לחיצה אמיתית.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _dialogShowing = false;
  bool _detectedOnce = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    if (!_detectedOnce) {
      setState(() => _detectedOnce = true);
    }

    if (_dialogShowing) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _dialogShowing = true;
    _controller.stop();
    _showFoundDialog(value);
  }

  Future<void> _showFoundDialog(String value) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.barcodeDetectedTitle),
        content: Text(
          value,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _controller.start();
              if (mounted) setState(() => _dialogShowing = false);
            },
            child: const Text(AppStrings.rescanButton),
          ),
          ElevatedButton(
            onPressed: () {
              // קריאה סינכרונית ישירות מתוך onPressed - זו לחיצה
              // אמיתית של המשתמש, אז הדפדפן לא חוסם את הפתיחה.
              _openScannedLink(value);
              Navigator.of(dialogContext).pop();
              if (mounted) Navigator.of(context).pop(value);
            },
            child: const Text(AppStrings.openInSiteButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanBarcodeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: AppStrings.toggleFlashTooltip,
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // אם למצלמה אין גישה בכלל (הרשאה נדחתה, אין מצלמה,
            // הדפדפן לא תומך) - מוצגת הודעת שגיאה מפורשת במקום מסך
            // מצלמה ריק/שחור שנראה כאילו הוא "עובד".
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '${AppStrings.cameraErrorPrefix}\n${error.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
          // מסגרת ויזואלית שהופכת לירוקה ברגע שמזהים ברקוד -
          // אינדיקציה מיידית שהמצלמה בכלל "רואה" משהו.
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _detectedOnce ? Colors.greenAccent : Colors.white,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _detectedOnce ? AppStrings.barcodeFoundHint : AppStrings.scanBarcodeHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

