import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_colors.dart';
import '../../../providers/household_provider.dart';
import '../../../providers/notes_provider.dart';
import '../../notes/note_editor_screen.dart';
import '../../notes/note_palette.dart';

/// טאב "פתקים": רשת של פתקים קטנים. לחיצה פותחת פתק לעריכה.
/// (נשאר בשם הקובץ והמחלקה הישנים כדי שהניווט לא ישתנה.)
class TasksTabContent extends ConsumerWidget {
  const TasksTabContent({super.key});

  void _open(
    BuildContext context,
    String householdId,
    NotePage? note, {
    int newColor = 0,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          householdId: householdId,
          note: note,
          newColor: newColor,
        ),
      ),
    );
  }

  /// לחיצה ארוכה על פתק: עריכה או מחיקה.
  Future<void> _showActions(
    BuildContext context,
    String householdId,
    NotePage note,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionRow(
              icon: Icons.edit_outlined,
              label: 'עריכה',
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            _ActionRow(
              icon: Icons.delete_outline,
              label: 'מחיקה',
              color: Colors.red,
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      _open(context, householdId, note);
    } else if (action == 'delete') {
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
      if (ok == true) {
        try {
          await notesCollection(householdId).doc(note.id).delete();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdProvider)?.id;
    if (householdId == null) return const SizedBox.shrink();

    final notesAsync = ref.watch(notePagesProvider(householdId));

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('שגיאה בטעינת הפתקים: $e', textAlign: TextAlign.center),
        ),
      ),
      data: (notes) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: _AddNoteTile(
                onTap: () => _open(context, householdId, null, newColor: notes.length),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final columns = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteCard(
                        note: note,
                        onTap: () => _open(context, householdId, note),
                        onLongPress: () => _showActions(context, householdId, note),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddNoteTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddNoteTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // כפתור קטן בלי מסגרת וריבוע מסביב, בצד ימין למעלה.
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: kNotePressColor,
        highlightColor: kNotePressColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'פתק חדש',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NotePage note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  String _dateLabel() {
    final d = note.updatedAt;
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year % 100}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: noteColor(note.color),
      elevation: 1.5,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: kNotePressColor,
        highlightColor: kNotePressColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.text,
                  textDirection: noteDirection(note.text),
                  maxLines: 7,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: kNoteTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateLabel(),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.black87;
    return InkWell(
      onTap: onTap,
      splashColor: kNotePressColor,
      highlightColor: kNotePressColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: c),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 16, color: c)),
          ],
        ),
      ),
    );
  }
}
