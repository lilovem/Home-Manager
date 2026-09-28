import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import 'vehicle_export_fonts.dart';
import 'vehicle_photo_picker.dart' show mimeTypeOfDataUrl, renderPdfFirstPageAsImageDataUrl;

/// בונה קובץ Excel (.xlsx אמיתי) עם טבלת היסטוריית הטיפולים של הרכב -
/// שורה אחת לכל טיפול, מהחדש לישן. אין הטמעת תמונות קבלה כאן (רק
/// ציון טקסטואלי אם יש קבלה מצורפת) - התמונה עצמה מוטמעת בקובץ
/// ה-Word (buildServiceHistoryWordDataUrl), כי שם קל וטבעי להציג
/// תמונה בתוך מסמך. מחזיר Data URL מוכן לשיתוף/הורדה.
String buildServiceHistoryExcelDataUrl(
  Vehicle vehicle,
  List<VehicleServiceRecord> records,
) {
  final excel = xls.Excel.createExcel();
  const sheetName = 'טיפולים';
  final defaultSheetName = excel.getDefaultSheet();
  if (defaultSheetName != null && defaultSheetName != sheetName) {
    excel.rename(defaultSheetName, sheetName);
  }
  final sheet = excel[sheetName];

  sheet.appendRow([xls.TextCellValue('דוח היסטוריית טיפולים ואחזקה')]);
  sheet.appendRow([xls.TextCellValue('כלי רכב: ${vehicle.displayName}')]);
  sheet.appendRow([xls.TextCellValue('מספר רישוי: ${vehicle.licensePlate}')]);
  sheet.appendRow([xls.TextCellValue('תאריך הפקת הדוח: ${formatPrettyDateHe(DateTime.now())}')]);
  sheet.appendRow([xls.TextCellValue('')]);
  sheet.appendRow([
    xls.TextCellValue('מס\''),
    xls.TextCellValue('סוג טיפול'),
    xls.TextCellValue('תאריך'),
    xls.TextCellValue('ק"מ'),
    xls.TextCellValue('עלות'),
    xls.TextCellValue('הערות'),
    xls.TextCellValue('קבלה'),
  ]);

  final sorted = [...records]..sort((a, b) => b.performedAt.compareTo(a.performedAt));
  for (var i = 0; i < sorted.length; i++) {
    final record = sorted[i];
    final name = kMaintenanceTemplateNames[record.serviceType] ?? record.serviceType;
    sheet.appendRow([
      xls.IntCellValue(i + 1),
      xls.TextCellValue(name),
      xls.TextCellValue(formatPrettyDateHe(record.performedAt)),
      xls.IntCellValue(record.mileageAtService),
      xls.TextCellValue(record.cost != null ? '₪${record.cost!.toStringAsFixed(0)}' : ''),
      xls.TextCellValue(record.notes ?? ''),
      xls.TextCellValue(
          record.receiptDataUrl != null ? 'ראה נספח ${i + 1} בקובץ PDF' : ''),
    ]);
  }

  final bytes = excel.save() ?? <int>[];
  final base64Str = base64Encode(bytes);
  return 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Str';
}

