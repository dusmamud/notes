// Exact domain enums verified and extracted from target APK binary (libapp.so)

enum NoteBlockKind {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  checkList,
  quote,
  codeBlock,
  mathBlock,
  table,
}

enum NoteKind {
  standard,
  mathNote,
  quickNote,
  lockedNote,
}

enum NoteFontFace {
  pretenda,
  sans,
  serif,
  monospace,
  handwriting,
}

enum NoteTextScaler {
  small(0.85),
  medium(1.0),
  large(1.2),
  extraLarge(1.4);

  final double scale;
  const NoteTextScaler(this.scale);
}

enum NoteLinkStage {
  unlinked,
  resolving,
  linked,
}

enum MathLineKind {
  expression,
  assignment,
  statement,
  plainText,
}
