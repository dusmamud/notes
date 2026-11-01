import 'package:flutter_test/flutter_test.dart';
import 'package:note/core/services/math_notes_engine.dart';
import 'package:note/features/notes/data/models/note_entity.dart';
import 'package:note/features/notes/data/repositories/note_repository_impl.dart';

void main() {
  test('MathNotesEngine arithmetic evaluation test', () {
    final engine = MathNotesEngine(mode: MathResultsMode.suggest);
    final result = engine.evaluateLine('125 * 4 =');
    expect(result, '500');
  });

  test('MathNotesEngine percentage calculation test', () {
    final engine = MathNotesEngine(mode: MathResultsMode.suggest);
    final result = engine.evaluateLine('500 - 10% =');
    expect(result, '450');
  });

  test('MathNotesEngine square root test', () {
    final engine = MathNotesEngine(mode: MathResultsMode.suggest);
    final result = engine.evaluateLine('sqrt(144) =');
    expect(result, '12');
  });

  test('NoteRepositoryImpl CRUD and Pinning test', () async {
    final repo = NoteRepositoryImpl();
    final note = NoteEntity(
      title: 'Grocery List',
      contentMarkdown: '- [x] Milk\n- [ ] Bread',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final id = await repo.saveNote(note);
    expect(id, isNonZero);

    final all = await repo.getAllNotes();
    expect(all.length, 1);
    expect(all.first.title, 'Grocery List');

    await repo.pinNote(id, true);
    final pinned = await repo.getPinnedNotes();
    expect(pinned.length, 1);

    await repo.deleteNote(id);
    final afterDelete = await repo.getAllNotes();
    expect(afterDelete.isEmpty, true);

    final trash = await repo.getTrashNotes();
    expect(trash.length, 1);
  });
}
