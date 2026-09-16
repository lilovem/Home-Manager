import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/config/app_strings.dart';

/// מסך סריקת ברקוד - פותח את המצלמה, סורק ברקוד/QR על שובר תשלום
/// פיזי, ומחזיר את הערך שנסרק (Navigator.pop). לא מנסה "לפענח"
/// את התוכן (סכום/מספר לקוח וכו') - פורמטים של שוברים משתנים בין
/// ספקים, זיהוי אמין דורש טיפול ייעודי לכל ספק בנפרד.
class BarcodeScanScreen extends StatelessWidget {
  const BarcodeScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.scanBarcodeTitle)),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                Navigator.of(context).pop(barcodes.first.rawValue);
              }
            },
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
              child: const Text(
                AppStrings.scanBarcodeHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

