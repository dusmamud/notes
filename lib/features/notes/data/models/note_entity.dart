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
  bool isArchived;
  String? passwordHash;

  bool isTrashed;
  @Property(type: PropertyType.date)
  DateTime? trashedAt;

  int colorIndex;
  String? coverImagePath;
  String? backgroundImagePath;
  double textScale;
  String? customFontPath;
  String mathResultsMode;

  final folder = ToOne<FolderEntity>();

  @Backlink('notes')
  final tags = ToMany<TagEntity>();

  @Backlink('note')
  final attachments = ToMany<AttachmentEntity>();

  NoteEntity({
    this.id = 0,
    String? uuid,
    required this.title,
    this.contentJson = '[]',
    this.plainText = '',
    String? contentMarkdown,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.isLocked = false,
    this.isArchived = false,
    this.passwordHash,
    this.isTrashed = false,
    bool? isTrash,
    this.trashedAt,
    this.colorIndex = 0,
    int? colorValue,
    this.coverImagePath,
    this.backgroundImagePath,
    this.textScale = 1.0,
    this.customFontPath,
    this.mathResultsMode = 'suggest',
  })  : uuid = uuid ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    if (contentMarkdown != null) {
      plainText = contentMarkdown;
    }
    if (colorValue != null) {
      colorIndex = colorValue;
    }
    if (isTrash != null) {
      isTrashed = isTrash;
    }
  }

  String get contentMarkdown => plainText;
  set contentMarkdown(String val) => plainText = val;

  bool get isTrash => isTrashed;
  set isTrash(bool val) => isTrashed = val;

  int? get colorValue => colorIndex != 0 ? colorIndex : null;
  set colorValue(int? val) => colorIndex = val ?? 0;
}
