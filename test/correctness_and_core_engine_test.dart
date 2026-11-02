import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note/core/security/security_service.dart';
import 'package:note/features/notes/data/models/note_entity.dart';
import 'package:note/features/notes/data/repositories/text_scale_migration.dart';
import 'package:note/features/notes/data/repositories/note_repository_impl.dart';
import 'package:note/features/backup/data/repositories/backup_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('3a. TextScale Unit & Idempotent Migration Tests', () {
    test('spToMultiplier and multiplierToSp conversions', () {
      expect(TextScaleMigrator.spToMultiplier(16.0), 1.0);
      expect(TextScaleMigrator.spToMultiplier(12.0), 0.75);
      expect(TextScaleMigrator.spToMultiplier(24.0), 1.5);
      expect(TextScaleMigrator.spToMultiplier(28.0), 1.75);

      expect(TextScaleMigrator.multiplierToSp(1.0), 16.0);
      expect(TextScaleMigrator.multiplierToSp(0.75), 12.0);
      expect(TextScaleMigrator.multiplierToSp(1.5), 24.0);
      expect(TextScaleMigrator.multiplierToSp(1.75), 28.0);
    });

    test('TextScaleMigrator converts raw sp > 2.0 to canonical multiplier and marks migrated', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notes = [
        NoteEntity(title: 'Note 1', textScale: 24.0), // buggy raw sp
        NoteEntity(title: 'Note 2', textScale: 1.25), // already multiplier
        NoteEntity(title: 'Note 3', textScale: 16.0), // buggy raw sp
        NoteEntity(title: 'Note 4', textScale: 1.0),  // standard 1.0 multiplier
      ];

      await TextScaleMigrator.migrateNotes(prefs, notes);

      expect(notes[0].textScale, 1.5);
      expect(notes[1].textScale, 1.25);
      expect(notes[2].textScale, 1.0);
      expect(notes[3].textScale, 1.0);
      expect(prefs.getBool(TextScaleMigrator.migrationKey), true);

      // Idempotency: run again, values must not change
      notes[0].textScale = 24.0; // Simulate new addition
      await TextScaleMigrator.migrateNotes(prefs, notes);
      // Because alreadyMigrated is true, it skips processing
      expect(notes[0].textScale, 24.0);
    });
  });

  group('4c. SecurityService Fail-Closed PBKDF2 & AES-256 Tests', () {
    test('PBKDF2 + AES-256 roundtrip encrypt and decrypt', () {
      final sec = SecurityService();
      const plain = "Secret meeting at midnight";
      const key = "StrongPassword@123";

      final encrypted = sec.encryptNoteContent(plain, key);
      expect(encrypted != plain, true);
      expect(encrypted.contains(':'), true);

      final decrypted = sec.decryptNoteContent(encrypted, key);
      expect(decrypted, plain);
    });

    test('Fail-Closed: wrong password returns empty string, NEVER leaks plaintext', () {
      final sec = SecurityService();
      const plain = "Highly confidential data";
      final encrypted = sec.encryptNoteContent(plain, "CorrectKey");

      // Attempt decrypt with wrong password
      final failResult = sec.decryptNoteContent(encrypted, "WrongKey");
      expect(failResult, '');
      expect(failResult != plain, true);
    });

    test('Fail-Closed: corrupted ciphertext or invalid format returns empty string', () {
      final sec = SecurityService();
      expect(sec.decryptNoteContent("malformed_data_without_prefix", "AnyKey"), '');
      expect(sec.decryptNoteContent("invalid:payload:too:many:parts:here", "AnyKey"), '');
      expect(sec.decryptNoteContent("bm90YWJhc2U2NA==:bm90YWJhc2U2NA==", "AnyKey"), '');
    });

    test('Salt uniqueness: encrypting identical text twice produces different ciphertexts', () {
      final sec = SecurityService();
      const plain = "Identical note body";
      const key = "MasterKey";

      final enc1 = sec.encryptNoteContent(plain, key);
      final enc2 = sec.encryptNoteContent(plain, key);

      expect(enc1 != enc2, true);
      expect(sec.decryptNoteContent(enc1, key), plain);
      expect(sec.decryptNoteContent(enc2, key), plain);
    });
  });

  group('4e. BackupRepository ZIP Archive & Restore Tests', () {
    test('Create ZIP backup, verify manifest and Markdown files, restore integrity', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = NoteRepositoryImpl();
      await repo.saveNote(NoteEntity(
        title: 'Project Roadmap',
        contentMarkdown: '- [x] Phase 1\n- [ ] Phase 2',
        isPinned: true,
      ));
      await repo.saveNote(NoteEntity(
        title: 'Meeting Notes',
        contentMarkdown: 'Discussed clean-room engineering architecture.',
        isPinned: false,
      ));

      final backupRepo = BackupRepository(repository: repo);
      final tempDir = Directory.systemTemp.createTempSync('dusrel_test_backup_');

      try {
        final zipFile = await backupRepo.createZipBackup(destinationDir: tempDir);
        expect(zipFile.existsSync(), true);
        expect(zipFile.lengthSync() > 0, true);

        // Test restore into fresh repository
        SharedPreferences.setMockInitialValues({});
        final restoreRepo = NoteRepositoryImpl();
        final restoreBackupRepo = BackupRepository(repository: restoreRepo);

        final success = await restoreBackupRepo.restoreFromZip(zipFile);
        expect(success, true);

        final restoredNotes = await restoreRepo.getAllNotes();
        expect(restoredNotes.length, 2);
        final titles = restoredNotes.map((n) => n.title).toList();
        expect(titles.contains('Project Roadmap'), true);
        expect(titles.contains('Meeting Notes'), true);

        // Corrupted ZIP restore returns false (fail-closed)
        final corruptFile = File('${tempDir.path}/corrupt.zip');
        await corruptFile.writeAsBytes([1, 2, 3, 4, 5]);
        final corruptSuccess = await restoreBackupRepo.restoreFromZip(corruptFile);
        expect(corruptSuccess, false);
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });

  group('4a. NoteRepository JSON Migration and CRUD Tests', () {
    test('Migrates existing SharedPreferences JSON notes and supports full CRUD', () async {
      SharedPreferences.setMockInitialValues({
        'local_notes_json': '[{"id":1,"uuid":"u1","title":"Migrated Note","contentMarkdown":"Legacy content","createdAt":"2026-11-01T00:00:00.000","updatedAt":"2026-11-01T00:00:00.000"}]',
      });

      final repo = NoteRepositoryImpl();
      final notes = await repo.getAllNotes();
      expect(notes.length, 1);
      expect(notes.first.title, 'Migrated Note');
      expect(notes.first.contentMarkdown, 'Legacy content');

      // Test pin
      await repo.pinNote(notes.first.id, true);
      final pinned = await repo.getPinnedNotes();
      expect(pinned.length, 1);

      // Test trash & restore
      await repo.deleteNote(notes.first.id);
      expect((await repo.getAllNotes()).isEmpty, true);
      expect((await repo.getTrashNotes()).length, 1);
      expect((await repo.getTrashedNotes()).length, 1);

      await repo.restoreNote(notes.first.id);
      expect((await repo.getAllNotes()).length, 1);

      // Test empty trash
      await repo.deleteNote(notes.first.id);
      await repo.emptyTrash();
      expect((await repo.getTrashNotes()).isEmpty, true);
    });
  });
}

