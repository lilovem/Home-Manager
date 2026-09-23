import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// בוחר תמונה מהמחשב/טלפון של המשתמש (דרך חלון "בחירת קובץ" של
/// הדפדפן) ומכווץ אותה לרוחב מקסימלי, כדי שתישאר קטנה מספיק לשמירה
/// ישירה במסמך Firestore (מגבלה של 1MB למסמך) - בלי Firebase
/// Storage בתשלום. מחזיר Data URL מוכן לשמירה (data:image/jpeg;base64,...),
/// או null אם המשתמש ביטל את הבחירה.
Future<String?> pickAndCompressVehiclePhoto({
  int maxWidth = 480,
  double quality = 0.72,
}) async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
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
