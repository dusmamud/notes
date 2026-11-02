import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note/core/theme/app_theme_controller.dart';
import 'package:note/features/notes/data/models/note_entity.dart';
import 'package:note/features/notes/data/repositories/note_repository_impl.dart';
import 'package:note/features/backup/data/repositories/backup_repository.dart';
import 'package:note/features/settings/presentation/screens/settings_screen.dart';
import 'package:note/features/premium/presentation/screens/premium_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Notes',
      packageName: 'com.dusrel.note',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final ctrl = AppThemeController.instance;
    await ctrl.load();

    tempDir = Directory.systemTemp.createTempSync('backup_test_dir_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Item 3c: BackupRepository Persistent Backup & Workmanager Schedule', () {
    test('createPersistentBackup creates ZIP in documents/backups directory with manifest', () async {
      final repo = NoteRepositoryImpl();
      await repo.saveNote(NoteEntity(
        title: 'Persistent Backup Note',
        contentMarkdown: 'Testing persistent archive creation.',
      ));

      final backupRepo = BackupRepository(repository: repo);
      final file = await backupRepo.createPersistentBackup();

      expect(file.existsSync(), true);
      expect(file.path.contains('backups'), true);
      expect(file.lengthSync() > 0, true);

      // Verify restore roundtrip
      final restoreRepo = NoteRepositoryImpl();
      final restoreBackupRepo = BackupRepository(repository: restoreRepo);
      final success = await restoreBackupRepo.restoreFromZip(file);
      expect(success, true);

      final restoredNotes = await restoreRepo.getAllNotes();
      expect(restoredNotes.any((n) => n.title == 'Persistent Backup Note'), true);
    });

    test('scheduleDailyBackup handles enable/disable cleanly without unhandled exceptions', () async {
      final repo = NoteRepositoryImpl();
      final backupRepo = BackupRepository(repository: repo);

      await expectLater(backupRepo.scheduleDailyBackup(true), completes);
      await expectLater(backupRepo.scheduleDailyBackup(false), completes);
    });
  });

  group('Item 3a: Settings Screen Honest Sync Row & Backup UI', () {
    testWidgets('Cloud Sync row displays Not Connected and shows info dialog without paywall', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = NoteRepositoryImpl();
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Find Cloud Sync row
      final syncRow = find.text("Cloud Sync (Not Connected)");
      expect(syncRow, findsOneWidget);
      expect(find.text("Notes stored locally on device · Cloud sync not configured"), findsOneWidget);

      // Tap on Cloud Sync row
      await tester.tap(syncRow);
      await tester.pumpAndSettle();

      // Info dialog appears explaining local-only state
      expect(find.text("Cloud Sync"), findsWidgets);
      expect(find.textContaining("Cloud Sync is currently not connected"), findsOneWidget);
      expect(find.text("Upgrade to Premium"), findsNothing); // Does NOT route to paywall

      // Dismiss dialog
      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();
      expect(find.textContaining("Cloud Sync is currently not connected"), findsNothing);
    });

    testWidgets('Local Backup & Restore tile is present with honest description', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = NoteRepositoryImpl();
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Local Backup & Restore"), findsOneWidget);
      expect(find.text("Create or restore local ZIP archives"), findsOneWidget);
    });
  });

  group('Item 3b: Premium Sheet Disabled Notices & Fake Delay Removal', () {
    testWidgets('PremiumSheet displays disabled store notices and no fake rewards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool rewarded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumSheet(
              onRewardUnlocked: () {
                rewarded = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify disabled button text
      final purchaseBtn = find.text("Store Purchases Disabled (Pending Setup)");
      final adBtn = find.text("Rewarded Ads Disabled (AdMob Required)");
      final restoreBtn = find.text("Restore Purchases (Disabled)");

      expect(purchaseBtn, findsOneWidget);
      expect(adBtn, findsOneWidget);
      expect(restoreBtn, findsOneWidget);

      // Tap ad button -> shows disabled dialog, does NOT unlock reward
      await tester.ensureVisible(adBtn);
      await tester.tap(adBtn);
      await tester.pumpAndSettle();

      expect(find.text("Ads Disabled"), findsOneWidget);
      expect(find.textContaining("Google AdMob App ID and Ad Unit credentials are required"), findsOneWidget);
      expect(rewarded, false);

      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();

      // Tap purchase button -> shows disabled dialog
      await tester.ensureVisible(purchaseBtn);
      await tester.tap(purchaseBtn);
      await tester.pumpAndSettle();

      expect(find.text("Store Purchases Disabled"), findsOneWidget);
      expect(find.textContaining("Google Play Billing integration and SKU configuration are required"), findsOneWidget);

      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();

      // Tap restore button -> shows disabled dialog
      await tester.ensureVisible(restoreBtn);
      await tester.tap(restoreBtn);
      await tester.pumpAndSettle();

      expect(find.text("Restore Purchases"), findsOneWidget);
      expect(find.textContaining("Subscription restoration is currently disabled"), findsOneWidget);

      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();

      // Still no fake reward was triggered
      expect(rewarded, false);
    });
  });
}
