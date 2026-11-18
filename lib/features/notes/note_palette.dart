import 'package:flutter/material.dart';

const List<Color> kNoteColors = [
  Color(0xFFFFF59D),
  Color(0xFFFFCCBC),
  Color(0xFFC8E6C9),
  Color(0xFFB3E5FC),
  Color(0xFFE1BEE7),
  Color(0xFFFFE0B2),
  Color(0xFFF8BBD0),
  Color(0xFFD7CCC8),
];

Color noteColor(int index) => kNoteColors[index.abs() % kNoteColors.length];

const Color kNoteTextColor = Color(0xFF212121);
