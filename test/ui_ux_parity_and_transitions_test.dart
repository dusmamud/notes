import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:note/core/constants/app_colors.dart';
import 'package:note/features/notes/data/models/note_entity.dart';
import 'package:note/features/notes/data/repositories/note_repository_impl.dart';
import 'package:note/features/notes/presentation/widgets/note_card.dart';
import 'package:note/features/notes/presentation/screens/note_editor_screen.dart';
import 'package:note/features/notes/presentation/widgets/page_appearance_sheet.dart';
import 'package:note/features/premium/presentation/screens/premium_sheet.dart';
import 'package:note/features/notes/presentation/widgets/attachment_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Prompt 7: Global Transitions & Hero Parity', () {
    testWidgets('NoteCard and NoteEditorScreen have matching Hero tags', (tester) async {
      final note = NoteEntity(
        id: 77,
        title: 'Parity Note',
        contentMarkdown: 'Testing shared element transition',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Verify NoteCard has Hero tag
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteCard(
              note: note,
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      );

      final heroInCard = tester.widget<Hero>(
        find.descendant(of: find.byType(NoteCard), matching: find.byType(Hero)),
      );
      expect(heroInCard.tag, 'note_77');

      // Verify NoteEditorScreen has matching Hero tag when enableHero is true
      final repo = NoteRepositoryImpl();
      await tester.pumpWidget(
        MaterialApp(
          home: NoteEditorScreen(
            note: note,
            repository: repo,
            enableHero: true,
          ),
        ),
      );

      final heroInEditor = tester.widget<Hero>(
        find.descendant(of: find.byType(NoteEditorScreen), matching: find.byType(Hero)),
      );
      expect(heroInEditor.tag, 'note_77');

      // Verify enableHero: false does NOT render Hero (preventing tablet collision)
      await tester.pumpWidget(
        MaterialApp(
          home: NoteEditorScreen(
            note: note,
            repository: repo,
            enableHero: false,
          ),
        ),
      );

      final heroInTabletEditor = find.descendant(
        of: find.byType(NoteEditorScreen),
        matching: find.byType(Hero),
      );
      expect(heroInTabletEditor, findsNothing);
    });

    testWidgets('NoteCard swipe Pin action has orange color', (tester) async {
      final note = NoteEntity(
        id: 10,
        title: 'Pin Test Note',
        contentMarkdown: 'Testing Pin swipe color',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteCard(
              note: note,
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      );

      // Find SlidableAction for Pin from Slidable startActionPane
      final slidable = tester.widget<Slidable>(find.byType(Slidable));
      final actions = slidable.startActionPane!.children;
      final pinAction = actions.first as SlidableAction;
      expect(pinAction.backgroundColor, AppColors.tagOrange);
      expect(pinAction.backgroundColor, const Color(0xFFFF8C27));
      expect(pinAction.label, 'Pin');
    });
  });

  group('Prompt 7: Note Editor Undo/Redo Long-Press Parity', () {
    testWidgets('Undo button tooltip promises Hold for Redo and long-press triggers redo', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = NoteRepositoryImpl();
      final note = NoteEntity(
        id: 101,
        title: 'Undo Test',
        contentMarkdown: 'Initial',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NoteEditorScreen(
            note: note,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Undo button and tooltip
      final undoBtn = find.byTooltip("Undo (Hold for Redo)");
      expect(undoBtn, findsOneWidget);

      // Tap Checklist button in accessory toolbar -> inserts '- [ ] ' and records undo state
      final checklistBtn = find.byTooltip("Checklist");
      expect(checklistBtn, findsOneWidget);
      await tester.tap(checklistBtn);
      await tester.pumpAndSettle();

      TextField bodyField() => tester.widget<TextField>(find.byType(TextField).last);
      expect(bodyField().controller!.text, contains('- [ ]'));

      // Tap Undo button -> reverts to 'Initial'
      await tester.tap(undoBtn);
      await tester.pumpAndSettle();
      expect(bodyField().controller!.text, 'Initial');

      // Long-press Undo button -> triggers Redo -> restores '- [ ] '
      await tester.longPress(undoBtn);
      await tester.pumpAndSettle();
      expect(bodyField().controller!.text, contains('- [ ]'));
    });
  });

  group('Prompt 7: Spring Draggable Sheets Parity', () {
    testWidgets('PageAppearanceSheet builds with smooth_sheets BouncingSheetPhysics', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final note = NoteEntity(
        id: 202,
        title: 'Sheet Note',
        contentMarkdown: 'Testing sheet',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageAppearanceSheet(
              note: note,
              onAppearanceChanged: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sheetWidget = tester.widget<Sheet>(find.byType(Sheet));
      expect(sheetWidget.physics, isA<BouncingSheetPhysics>());
      expect(find.text('Note Options'), findsOneWidget);
    });

    testWidgets('PremiumSheet builds with smooth_sheets BouncingSheetPhysics', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumSheet(
              onRewardUnlocked: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sheetWidget = tester.widget<Sheet>(find.byType(Sheet));
      expect(sheetWidget.physics, isA<BouncingSheetPhysics>());
      expect(find.text('Notes Premium'), findsOneWidget);
    });
  });

  group('Prompt 7: Scanner Honest Label Parity', () {
    testWidgets('AttachmentSelectorSheet displays Document Photo Capture with unverified disclaimer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentSelectorSheet(
              onActionSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Document Photo Capture'), findsOneWidget);
      expect(
        find.text('Capture photo document into PDF (native edge warp unverified)'),
        findsOneWidget,
      );
    });
  });
}
