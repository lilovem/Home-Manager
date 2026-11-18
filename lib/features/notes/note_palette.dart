import 'package:flutter/material.dart';

/// 10 צבעים בהירים - הטקסט הכהה קריא על כולם. הצבע של פתק חדש נקבע לפי
/// מספר הפתקים הקיימים, כך שהצבעים רצים בסדר קבוע וחוזרים כל 10 פתקים.
const List<Color> kNoteColors = [
  Color(0xFFFFF59D), // צהוב
  Color(0xFFB3E5FC), // תכלת
  Color(0xFFC8E6C9), // ירוק
  Color(0xFFF8BBD0), // ורוד
  Color(0xFFFFE0B2), // כתום
  Color(0xFFE1BEE7), // סגול
  Color(0xFFB2DFDB), // טורקיז
  Color(0xFFDCEDC8), // ירוק בהיר
  Color(0xFFFFCCBC), // אפרסק
  Color(0xFFD1C4E9), // לבנדר
];

Color noteColor(int index) => kNoteColors[index.abs() % kNoteColors.length];

const Color kNoteTextColor = Color(0xFF212121);

/// צבע סימון הלחיצה - כחול האפליקציה בגוון שקוף, נראה על כל צבע פתק.
const Color kNotePressColor = Color(0x401976D2);

/// כיוון הטקסט לפי האות הראשונה: עברית -> מימין לשמאל.
TextDirection noteDirection(String text) {
  for (final rune in text.runes) {
    if (rune >= 0x0590 && rune <= 0x05FF) return TextDirection.rtl;
    if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
      return TextDirection.ltr;
    }
  }
  return TextDirection.rtl;
}