/// בונה קובץ PDF אמיתי (ולא קובץ HTML בתחפושת וורד, כמו בגרסה
/// הקודמת) עם כותרת רשמית (שם הרכב, מספר רישוי, תאריך הפקה), טבלה
/// מסודרת וממוספרת של היסטוריית הטיפולים, ונספח נפרד לכל קבלה - כל
/// קבלה בעמוד משלה, עם מספר הנספח וכותרתו למעלה ותמונת הקבלה מתחת,
/// ממוספר לפי מספר הטיפול בטבלה כדי שיהיה ברור לקונה פוטנציאלי איזו
/// קבלה שייכת לאיזה טיפול. קבלת PDF מומרת קודם לתמונה (ראה
/// renderPdfFirstPageAsImageDataUrl) כדי שתוצג תמיד כתמונה בנספח,
/// בלי צורך בשום לחיצה על קישור.
///
/// למה PDF ולא וורד: בפורמט PDF מעבר עמוד הוא עובדה פיזית בקובץ עצמו
/// (pw.NewPage), ולא "בקשה" שכל תוכנה מפרשת אחרת - לכן העימוד נכון
/// בכל תוכנה שפותחת PDF (כולל אפליקציות כמו CamScanner), בניגוד לקובץ
/// HTML/וורד שבו מעבר עמוד הוא רק המלצה שחלק גדול מהתוכנות מתעלמות
/// ממנה. מאותה סיבה גם חתימת המיתוג בתחתית העמוד כאן היא "footer"
/// אמיתי של pw.MultiPage שמצטרף אוטומטית לכל עמוד בקובץ, ולא צריך
/// להוסיף אותו ידנית אחרי כל קטע כמו קודם.
///
/// לפורמט PDF אין תמיכה מובנית בעברית (הגופנים המובנים בפורמט הם
/// לטיניים בלבד), ולכן גופן עברי אמיתי (Rubik, גופן פתוח ברישיון
/// OFL) משובץ ישירות בתוך קובץ ה-PDF עצמו (ראה vehicle_export_fonts.dart)
/// - כך שהטקסט העברי יוצג נכון בכל מכשיר שפותח את הקובץ, גם אם אין
/// לו גופן עברי מותקן.
Future<String> buildServiceHistoryPdfDataUrl(
  Vehicle vehicle,
  List<VehicleServiceRecord> records,
) async {
  final sorted = [...records]..sort((a, b) => b.performedAt.compareTo(a.performedAt));

  // פותרים כל קבלה לתמונה פעם אחת בלבד (כדי לא לרנדר PDF פעמיים -
  // גם לתא "ראה נספח" בטבלה וגם לתמונה הגדולה בעמוד הנספח עצמו).
  final resolvedReceiptImages = <String?>[];
  for (final record in sorted) {
    final receipt = record.receiptDataUrl;
    if (receipt == null) {
      resolvedReceiptImages.add(null);
      continue;
    }
    final mime = mimeTypeOfDataUrl(receipt);
    if (mime.startsWith('image/')) {
      resolvedReceiptImages.add(receipt);
    } else {
      resolvedReceiptImages.add(await renderPdfFirstPageAsImageDataUrl(receipt));
    }
  }

  final regularFont = pw.Font.ttf(base64Decode(kRubikRegularFontBase64).buffer.asByteData());
  final boldFont = pw.Font.ttf(base64Decode(kRubikBoldFontBase64).buffer.asByteData());

  final brandColor = PdfColor.fromHex('2E3B55');
  final footerColor = PdfColor.fromHex('9AA0A6');
  final borderColor = PdfColor.fromHex('CCCCCC');

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
  );

  pw.Widget infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(font: boldFont, fontSize: 11)),
          pw.SizedBox(width: 8),
          pw.Text(value, style: pw.TextStyle(font: regularFont, fontSize: 11)),
        ],
      ),
    );
  }

  const headers = ['מס\'', 'סוג טיפול', 'תאריך', 'ק"מ', 'עלות', 'הערות', 'קבלה'];
  final tableData = <List<String>>[];
  for (var i = 0; i < sorted.length; i++) {
    final record = sorted[i];
    final number = i + 1;
    final name = kMaintenanceTemplateNames[record.serviceType] ?? record.serviceType;
    final costText = record.cost != null ? '₪${record.cost!.toStringAsFixed(0)}' : '-';
    final receiptImage = resolvedReceiptImages[i];

    // בטבלה עצמה - רק טקסט "ראה נספח X", בלי תמונה (התמונה מופיעה
    // רק בעמוד הנספח הייעודי שלה, בהמשך המסמך).
    var receiptCell = '-';
    if (receiptImage != null) {
      receiptCell = 'ראה נספח $number';
    } else if (record.receiptDataUrl != null) {
      // קבלת PDF שלא הצלחנו להמיר לתמונה (למשל קובץ פגום) - עדיין
      // מסומנת כמצורפת, גם אם אין לה עמוד נספח משלה.
      receiptCell = 'קובץ מצורף';
    }

    tableData.add([
      '$number',
      name,
      formatPrettyDateHe(record.performedAt),
      '${record.mileageAtService}',
      costText,
      record.notes ?? '',
      receiptCell,
    ]);
  }

  // עמודי נספח - רק לרשומות שבאמת הצלחנו להמיר להן תמונת קבלה. כל
  // נספח מתחיל בעמוד חדש משלו (pw.NewPage - שבירת עמוד אמיתית ברמת
  // הקובץ, לא הצעה שהתוכנה הפותחת יכולה להתעלם ממנה), עם הכותרת
  // והתמונה יחד באותו עמוד - בלי עמוד כותרת נפרד ובלי עמודים ריקים
  // ביניהם.
  final appendixIndices = [
    for (var i = 0; i < sorted.length; i++)
      if (resolvedReceiptImages[i] != null) i,
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
      footer: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        alignment: pw.Alignment.bottomLeft,
        child: pw.Text(
          'הופק ע"י אפליקציית ניהול הבית LeeHome',
          style: pw.TextStyle(font: regularFont, fontSize: 8, color: footerColor),
        ),
      ),
      build: (context) => [
        pw.Center(
          child: pw.Text(
            'דוח היסטוריית טיפולים ואחזקה',
            style: pw.TextStyle(font: boldFont, fontSize: 18, color: brandColor),
          ),
        ),
        pw.SizedBox(height: 16),
        infoRow('כלי רכב:', '${vehicle.displayName}${vehicle.year != null ? ' (${vehicle.year})' : ''}'),
        infoRow('מספר רישוי:', vehicle.licensePlate),
        infoRow('תאריך הפקת הדוח:', formatPrettyDateHe(DateTime.now())),
        pw.SizedBox(height: 24),
        pw.TableHelper.fromTextArray(
          context: context,
          headers: headers,
          data: tableData,
          headerStyle: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: brandColor),
          cellStyle: pw.TextStyle(font: regularFont, fontSize: 9),
          cellAlignment: pw.Alignment.centerRight,
          headerAlignment: pw.Alignment.centerRight,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          border: pw.TableBorder.all(color: borderColor, width: 0.5),
        ),
        for (final i in appendixIndices) ...[
          pw.NewPage(),
          pw.Center(
            child: pw.Text(
              'נספח ${i + 1} - '
              '${kMaintenanceTemplateNames[sorted[i].serviceType] ?? sorted[i].serviceType} - '
              '${formatPrettyDateHe(sorted[i].performedAt)}',
              style: pw.TextStyle(font: boldFont, fontSize: 14, color: brandColor),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Image(
              pw.MemoryImage(_bytesFromDataUrl(resolvedReceiptImages[i]!)),
              fit: pw.BoxFit.contain,
              height: 620,
            ),
          ),
        ],
      ],
    ),
  );

  final bytes = await doc.save();
  final base64Str = base64Encode(bytes);
  return 'data:application/pdf;base64,$base64Str';
}

/// ממיר Data URL (כמו "data:image/png;base64,...") לבייטים גולמיים -
/// נחוץ כדי להטמיע תמונת קבלה בתוך ה-PDF דרך pw.MemoryImage, שמצפה
/// לבייטים ולא למחרוזת Data URL.
Uint8List _bytesFromDataUrl(String dataUrl) {
  final commaIndex = dataUrl.indexOf(',');
  final base64Part = commaIndex == -1 ? dataUrl : dataUrl.substring(commaIndex + 1);
  return base64Decode(base64Part);
}

