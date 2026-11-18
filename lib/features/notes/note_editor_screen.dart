import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../providers/notes_provider.dart';
import 'note_palette.dart';

/// מסך פתק: נפתח ישר במצב עריכה, שומר אוטומטית, ואפשר למחוק.
class NoteEditorScreen extends StatefulWidget {
  final String householdId;
  final NotePage? note;

  /// צבע לפתק חדש (נקבע לפי מספר הפתקים הקיימים).
  final int newColor;

  const NoteEditorScreen({
    super.key,
    required this.householdId,
    this.note,
    this.newColor = 0,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final DocumentReference<Map<String, dynamic>> _ref;
  late final TextEditingController _controller;
  late final int _color;
  late bool _exists;
  bool _dirty = false;
  bool _deleted = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final col = notesCollection(widget.householdId);
    _ref = widget.note != null ? col.doc(widget.note!.id) : col.doc();
    _exists = widget.note != null;
    _color = widget.note?.color ?? widget.newColor;
    _controller = TextEditingController(text: widget.note?.text ?? '');
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
  }

  void _onChanged(String _) {
    setState(() {});
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  Future<void> _save() async {
    if (_deleted || !_dirty) return;
    final text = _controller.text;
    _dirty = false;
    try {
      if (text.trim().isEmpty) {
        if (_exists) {
          _exists = false;
          await _ref.delete();
        }
        return;
      }
      _exists = true;
      await _ref.set({
        'text': text,
        'color': _color,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      _dirty = true;
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('מחיקת הפתק'),
        content: const Text('הפתק יימחק אצל כל בני הבית. להמשיך?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('מחיקה', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _deleted = true;
    _debounce?.cancel();
    try {
      await _ref.delete();
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _save();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = noteColor(_color);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kNoteTextColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'חזרה',
          splashColor: kNotePressColor,
          highlightColor: kNotePressColor,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('פתק'),
        actions: [
          IconButton(
            tooltip: 'מחיקת הפתק',
            splashColor: kNotePressColor,
            highlightColor: kNotePressColor,
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            minLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            textDirection: noteDirection(_controller.text),
            onChanged: _onChanged,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: kNoteTextColor,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintText: 'כתבו כאן...',
            ),
          ),
        ),
      ),
    );
  }
}
