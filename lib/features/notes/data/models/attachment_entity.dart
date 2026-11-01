import 'package:objectbox/objectbox.dart';
import 'note_entity.dart';

@Entity()
class AttachmentEntity {
  @Id()
  int id = 0;

  @Index()
  String uuid;

  /// 'photo', 'voice', 'scan_pdf', 'file'
  String type;
  String localPath;
  String fileName;
  int fileSizeBytes;
  int durationMs;
  String? transcript;
  bool isLargeView;

  final note = ToOne<NoteEntity>();

  AttachmentEntity({
    this.id = 0,
    required this.uuid,
    required this.type,
    required this.localPath,
    required this.fileName,
    this.fileSizeBytes = 0,
    this.durationMs = 0,
    this.transcript,
    this.isLargeView = false,
  });
}

