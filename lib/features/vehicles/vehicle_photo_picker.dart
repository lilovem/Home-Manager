import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

/// בוחר תמונה מהמחשב/טלפון של המשתמש (דרך חלון "בחירת קובץ" של
/// הדפדפן) ומכווץ אותה לרוחב מקסימלי, כדי שתישאר קטנה מספיק לשמירה
/// ישירה במסמך Firestore (מגבלה של 1MB למסמך) - בלי Firebase
/// Storage בתשלום. מחזיר Data URL מוכן לשמירה (data:image/jpeg;base64,...),
/// או null אם המשתמש ביטל את הבחירה.
Future<String?> pickAndCompressVehiclePhoto({
  int maxWidth = 480,
  double quality = 0.72,
}) {
  return _pickAndCompressImage(useCamera: false, maxWidth: maxWidth, quality: quality);
}

/// כמו pickAndCompressVehiclePhoto, אבל עם אפשרות לבחור אם לפתוח
/// ישירות את המצלמה של המכשיר (useCamera: true - עובד בטלפון; בדסקטופ
/// זה פשוט ייפול לבחירת קובץ רגילה) או לפתוח את גלריית התמונות/בחירת
/// קובץ (useCamera: false).
Future<String?> pickAndCompressPhoto({
  required bool useCamera,
  int maxWidth = 480,
  double quality = 0.72,
}) {
  return _pickAndCompressImage(useCamera: useCamera, maxWidth: maxWidth, quality: quality);
}

Future<String?> _pickAndCompressImage({
  required bool useCamera,
  required int maxWidth,
  required double quality,
}) async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  if (useCamera) {
    input.setAttribute('capture', 'environment');
  }
  input.click();

  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;
  final file = files.first;

  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;
  final originalDataUrl = reader.result as String;

  final completer = Completer<String?>();
  final imgElement = html.ImageElement();
  imgElement.onLoad.listen((_) {
    final originalWidth = imgElement.width ?? maxWidth;
    final originalHeight = imgElement.height ?? maxWidth;
    final scale = originalWidth > maxWidth ? maxWidth / originalWidth : 1.0;
    final targetWidth = (originalWidth * scale).round().clamp(1, 4000);
    final targetHeight = (originalHeight * scale).round().clamp(1, 4000);

    final canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
    final ctx = canvas.context2D;
    ctx.drawImageScaled(imgElement, 0, 0, targetWidth, targetHeight);
    final compressedDataUrl = canvas.toDataUrl('image/jpeg', quality);
    if (!completer.isCompleted) completer.complete(compressedDataUrl);
  });
  imgElement.onError.listen((_) {
    if (!completer.isCompleted) completer.complete(null);
  });
  imgElement.src = originalDataUrl;

  return completer.future;
}

/// בוחר קובץ PDF מהמחשב/טלפון ומחזיר אותו כ-Data URL גולמי (בלי
/// כיווץ - PDF לא ניתן לכיווץ כמו תמונה). שימי לב שיש בדיקת גודל
/// נפרדת (dataUrlSizeBytes) לפני השמירה, כדי לא לחרוג ממגבלת המסמך
/// ב-Firestore.
Future<String?> pickPdfDataUrl() async {
  final input = html.FileUploadInputElement()..accept = 'application/pdf';
  input.click();

  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;
  final file = files.first;

  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;
  return reader.result as String;
}

/// ממיר Data URL (data:image/jpeg;base64,....) לבייטים גולמיים, כדי
/// להציג אותם עם Image.memory בלי תלות בפלטפורמה.
List<int>? decodeVehiclePhotoDataUrl(String? dataUrl) {
  if (dataUrl == null) return null;
  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex == -1) return null;
  try {
    return base64Decode(dataUrl.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

/// גודל משוער (בייטים) של Data URL - לבדיקת חריגה ממגבלת המסמך
/// לפני השמירה (למשל קובצי PDF, שלא עוברים כיווץ).
int dataUrlSizeBytes(String dataUrl) {
  final commaIndex = dataUrl.indexOf(',');
  final base64Part = commaIndex == -1 ? dataUrl : dataUrl.substring(commaIndex + 1);
  return (base64Part.length * 3) ~/ 4;
}

/// מחלץ את סוג הקובץ (MIME) מתוך Data URL - משמש כדי להחליט אם
/// להציג תצוגה מקדימה של תמונה או לפתוח PDF בלשונית נפרדת.
String mimeTypeOfDataUrl(String dataUrl) {
  final match = RegExp(r'^data:([^;]+);base64').firstMatch(dataUrl);
  return match?.group(1) ?? 'application/octet-stream';
}

/// פותח Data URL בלשונית דפדפן חדשה - משמש לצפייה בקבצי PDF, שהדפדפן
/// יודע להציג באופן טבעי בלי צורך בספריית תצוגה נפרדת.
void openDataUrlInNewTab(String dataUrl) {
  html.window.open(dataUrl, '_blank');
}

/// מוריד Data URL כקובץ למחשב/טלפון של המשתמש - משמש כ"נפילה
/// רכה" (fallback) כששיתוף ישיר (Web Share API) לא נתמך בדפדפן,
/// כדי שעדיין אפשר יהיה לשמור ולצרף את הקובץ ידנית.
void downloadDataUrlFile({required String dataUrl, required String fileName}) {
  final anchor = html.AnchorElement(href: dataUrl)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

/// משתף קובץ (Data URL) דרך תפריט השיתוף המובנה של המכשיר
/// (Web Share API) - זה אותו תפריט שנפתח בכל אפליקציה כשלוחצים
/// "שתף", וממנו אפשר לבחור וואטסאפ, מייל, או כל אפליקציה אחרת
/// שמותקנת. מחזיר true אם השיתוף נפתח בהצלחה, ו-false אם הדפדפן
/// לא תומך בשיתוף קבצים (למשל בדסקטופ) - במקרה כזה כדאי ליפול
/// ל-downloadDataUrlFile כחלופה.
Future<bool> shareDataUrlFile({
  required String dataUrl,
  required String fileName,
  String? title,
  String? text,
}) async {
  try {
    final navigator = html.window.navigator;
    final hasShare = js_util.hasProperty(navigator, 'share');
    if (!hasShare) return false;

    final mimeType = mimeTypeOfDataUrl(dataUrl);
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex == -1) return false;
    final bytes = Uint8List.fromList(base64Decode(dataUrl.substring(commaIndex + 1)));

    final blob = html.Blob([bytes], mimeType);
    final file = html.File([blob], fileName, {'type': mimeType});

    final shareData = js_util.newObject();
    js_util.setProperty(shareData, 'files', [file]);
    if (title != null) js_util.setProperty(shareData, 'title', title);
    if (text != null) js_util.setProperty(shareData, 'text', text);

    final hasCanShare = js_util.hasProperty(navigator, 'canShare');
    if (hasCanShare) {
      final canShareFiles =
          js_util.callMethod(navigator, 'canShare', [shareData]) as bool? ?? false;
      if (!canShareFiles) return false;
    }

    await js_util.promiseToFuture(js_util.callMethod(navigator, 'share', [shareData]));
    return true;
  } catch (_) {
    return false;
  }
}
