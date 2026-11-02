import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/widget_sync_service.dart';
import '../../../../objectbox.g.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_entity.dart';
import '../models/folder_entity.dart';
import '../models/tag_entity.dart';
import 'text_scale_migration.dart';

class NoteRepositoryImpl implements NoteRepository {
  final Store? store;
  Box<NoteEntity>? _noteBox;
  Box<FolderEntity>? _folderBox;
  Box<TagEntity>? _tagBox;

  final List<NoteEntity> _memoryNotes = [];
  final List<FolderEntity> _memoryFolders = [];
  final List<TagEntity> _memoryTags = [];
  bool _initialized = false;

  NoteRepositoryImpl({this.store});

  Future<void> initialize() => _ensureInitialized();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (store != null) {
      _noteBox = store!.box<NoteEntity>();
      _folderBox = store!.box<FolderEntity>();
      _tagBox = store!.box<TagEntity>();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool objectBoxMigrated = prefs.getBool('migration_objectbox_complete') ?? false;

      // Migrate from SharedPreferences JSON if not yet migrated
      if (!objectBoxMigrated) {
        final notesJson = prefs.getString('saved_notes_data') ?? prefs.getString('local_notes_json');
        if (notesJson != null && notesJson.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(notesJson);
          for (var item in decoded) {
            final note = NoteEntity(
              id: 0, // Let ObjectBox assign auto-increment ID
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
            );
            if (_noteBox != null) {
              _noteBox!.put(note);
            } else {
              note.id = item['id'] ?? DateTime.now().millisecondsSinceEpoch;
              _memoryNotes.add(note);
            }
          }
        }
        await prefs.setBool('migration_objectbox_complete', true);
      } else if (_noteBox == null) {
        // Fallback for tests/environments without native ObjectBox
        final notesJson = prefs.getString('saved_notes_data') ?? prefs.getString('local_notes_json');
        if (notesJson != null && notesJson.isNotEmpty && _memoryNotes.isEmpty) {
          final List<dynamic> decoded = jsonDecode(notesJson);
          for (var item in decoded) {
            _memoryNotes.add(NoteEntity(
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
      }

      // Step 3a: Run one-time textScale unit migration
      final currentNotes = _noteBox != null ? _noteBox!.getAll() : _memoryNotes;
      await TextScaleMigrator.migrateNotes(prefs, currentNotes);
      if (_noteBox != null) {
        _noteBox!.putMany(currentNotes);
      }

      // Auto-purge notes trashed > 30 days
      final now = DateTime.now();
      if (_noteBox != null) {
        final trashed = _noteBox!.query(NoteEntity_.isTrash.equals(true).or(NoteEntity_.isTrashed.equals(true))).build().find();
        for (final n in trashed) {
          if (n.trashedAt != null && now.difference(n.trashedAt!).inDays >= 30) {
            _noteBox!.remove(n.id);
          }
        }
      } else {
        _memoryNotes.removeWhere((n) => (n.isTrash || n.isTrashed) && n.trashedAt != null && now.difference(n.trashedAt!).inDays >= 30);
      }
    } catch (_) {}
    _initialized = true;
  }

  Future<void> _syncWidgets() async {
    try {
      final active = await getAllNotes();
      final prefs = await SharedPreferences.getInstance();
      final activeUnlockedNotes = active.where((n) => !n.isTrash && !n.isArchived && !n.isLocked).toList();
      if (activeUnlockedNotes.isNotEmpty) {
        final top = activeUnlockedNotes.first;
        await prefs.setInt('widget_default_note_id', top.id);
        await prefs.setString('widget_default_title', top.title.isNotEmpty ? top.title : 'Notes');
        await prefs.setString('widget_default_body', top.contentMarkdown);
        await prefs.setString('widget_default_date', '${top.updatedAt.day}/${top.updatedAt.month}/${top.updatedAt.year}');
      } else {
        await prefs.remove('widget_default_note_id');
        await prefs.setString('widget_default_title', 'Notes');
        await prefs.setString('widget_default_body', 'No unlocked notes');
      }
      await WidgetSyncService.updateWidgets();
    } catch (_) {}
  }

  @override
  Future<List<NoteEntity>> getAllNotes() async {
    await _ensureInitialized();
    if (_noteBox != null) {
      final query = _noteBox!.query(NoteEntity_.isTrash.equals(false).and(NoteEntity_.isArchived.equals(false))).order(NoteEntity_.updatedAt, flags: Order.descending).build();
      final list = query.find();
      query.close();
      return list;
    }
    return _memoryNotes.where((n) => !n.isTrash && !n.isArchived).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<NoteEntity>> getPinnedNotes() async {
    await _ensureInitialized();
    if (_noteBox != null) {
      final query = _noteBox!.query(NoteEntity_.isPinned.equals(true).and(NoteEntity_.isTrash.equals(false)).and(NoteEntity_.isArchived.equals(false))).order(NoteEntity_.updatedAt, flags: Order.descending).build();
      final list = query.find();
      query.close();
      return list;
    }
    return _memoryNotes.where((n) => n.isPinned && !n.isTrash && !n.isArchived).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<NoteEntity>> getTrashNotes() async {
    await _ensureInitialized();
    if (_noteBox != null) {
      final query = _noteBox!.query(NoteEntity_.isTrash.equals(true).or(NoteEntity_.isTrashed.equals(true))).order(NoteEntity_.updatedAt, flags: Order.descending).build();
      final list = query.find();
      query.close();
      return list;
    }
    return _memoryNotes.where((n) => n.isTrash || n.isTrashed).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<NoteEntity>> getTrashedNotes() => getTrashNotes();

  @override
  Future<NoteEntity?> getNoteById(int id) async {
    await _ensureInitialized();
    if (_noteBox != null) {
      return _noteBox!.get(id);
    }
    try {
      return _memoryNotes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> saveNote(NoteEntity note) async {
    await _ensureInitialized();
    if (_noteBox != null) {
      final assignedId = _noteBox!.put(note);
      await _syncWidgets();
      return assignedId;
    }
    if (note.id == 0) {
      note.id = DateTime.now().millisecondsSinceEpoch;
      _memoryNotes.insert(0, note);
    } else {
      final index = _memoryNotes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _memoryNotes[index] = note;
      } else {
        _memoryNotes.insert(0, note);
      }
    }
    await _syncWidgets();
    return note.id;
  }

  @override
  Future<void> deleteNote(int id, {bool permanent = false}) async {
    await _ensureInitialized();
    if (_noteBox != null) {
      if (permanent) {
        _noteBox!.remove(id);
      } else {
        final note = _noteBox!.get(id);
        if (note != null) {
          note.isTrash = true;
          note.isTrashed = true;
          note.isPinned = false;
          note.trashedAt = DateTime.now();
          _noteBox!.put(note);
        }
      }
      await _syncWidgets();
      return;
    }
    if (permanent) {
      _memoryNotes.removeWhere((n) => n.id == id);
    } else {
      final note = await getNoteById(id);
      if (note != null) {
        note.isTrash = true;
        note.isTrashed = true;
        note.isPinned = false;
        note.trashedAt = DateTime.now();
      }
    }
    await _syncWidgets();
  }

  @override
  Future<void> restoreNote(int id) async {
    await _ensureInitialized();
    if (_noteBox != null) {
      final note = _noteBox!.get(id);
      if (note != null) {
        note.isTrash = false;
        note.isTrashed = false;
        note.trashedAt = null;
        _noteBox!.put(note);
      }
      await _syncWidgets();
      return;
    }
    final note = await getNoteById(id);
    if (note != null) {
      note.isTrash = false;
      note.isTrashed = false;
      note.trashedAt = null;
    }
    await _syncWidgets();
  }

  @override
  Future<void> emptyTrash() async {
    await _ensureInitialized();
    if (_noteBox != null) {
      final trashed = await getTrashNotes();
      for (final n in trashed) {
        _noteBox!.remove(n.id);
      }
      return;
    }
    _memoryNotes.removeWhere((n) => n.isTrash || n.isTrashed);
  }

  @override
  Future<void> pinNote(int id, bool isPinned) async {
    await _ensureInitialized();
    if (_noteBox != null) {
      final note = _noteBox!.get(id);
      if (note != null) {
        note.isPinned = isPinned;
        _noteBox!.put(note);
      }
      await _syncWidgets();
      return;
    }
    final note = await getNoteById(id);
    if (note != null) {
      note.isPinned = isPinned;
    }
    await _syncWidgets();
  }

  @override
  Future<List<FolderEntity>> getAllFolders() async {
    await _ensureInitialized();
    if (_folderBox != null) {
      return _folderBox!.getAll();
    }
    return List.unmodifiable(_memoryFolders);
  }

  @override
  Future<int> saveFolder(FolderEntity folder) async {
    await _ensureInitialized();
    if (_folderBox != null) {
      return _folderBox!.put(folder);
    }
    if (folder.id == 0) {
      folder.id = DateTime.now().millisecondsSinceEpoch;
      _memoryFolders.add(folder);
    } else {
      final idx = _memoryFolders.indexWhere((f) => f.id == folder.id);
      if (idx >= 0) _memoryFolders[idx] = folder;
    }
    return folder.id;
  }

  @override
  Future<void> deleteFolder(int id) async {
    await _ensureInitialized();
    if (_folderBox != null) {
      _folderBox!.remove(id);
      return;
    }
    _memoryFolders.removeWhere((f) => f.id == id);
  }

  @override
  Future<List<TagEntity>> getAllTags() async {
    await _ensureInitialized();
    if (_tagBox != null) {
      return _tagBox!.getAll();
    }
    return List.unmodifiable(_memoryTags);
  }

  @override
  Future<int> saveTag(TagEntity tag) async {
    await _ensureInitialized();
    if (_tagBox != null) {
      return _tagBox!.put(tag);
    }
    if (tag.id == 0) {
      tag.id = DateTime.now().millisecondsSinceEpoch;
      _memoryTags.add(tag);
    } else {
      final idx = _memoryTags.indexWhere((t) => t.id == tag.id);
      if (idx >= 0) _memoryTags[idx] = tag;
    }
    return tag.id;
  }
}
