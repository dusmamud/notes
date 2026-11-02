import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_entity.dart';

/// One-time canonical unit migration for note.textScale.
/// In previous builds, the slider stored raw sp (12.0 - 28.0) directly into note.textScale.
/// Canonical unit is MULTIPLIER (e.g. 1.0 for 16sp, 0.75 for 12sp, 1.75 for 28sp).
class TextScaleMigrator {
  static const String migrationKey = 'migration_text_scale_units_v1';

  static double spToMultiplier(double sp) => sp / 16.0;

  static double multiplierToSp(double multiplier) => multiplier * 16.0;

  static Future<void> migrateNotes(SharedPreferences prefs, List<NoteEntity> notes) async {
    final bool alreadyMigrated = prefs.getBool(migrationKey) ?? false;
    if (alreadyMigrated) return;

    for (final note in notes) {
      if (note.textScale > 2.0) {
        note.textScale = spToMultiplier(note.textScale);
      }
    }
    await prefs.setBool(migrationKey, true);
  }
}

