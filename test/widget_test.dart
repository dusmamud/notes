import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note/core/security/security_service.dart';
import 'package:note/core/services/markdown_table_helper.dart';
import 'package:note/core/services/math_notes_engine.dart';
import 'package:note/features/notes/data/models/note_entity.dart';
import 'package:note/features/notes/data/repositories/note_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    SharedPreferences.setMockInitialValues({});
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

    await repo.restoreNote(id);
    final restored = await repo.getAllNotes();
    expect(restored.length, 1);
  });

  test('NoteEntity JSON serialization and deserialization integrity', () {
    final original = NoteEntity(
      id: 42,
      uuid: 'test-uuid-1234',
      title: 'Architecture Review',
      contentMarkdown: '# Clean-Room Replica\n- [x] Android Widgets\n- [x] TileService',
      contentJson: '[{"insert":"Hello"}]',
      isPinned: true,
      isLocked: false,
      colorValue: 0xFFFEEBC8,
      createdAt: DateTime(2026, 11, 2, 10, 0),
      updatedAt: DateTime(2026, 11, 2, 12, 0),
    );

    expect(original.id, 42);
    expect(original.isPinned, true);
    expect(original.colorValue, 0xFFFEEBC8);
    expect(original.contentMarkdown.contains('TileService'), true);
  });

  test('MarkdownTableHelper table manipulation test', () {
    const table = "| Col 1 | Col 2 |\n|---|---|\n| Val 1 | Val 2 |\n";
    final region = MarkdownTableHelper.parseTableAt(table, 10);
    expect(region, isNotNull);
    expect(region!.lines.length, 3);

    // Test add row below
    final withNewRow = MarkdownTableHelper.addRow(table, 10, below: true);
    expect(withNewRow.contains('| Item | Item |'), true);

    // Test add column
    final withNewCol = MarkdownTableHelper.addColumn(table, 10);
    expect(withNewCol.contains('| NewCol |'), true);

    // Test convert to text
    final textOnly = MarkdownTableHelper.convertTableToText(table, 10);
    expect(textOnly.contains('|'), false);
    expect(textOnly.contains('Col 1'), true);

    // Test copy table only
    final copied = MarkdownTableHelper.copyTableOnly(table, 10);
    expect(copied, table.trim());
  });

  test('SecurityService cryptographic hashing, rate limit and AES encryption test', () async {
    SharedPreferences.setMockInitialValues({});
    final sec = SecurityService();

    // Verify fail closed when no passcode
    final noCode = await sec.verifyPasscode('1234');
    expect(noCode, false);

    // Set passcode
    await sec.setPasscode('1234');
    expect(await sec.hasPasscode(), true);

    // Correct passcode verification
    expect(await sec.verifyPasscode('1234'), true);

    // Incorrect passcode verification
    expect(await sec.verifyPasscode('0000'), false);

    // AES encryption and decryption test
    const plain = "Confidential Note Data";
    final encrypted = sec.encryptNoteContent(plain, "mySecretKey123");
    expect(encrypted != plain, true);
    expect(encrypted.contains(':'), true);

    final decrypted = sec.decryptNoteContent(encrypted, "mySecretKey123");
    expect(decrypted, plain);
  });
}
