import '../../data/models/note_entity.dart';
import '../../data/models/folder_entity.dart';
import '../../data/models/tag_entity.dart';

abstract class NoteRepository {
  Future<List<NoteEntity>> getAllNotes();
  Future<List<NoteEntity>> getPinnedNotes();
  Future<List<NoteEntity>> getTrashNotes();
  Future<List<NoteEntity>> getTrashedNotes();
  Future<NoteEntity?> getNoteById(int id);
  Future<int> saveNote(NoteEntity note);
  Future<void> deleteNote(int id, {bool permanent = false});
  Future<void> restoreNote(int id);
  Future<void> emptyTrash();
  Future<void> pinNote(int id, bool isPinned);
  Future<List<FolderEntity>> getAllFolders();
  Future<int> saveFolder(FolderEntity folder);
  Future<void> deleteFolder(int id);
  Future<List<TagEntity>> getAllTags();
  Future<int> saveTag(TagEntity tag);
}
