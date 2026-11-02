class TableRegion {
  final int startOffset;
  final int endOffset;
  final List<String> lines;
  final int cursorRowIndex;
  final int cursorColIndex;

  TableRegion({
    required this.startOffset,
    required this.endOffset,
    required this.lines,
    required this.cursorRowIndex,
    required this.cursorColIndex,
  });
}

class MarkdownTableHelper {
  static bool isTableRow(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('|') && trimmed.endsWith('|') && trimmed.length > 2;
  }

  static TableRegion? parseTableAt(String text, int cursor) {
    if (text.isEmpty) return null;
    final clampedCursor = cursor.clamp(0, text.length);

    // Split text into lines with their start offsets
    final lines = text.split('\n');
    int currentOffset = 0;
    int cursorLine = 0;
    int cursorColInLine = 0;

    for (int i = 0; i < lines.length; i++) {
      final lineEnd = currentOffset + lines[i].length;
      if (clampedCursor >= currentOffset && clampedCursor <= lineEnd) {
        cursorLine = i;
        cursorColInLine = clampedCursor - currentOffset;
        break;
      }
      currentOffset = lineEnd + 1; // +1 for '\n'
    }

    if (!isTableRow(lines[cursorLine])) {
      return null;
    }

    // Find contiguous table start
    int startLine = cursorLine;
    while (startLine > 0 && isTableRow(lines[startLine - 1])) {
      startLine--;
    }

    // Find contiguous table end
    int endLine = cursorLine;
    while (endLine < lines.length - 1 && isTableRow(lines[endLine + 1])) {
      endLine++;
    }

    // Compute start and end offsets in original text
    int startOffset = 0;
    for (int i = 0; i < startLine; i++) {
      startOffset += lines[i].length + 1;
    }

    int endOffset = startOffset;
    final tableLines = <String>[];
    for (int i = startLine; i <= endLine; i++) {
      tableLines.add(lines[i]);
      endOffset += lines[i].length + (i < lines.length - 1 ? 1 : 0);
    }

    // Find which column the cursor is in (count '|' characters before cursor)
    final targetLine = lines[cursorLine];
    int colIndex = 0;
    for (int i = 0; i < cursorColInLine && i < targetLine.length; i++) {
      if (targetLine[i] == '|') colIndex++;
    }
    // Adjust to 0-based index of actual data column
    colIndex = (colIndex - 1).clamp(0, 50);

    return TableRegion(
      startOffset: startOffset,
      endOffset: endOffset,
      lines: tableLines,
      cursorRowIndex: cursorLine - startLine,
      cursorColIndex: colIndex,
    );
  }

  static String deleteCurrentRow(String text, int cursor) {
    final region = parseTableAt(text, cursor);
    if (region == null) return text;

    final newLines = List<String>.from(region.lines);
    if (region.cursorRowIndex >= 0 && region.cursorRowIndex < newLines.length) {
      newLines.removeAt(region.cursorRowIndex);
    }

    // If only header or separator remains or table empty, remove completely
    if (newLines.length <= 1) {
      return text.replaceRange(region.startOffset, region.endOffset, "");
    }

    final newTableText = newLines.join('\n');
    return text.replaceRange(region.startOffset, region.endOffset, newTableText);
  }

  static String deleteCurrentColumn(String text, int cursor) {
    final region = parseTableAt(text, cursor);
    if (region == null) return text;

    final colToRemove = region.cursorColIndex;
    final newLines = <String>[];

    for (var line in region.lines) {
      final cells = line.split('|');
      // format: ["", cell0, cell1, cell2, ""]
      if (cells.length > 2) {
        final dataCells = cells.sublist(1, cells.length - 1);
        if (colToRemove < dataCells.length) {
          dataCells.removeAt(colToRemove);
        }
        if (dataCells.isEmpty) {
          return text.replaceRange(region.startOffset, region.endOffset, "");
        }
        newLines.add("|${dataCells.join('|')}|");
      } else {
        newLines.add(line);
      }
    }

    final newTableText = newLines.join('\n');
    return text.replaceRange(region.startOffset, region.endOffset, newTableText);
  }

  static String addRow(String text, int cursor, {bool below = true}) {
    final region = parseTableAt(text, cursor);
    if (region == null) {
      // If outside table, insert a default 2x2 table
      return "$text\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |\n";
    }

    final headerCells = region.lines.first.split('|');
    final colCount = (headerCells.length > 2) ? headerCells.length - 2 : 2;
    final newRow = "|${List.filled(colCount, ' Item ').join('|')}|";

    final newLines = List<String>.from(region.lines);
    final targetIndex = below
        ? (region.cursorRowIndex + 1).clamp(0, newLines.length)
        : region.cursorRowIndex.clamp(0, newLines.length);

    newLines.insert(targetIndex, newRow);
    return text.replaceRange(region.startOffset, region.endOffset, newLines.join('\n'));
  }

  static String addColumn(String text, int cursor) {
    final region = parseTableAt(text, cursor);
    if (region == null) {
      return "$text\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |\n";
    }

    final newLines = <String>[];
    for (int i = 0; i < region.lines.length; i++) {
      final line = region.lines[i];
      final trimmed = line.trim();
      if (trimmed.endsWith('|')) {
        final prefix = trimmed.substring(0, trimmed.length - 1);
        if (i == 0) {
          newLines.add("$prefix| NewCol |");
        } else if (i == 1 && trimmed.contains('---')) {
          newLines.add("$prefix| --- |");
        } else {
          newLines.add("$prefix| Item |");
        }
      } else {
        newLines.add(line);
      }
    }

    return text.replaceRange(region.startOffset, region.endOffset, newLines.join('\n'));
  }

  static String deleteEntireTable(String text, int cursor) {
    final region = parseTableAt(text, cursor);
    if (region == null) return text;
    return text.replaceRange(region.startOffset, region.endOffset, "").trim();
  }

  static String? copyTableOnly(String text, int cursor) {
    final region = parseTableAt(text, cursor);
    if (region == null) return null;
    return region.lines.join('\n');
  }

  static String convertTableToText(String text, int cursor) {
    final region = parseTableAt(text, cursor);
    if (region == null) return text;

    final convertedLines = <String>[];
    for (var line in region.lines) {
      if (line.contains('---')) continue; // Skip separator line
      final cells = line.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty);
      if (cells.isNotEmpty) {
        convertedLines.add(cells.join('\t'));
      }
    }

    return text.replaceRange(region.startOffset, region.endOffset, convertedLines.join('\n'));
  }
}

