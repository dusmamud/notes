import 'package:objectbox/objectbox.dart';
import 'note_entity.dart';

@Entity()
class TagEntity {
  @Id()
  int id = 0;

  @Index()
  String name;

  int colorValue;

  final notes = ToMany<NoteEntity>();

  TagEntity({
    this.id = 0,
    required this.name,
    this.colorValue = 0xFF0088FF,
  });
}

