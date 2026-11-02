import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../../../notes/data/models/note_entity.dart';
import '../../../notes/domain/repositories/note_repository.dart';

enum BackupSchedule { daily, weekly, onEdit, manual }

class BackupRepository {
  final NoteRepository repository;

  BackupRepository({required this.repository});

  /// Generates a complete ZIP archive backup containing metadata manifest and notes Markdown files.
  Future<File> createZipBackup({Directory? destinationDir}) async {
    final notes = await repository.getAllNotes();
    final trashed = await repository.getTrashedNotes();
    final allNotes = [...notes, ...trashed];

    final archive = Archive();

    // 1. Structured JSON manifest
    final manifest = {
      'app': 'com.dusrel.note',
      'version': '1.0.0',
      'backupDate': DateTime.now().toIso8601String(),
      'notesCount': allNotes.length,
      'notes': allNotes.map((n) => {
        'id': n.id,
        'uuid': n.uuid,
        'title': n.title,
        'contentMarkdown': n.contentMarkdown,
        'isPinned': n.isPinned,
        'isLocked': n.isLocked,
        'isTrash': n.isTrash,
        'colorValue': n.colorValue,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
      }).toList(),
    };

    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(ArchiveFile('backup_manifest.json', manifestBytes.length, manifestBytes));

    // 2. Individual Markdown files
    for (var n in allNotes) {
      final safeTitle = n.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = 'notes/${n.id}_$safeTitle.md';
      final mdContent = "# ${n.title}\n\n${n.contentMarkdown}";
      final bytes = utf8.encode(mdContent);
      archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
    }

    final zipBytes = ZipEncoder().encode(archive);
    final tempDir = destinationDir ?? await getTemporaryDirectory();
    final backupFile = File('${tempDir.path}/dusrel_notes_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
    await backupFile.writeAsBytes(zipBytes);
    return backupFile;
  }

  /// Restores notes from a validated ZIP backup archive with format integrity check.
  Future<bool> restoreFromZip(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final manifestFile = archive.findFile('backup_manifest.json');
      if (manifestFile == null) return false;

      final jsonStr = utf8.decode(manifestFile.content as List<int>);
      final manifest = jsonDecode(jsonStr);
      final List notesData = manifest['notes'] ?? [];

      for (var item in notesData) {
        final note = NoteEntity(
          title: item['title'] ?? '',
          contentMarkdown: item['contentMarkdown'] ?? '',
          isPinned: item['isPinned'] ?? false,
          isLocked: item['isLocked'] ?? false,
          isTrash: item['isTrash'] ?? false,
          colorValue: item['colorValue'],
          createdAt: DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(item['updatedAt'] ?? '') ?? DateTime.now(),
        );
        await repository.saveNote(note);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
