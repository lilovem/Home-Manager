import 'dart:convert';
import 'package:excel/excel.dart' as xls;
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
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
          record.receiptDataUrl != null ? 'ראה נספח ${i + 1} בקובץ Word' : ''),
    ]);
  }

  final bytes = excel.save() ?? <int>[];
  final base64Str = base64Encode(bytes);
  return 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Str';
}

/// בונה מסמך Word - בפועל קובץ HTML עם סיומת .doc (טכניקה נפוצה
/// ותומכת-Word בפועל, בלי צורך בספריית OOXML מלאה) - עם כותרת רשמית
/// (שם הרכב, מספר רישוי, תאריך הפקה), טבלה מסודרת וממוספרת של
/// היסטוריית הטיפולים, ונספח נפרד בסוף המסמך שבו כל קבלה מוצגת
/// בעמוד שלם משלה (לא רק תמונה קטנה בתוך הטבלה) - ממוספר לפי מספר
/// הטיפול בטבלה, כדי שיהיה ברור לקונה פוטנציאלי איזו קבלה שייכת
/// לאיזה טיפול. קבלת PDF מומרת קודם לתמונה (ראה
/// renderPdfFirstPageAsImageDataUrl) כדי שתוצג תמיד כתמונה, גם
/// בטבלה וגם בנספח, בלי צורך בשום לחיצה על קישור. נפתח בוורד/גוגל
/// דוקס בלי בעיה, וניתן לשיתוף כרגיל.
Future<String> buildServiceHistoryWordDataUrl(
  Vehicle vehicle,
  List<VehicleServiceRecord> records,
) async {
  final sorted = [...records]..sort((a, b) => b.performedAt.compareTo(a.performedAt));

  // פותרים כל קבלה לתמונה פעם אחת בלבד (כדי לא לרנדר PDF פעמיים -
  // גם לתמונה הקטנה בטבלה וגם לתמונה הגדולה בנספח).
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

  // "שובר עמוד" בטכניקה שוורד עצמו משתמש בה כשהוא שומר HTML עם מעבר
  // עמוד ידני - הרבה יותר אמינה מ-page-break-before רגיל על div, כדי
  // שהנספחים תמיד יתחילו בעמוד נפרד ולא "יידבקו" לעמוד הטבלה.
  const pageBreak =
      "<br clear=\"all\" style=\"mso-special-character:line-break; page-break-before:always;\">";

  // שורת מיתוג קטנה בתחתית העמוד (צד שמאל) - "לוגו" טקסטואלי של
  // האפליקציה, כדי שהדוח ייראה כמופק ממקור מסודר ומקצועי.
  const brandFooter = '<div style="margin-top:20px; text-align:left; '
      'font-size:10px; color:#9AA0A6;">🏠 הופק ע"י אפליקציית ניהול הבית '
      '<b style="color:#2E3B55;">LeeHome</b></div>';

  final buffer = StringBuffer();
  buffer.writeln('<html dir="rtl" lang="he"><head><meta charset="utf-8"></head>');
  buffer.writeln('<body style="font-family: Arial, sans-serif; direction: rtl;">');
  buffer.writeln(
      '<h1 style="text-align:center; margin-bottom:24px;">דוח היסטוריית טיפולים ואחזקה</h1>');
  buffer.writeln('<table style="border:none; margin-bottom:16px;">'
      '<tr><td style="padding:2px 0; font-weight:bold;">כלי רכב:</td>'
      '<td style="padding:2px 8px;">${_escapeHtml(vehicle.displayName)}${vehicle.year != null ? ' (${vehicle.year})' : ''}</td></tr>'
      '<tr><td style="padding:2px 0; font-weight:bold;">מספר רישוי:</td>'
      '<td style="padding:2px 8px;">${_escapeHtml(vehicle.licensePlate)}</td></tr>'
      '<tr><td style="padding:2px 0; font-weight:bold;">תאריך הפקת הדוח:</td>'
      '<td style="padding:2px 8px;">${formatPrettyDateHe(DateTime.now())}</td></tr>'
      '</table>');
  buffer.writeln(
      '<table border="1" cellspacing="0" cellpadding="6" style="border-collapse: collapse; width:100%; text-align: right;">');
  buffer.writeln('<tr style="background:#2E3B55; color:#ffffff;">'
      '<th>מס\'</th><th>סוג טיפול</th><th>תאריך</th><th>ק"מ</th><th>עלות</th><th>הערות</th><th>קבלה</th>'
      '</tr>');

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
      // קבלת PDF שלא הצלחנו להמיר לתמונה (למשל קובץ פגום) - נשארת
      // כקישור, למרות שלא תמיד ייפתח בכל תוכנה.
      receiptCell = '<a href="${record.receiptDataUrl}" target="_blank">📄 פתח קובץ PDF</a>';
    }

    buffer.writeln('<tr>'
        '<td>$number</td>'
        '<td>${_escapeHtml(name)}</td>'
        '<td>${formatPrettyDateHe(record.performedAt)}</td>'
        '<td>${record.mileageAtService}</td>'
        '<td>$costText</td>'
        '<td>${_escapeHtml(record.notes ?? '')}</td>'
        '<td>$receiptCell</td>'
        '</tr>');
  }

  buffer.writeln('</table>');
  buffer.writeln(brandFooter);

  // נספח קבלות - כל קבלה על עמוד נפרד ונבדל משלה, ממוספר לפי מספר
  // הטיפול בטבלה למעלה. שובר העמוד לפני "נספחים" מבטיח שזה לא יופיע
  // באותו עמוד עם הטבלה. הקבלה הראשונה מופיעה באותו עמוד עם כותרת
  // "נספחים" (כדי לא ליצור עמוד ריק עם כותרת בלבד), ומכל קבלה נוספת
  // יש שובר עמוד נפרד כדי שכל אחת תקבל עמוד משלה.
  final appendixIndices = [
    for (var i = 0; i < sorted.length; i++)
      if (resolvedReceiptImages[i] != null) i,
  ];

  if (appendixIndices.isNotEmpty) {
    buffer.writeln(pageBreak);
    buffer.writeln('<h1 style="text-align:center;">נספחים - קבלות מצורפות</h1>');
    for (var idx = 0; idx < appendixIndices.length; idx++) {
      final i = appendixIndices[idx];
      final record = sorted[i];
      final number = i + 1;
      final name = kMaintenanceTemplateNames[record.serviceType] ?? record.serviceType;
      if (idx > 0) {
        buffer.writeln(pageBreak);
      }
      buffer.writeln('<div style="text-align: center;">'
          '<h2>נספח $number - ${_escapeHtml(name)} - ${formatPrettyDateHe(record.performedAt)}</h2>'
          '<img src="${resolvedReceiptImages[i]}" style="max-width:100%; max-height:850px;" />'
          '</div>');
      buffer.writeln(brandFooter);
    }
  }

  buffer.writeln('</body></html>');

  final base64Str = base64Encode(utf8.encode(buffer.toString()));
  return 'data:application/msword;base64,$base64Str';
}

String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

