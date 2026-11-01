import 'package:objectbox/objectbox.dart';
import 'note_entity.dart';

@Entity()
class FolderEntity {
  @Id()
  int id = 0;

  @Index()
  String uuid;

  String name;
  String? emoji;
  int colorValue;
  int sortOrder;
  bool isExpanded;

  final parentFolder = ToOne<FolderEntity>();

  @Backlink('parentFolder')
  final subfolders = ToMany<FolderEntity>();

  @Backlink('folder')
  final notes = ToMany<NoteEntity>();

  FolderEntity({
    this.id = 0,
    required this.uuid,
    required this.name,
    this.emoji,
    this.colorValue = 0xFFE4AF0A,
    this.sortOrder = 0,
    this.isExpanded = false,
  });
}
