import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_entity.dart';
import '../models/folder_entity.dart';
import '../models/tag_entity.dart';

class NoteRepositoryImpl implements NoteRepository {
  final List<NoteEntity> _notes = [];
  final List<FolderEntity> _folders = [];
  final List<TagEntity> _tags = [];
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('saved_notes_data');
      if (notesJson != null && notesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(notesJson);
        _notes.clear();
        for (var item in decoded) {
          _notes.add(NoteEntity(
            id: item['id'] ?? 0,
            uuid: item['uuid'] ?? '',
            title: item['title'] ?? '',
            contentMarkdown: item['contentMarkdown'] ?? '',
            contentJson: item['contentJson'] ?? '[]',
            isPinned: item['isPinned'] ?? false,
            isLocked: item['isLocked'] ?? false,
            isArchived: item['isArchived'] ?? false,
            isTrash: item['isTrash'] ?? false,
            colorValue: item['colorValue'],
            coverImagePath: item['coverImagePath'],
            mathResultsMode: item['mathResultsMode'] ?? 'suggest',
            createdAt: DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(item['updatedAt'] ?? '') ?? DateTime.now(),
          ));
        }
      }
    } catch (_) {}
    _initialized = true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _notes.map((n) => {
        'id': n.id,
        'uuid': n.uuid,
        'title': n.title,
        'contentMarkdown': n.contentMarkdown,
        'contentJson': n.contentJson,
        'isPinned': n.isPinned,
        'isLocked': n.isLocked,
        'isArchived': n.isArchived,
        'isTrash': n.isTrash,
        'colorValue': n.colorValue,
        'coverImagePath': n.coverImagePath,
        'mathResultsMode': n.mathResultsMode,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
      }).toList();
      await prefs.setString('saved_notes_data', jsonEncode(data));
    } catch (_) {}
  }

  @override
  Future<List<NoteEntity>> getAllNotes() async {
    await _ensureInitialized();
    return _notes.where((n) => !n.isTrash && !n.isArchived).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<NoteEntity>> getPinnedNotes() async {
    await _ensureInitialized();
    return _notes.where((n) => n.isPinned && !n.isTrash && !n.isArchived).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<NoteEntity>> getTrashNotes() async {
    await _ensureInitialized();
    return _notes.where((n) => n.isTrash).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<NoteEntity?> getNoteById(int id) async {
    await _ensureInitialized();
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> saveNote(NoteEntity note) async {
    await _ensureInitialized();
    if (note.id == 0) {
      note.id = DateTime.now().millisecondsSinceEpoch;
      _notes.insert(0, note);
    } else {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _notes[index] = note;
      } else {
        _notes.insert(0, note);
      }
    }
    await _persist();
    return note.id;
  }

  @override
  Future<void> deleteNote(int id, {bool permanent = false}) async {
    await _ensureInitialized();
    if (permanent) {
      _notes.removeWhere((n) => n.id == id);
    } else {
      final note = await getNoteById(id);
      if (note != null) {
        note.isTrash = true;
        note.isPinned = false;
        note.trashedAt = DateTime.now();
      }
    }
    await _persist();
  }

  @override
  Future<void> restoreNote(int id) async {
    await _ensureInitialized();
    final note = await getNoteById(id);
    if (note != null) {
      note.isTrash = false;
      note.trashedAt = null;
      await _persist();
    }
  }

  @override
  Future<void> pinNote(int id, bool isPinned) async {
    await _ensureInitialized();
    final note = await getNoteById(id);
    if (note != null) {
      note.isPinned = isPinned;
      await _persist();
    }
  }

  @override
  Future<List<FolderEntity>> getAllFolders() async {
    await _ensureInitialized();
    return List.unmodifiable(_folders);
  }

  @override
  Future<int> saveFolder(FolderEntity folder) async {
    await _ensureInitialized();
    if (folder.id == 0) {
      folder.id = DateTime.now().millisecondsSinceEpoch;
      _folders.add(folder);
    } else {
      final idx = _folders.indexWhere((f) => f.id == folder.id);
      if (idx >= 0) _folders[idx] = folder;
    }
    return folder.id;
  }

  @override
  Future<void> deleteFolder(int id) async {
    await _ensureInitialized();
    _folders.removeWhere((f) => f.id == id);
  }

  @override
  Future<List<TagEntity>> getAllTags() async {
    await _ensureInitialized();
    return List.unmodifiable(_tags);
  }

  @override
  Future<int> saveTag(TagEntity tag) async {
    await _ensureInitialized();
    if (tag.id == 0) {
      tag.id = DateTime.now().millisecondsSinceEpoch;
      _tags.add(tag);
    } else {
      final idx = _tags.indexWhere((t) => t.id == tag.id);
      if (idx >= 0) _tags[idx] = tag;
    }
    return tag.id;
  }
}

