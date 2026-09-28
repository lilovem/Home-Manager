import 'dart:convert';
import 'package:excel/excel.dart' as xls;
import '../../models/vehicle_model.dart';
import '../../models/vehicle_service_record_model.dart';
import 'vehicle_photo_picker.dart' show mimeTypeOfDataUrl;

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

  sheet.appendRow([
    xls.TextCellValue('${vehicle.displayName} - ${vehicle.licensePlate}'),
  ]);
  sheet.appendRow([xls.TextCellValue('')]);
  sheet.appendRow([
    xls.TextCellValue('סוג טיפול'),
    xls.TextCellValue('תאריך'),
    xls.TextCellValue('ק"מ'),
    xls.TextCellValue('עלות'),
    xls.TextCellValue('הערות'),
    xls.TextCellValue('קבלה'),
  ]);

  final sorted = [...records]..sort((a, b) => b.performedAt.compareTo(a.performedAt));
  for (final record in sorted) {
    final name = kMaintenanceTemplateNames[record.serviceType] ?? record.serviceType;
    sheet.appendRow([
      xls.TextCellValue(name),
      xls.TextCellValue(formatPrettyDateHe(record.performedAt)),
      xls.IntCellValue(record.mileageAtService),
      xls.TextCellValue(record.cost != null ? '₪${record.cost!.toStringAsFixed(0)}' : ''),
      xls.TextCellValue(record.notes ?? ''),
      xls.TextCellValue(record.receiptDataUrl != null ? 'יש קבלה מצורפת (ראי בקובץ Word)' : ''),
    ]);
  }

  final bytes = excel.save() ?? <int>[];
  final base64Str = base64Encode(bytes);
  return 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Str';
}

/// בונה מסמך Word - בפועל קובץ HTML עם סיומת .doc (טכניקה נפוצה
/// ותומכת-Word בפועל, בלי צורך בספריית OOXML מלאה) - עם טבלה מסודרת
/// של היסטוריית הטיפולים, ותמונת הקבלה מוטמעת ממש בתוך הטבלה כשיש
/// כזו (קובץ PDF מצורף מסומן בטקסט בלבד, כי אי אפשר להטמיע PDF
/// כתמונה). נפתח בוורד/גוגל דוקס בלי בעיה, וניתן לשיתוף כרגיל.
String buildServiceHistoryWordDataUrl(
  Vehicle vehicle,
  List<VehicleServiceRecord> records,
) {
  final sorted = [...records]..sort((a, b) => b.performedAt.compareTo(a.performedAt));

  final buffer = StringBuffer();
  buffer.writeln('<html dir="rtl" lang="he"><head><meta charset="utf-8"></head>');
  buffer.writeln('<body style="font-family: Arial, sans-serif; direction: rtl;">');
  buffer.writeln(
      '<h2>היסטוריית טיפולים - ${_escapeHtml(vehicle.displayName)} (${_escapeHtml(vehicle.licensePlate)})</h2>');
  buffer.writeln(
      '<table border="1" cellspacing="0" cellpadding="6" style="border-collapse: collapse; width:100%; text-align: right;">');
  buffer.writeln('<tr style="background:#eeeeee;">'
      '<th>סוג טיפול</th><th>תאריך</th><th>ק"מ</th><th>עלות</th><th>הערות</th><th>קבלה</th>'
      '</tr>');

  for (final record in sorted) {
    final name = kMaintenanceTemplateNames[record.serviceType] ?? record.serviceType;
    final costText = record.cost != null ? '₪${record.cost!.toStringAsFixed(0)}' : '-';
    var receiptCell = '-';
    final receipt = record.receiptDataUrl;
    if (receipt != null) {
      final mime = mimeTypeOfDataUrl(receipt);
      receiptCell = mime.startsWith('image/')
          ? '<img src="$receipt" style="max-width:160px; max-height:160px;" />'
          : 'קובץ PDF מצורף (זמין לצפייה באפליקציה)';
    }
    buffer.writeln('<tr>'
        '<td>${_escapeHtml(name)}</td>'
        '<td>${formatPrettyDateHe(record.performedAt)}</td>'
        '<td>${record.mileageAtService}</td>'
        '<td>$costText</td>'
        '<td>${_escapeHtml(record.notes ?? '')}</td>'
        '<td>$receiptCell</td>'
        '</tr>');
  }

  buffer.writeln('</table></body></html>');

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

