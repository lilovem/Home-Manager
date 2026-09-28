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
/// בטבלה וגם בנספח, בלי צורך בשום לחיצה על קישור. תחתית עמוד קבועה
/// ("הופק ע"י LeeHome") מוגדרת כ"כותרת תחתונה" אמיתית של וורד
/// (mso-element:footer) - טכניקה שוורד עצמו משתמש בה - כך שהיא
/// מופיעה אוטומטית בתחתית *כל* עמוד, כולל כל עמודי הנספחים, בלי
/// צורך להוסיף אותה ידנית בכל מקום. נפתח בוורד/גוגל דוקס בלי בעיה,
/// וניתן לשיתוף כרגיל.
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
  // שכל נספח תמיד יתחיל בעמוד נפרד ולא "יידבק" לעמוד הקודם.
  const pageBreak =
      "<br clear=\"all\" style=\"mso-special-character:line-break; page-break-before:always;\">";

  final buffer = StringBuffer();
  buffer.writeln('<html xmlns:o="urn:schemas-microsoft-com:office:office" '
      'xmlns:w="urn:schemas-microsoft-com:office:word" '
      'xmlns="http://www.w3.org/TR/REC-html40" dir="rtl" lang="he">');
  buffer.writeln('<head><meta charset="utf-8">'
      '<style>@page Section1 { mso-footer: f1; } div.Section1 { page: Section1; }</style>'
      '</head>');
  buffer.writeln('<body style="font-family: Arial, sans-serif; direction: rtl;">');

  // תחתית עמוד קבועה - מוגדרת פעם אחת, ומופיעה אוטומטית בתחתית שמאל
  // של כל עמוד בקובץ (ראה @page/mso-footer למעלה).
  buffer.writeln('<div style="mso-element:footer" id="f1">'
      '<p dir="rtl" style="margin:0; text-align:left; font-size:10px; color:#9AA0A6;">'
      '🏠 הופק ע"י אפליקציית ניהול הבית <b style="color:#2E3B55;">LeeHome</b></p></div>');

  buffer.writeln('<div class="Section1">');
  buffer.writeln(
      '<h1 style="text-align:center; margin-bottom:24px;">דוח היסטוריית טיפולים ואחזקה</h1>');
  buffer.writeln('<table style="border:none; margin-bottom:32px;">'
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

  // נספח קבלות - כל קבלה מתחילה ישר בעמוד חדש משלה (בלי עמוד כותרת
  // "נספחים" נפרד בפני עצמו, ובלי עמודים ריקים ביניהם): שם הנספח
  // ומתחתיו, באותו עמוד, הצילום. התחתית הקבועה (הופק ע"י LeeHome)
  // מופיעה אוטומטית בתחתית כל עמוד כזה בזכות ה-footer שהוגדר למעלה.
  final appendixIndices = [
    for (var i = 0; i < sorted.length; i++)
      if (resolvedReceiptImages[i] != null) i,
  ];

  for (final i in appendixIndices) {
    final record = sorted[i];
    final number = i + 1;
    final name = kMaintenanceTemplateNames[record.serviceType] ?? record.serviceType;
    buffer.writeln(pageBreak);
    buffer.writeln('<div style="text-align: center;">'
        '<h1>נספח $number - ${_escapeHtml(name)} - ${formatPrettyDateHe(record.performedAt)}</h1>'
        '<img src="${resolvedReceiptImages[i]}" style="max-width:100%; max-height:850px;" />'
        '</div>');
  }

  buffer.writeln('</div>');
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

