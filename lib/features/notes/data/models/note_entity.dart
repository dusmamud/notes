import 'package:objectbox/objectbox.dart';
import 'folder_entity.dart';
import 'tag_entity.dart';
import 'attachment_entity.dart';

@Entity()
class NoteEntity {
  @Id()
  int id = 0;

  @Index()
  String uuid;

  String title;
  String contentJson;
  String plainText;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  bool isPinned;
  bool isLocked;
  String? passwordHash;

  bool isTrashed;
  @Property(type: PropertyType.date)
  DateTime? trashedAt;

  int colorIndex;
  String? coverImagePath;
  String? backgroundImagePath;
  double textScale;
  String? customFontPath;

  final folder = ToOne<FolderEntity>();

  @Backlink('notes')
  final tags = ToMany<TagEntity>();

  @Backlink('note')
  final attachments = ToMany<AttachmentEntity>();

  NoteEntity({
    this.id = 0,
    required this.uuid,
    required this.title,
    this.contentJson = '[]',
    this.plainText = '',
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isLocked = false,
    this.passwordHash,
    this.isTrashed = false,
    this.trashedAt,
    this.colorIndex = 0,
    this.coverImagePath,
    this.backgroundImagePath,
    this.textScale = 1.0,
    this.customFontPath,
  });
}
