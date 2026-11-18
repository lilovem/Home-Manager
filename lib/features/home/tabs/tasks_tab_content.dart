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

  void _open(BuildContext context, String householdId, NotePage? note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(householdId: householdId, note: note),
      ),
    );
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
        return LayoutBuilder(
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
              itemCount: notes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AddNoteTile(
                    onTap: () => _open(context, householdId, null),
                  );
                }
                final note = notes[index - 1];
                return _NoteCard(
                  note: note,
                  onTap: () => _open(context, householdId, note),
                );
              },
            );
          },
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.5),
          color: AppColors.primary.withOpacity(0.06),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 38, color: AppColors.primary),
            const SizedBox(height: 6),
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
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NotePage note;
  final VoidCallback onTap;
  const _NoteCard({required this.note, required this.onTap});

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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.text,
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
