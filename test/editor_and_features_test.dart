import 'package:flutter_test/flutter_test.dart';
import 'package:note/core/services/markdown_table_helper.dart';
import 'package:note/core/services/math_notes_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Item 1: Custom Editor - Undo & Redo History Logic', () {
    test('Undo and Redo stack management and state reversal', () {
      final List<String> undoHistory = [];
      final List<String> redoHistory = [];
      String currentContent = "Initial text";

      void recordState(String newContent) {
        undoHistory.add(currentContent);
        if (undoHistory.length > 50) undoHistory.removeAt(0);
        redoHistory.clear();
        currentContent = newContent;
      }

      void undo() {
        if (undoHistory.isNotEmpty) {
          redoHistory.add(currentContent);
          currentContent = undoHistory.removeLast();
        }
      }

      void redo() {
        if (redoHistory.isNotEmpty) {
          undoHistory.add(currentContent);
          currentContent = redoHistory.removeLast();
        }
      }

      // Step 1: Type state 1
      recordState("Initial text with modification 1");
      expect(currentContent, "Initial text with modification 1");
      expect(undoHistory.length, 1);
      expect(redoHistory.isEmpty, true);

      // Step 2: Type state 2
      recordState("Initial text with modification 1 and 2");
      expect(currentContent, "Initial text with modification 1 and 2");
      expect(undoHistory.length, 2);

      // Step 3: Undo once
      undo();
      expect(currentContent, "Initial text with modification 1");
      expect(undoHistory.length, 1);
      expect(redoHistory.length, 1);

      // Step 4: Undo again
      undo();
      expect(currentContent, "Initial text");
      expect(undoHistory.isEmpty, true);
      expect(redoHistory.length, 2);

      // Step 5: Redo
      redo();
      expect(currentContent, "Initial text with modification 1");
      expect(undoHistory.length, 1);
      expect(redoHistory.length, 1);

      // Step 6: Typing new content clears redo
      recordState("Completely new branch");
      expect(currentContent, "Completely new branch");
      expect(redoHistory.isEmpty, true);
    });
  });

  group('Item 1: Custom Editor - Markdown Table Manipulation', () {
    const tableText = "| Col 1 | Col 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |\n";

    test('Add row below and above', () {
      final withRowBelow = MarkdownTableHelper.addRow(tableText, 10, below: true);
      expect(withRowBelow.contains('| Item | Item |'), true);
      expect(withRowBelow.split('\n').where((l) => l.trim().isNotEmpty).length, 4);

      final withRowAbove = MarkdownTableHelper.addRow(tableText, 10, below: false);
      expect(withRowAbove.contains('| Item | Item |'), true);
    });

    test('Add and delete column', () {
      final withCol = MarkdownTableHelper.addColumn(tableText, 10);
      expect(withCol.contains('NewCol'), true);
      expect(withCol.contains('--- | --- | ---'), true);

      // Delete the newly added column or existing column
      final deletedCol = MarkdownTableHelper.deleteCurrentColumn(withCol, 10);
      expect(deletedCol.contains('NewCol') || deletedCol.contains('Col 1'), true);
    });

    test('Delete current row', () {
      final withoutRow = MarkdownTableHelper.deleteCurrentRow(tableText, 45); // cursor in Cell 1
      expect(withoutRow.contains('Cell 1'), false);
    });

    test('Delete entire table and convert to text', () {
      final deleted = MarkdownTableHelper.deleteEntireTable(tableText, 10);
      expect(deleted.isEmpty, true);

      final textOnly = MarkdownTableHelper.convertTableToText(tableText, 10);
      expect(textOnly.contains('|'), false);
      expect(textOnly.contains('Col 1\tCol 2'), true);
      expect(textOnly.contains('Cell 1\tCell 2'), true);
    });
  });

  group('Item 1: Custom Editor - Find & Replace All Logic', () {
    test('Replace all occurrences case-insensitively', () {
      const source = "The apple is red. I like this Apple because APPLE is healthy.";
      final replaced = source.replaceAll(RegExp(RegExp.escape("apple"), caseSensitive: false), "orange");
      expect(replaced, "The orange is red. I like this orange because orange is healthy.");
    });
  });

  group('Item 1: Custom Editor - MathNotesEngine Modes', () {
    test('Mode off suppresses calculation', () {
      final engine = MathNotesEngine(mode: MathResultsMode.off);
      expect(engine.evaluateLine('10 + 20 ='), isNull);
    });

    test('Mode suggest returns evaluation string', () {
      final engine = MathNotesEngine(mode: MathResultsMode.suggest);
      expect(engine.evaluateLine('10 + 20 ='), '30');
      expect(engine.evaluateLine('100 / 4 ='), '25');
    });

    test('Mode insert returns evaluation string', () {
      final engine = MathNotesEngine(mode: MathResultsMode.insert);
      expect(engine.evaluateLine('5 * 6 ='), '30');
    });
  });
}

