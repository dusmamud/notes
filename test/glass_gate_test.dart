import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:note/core/theme/app_theme_controller.dart';
import 'package:note/features/settings/presentation/screens/style_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Item 2: Glass Capability Gate & Dialog Verification', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final ctrl = AppThemeController.instance;
      await ctrl.load();
      await ctrl.setUiStyle('classic');
    });

    tearDown(() {
      GlassCapabilityChecker.setMockSupported(null);
    });

    testWidgets('Capable device: switching to Glass succeeds directly without dialog', (tester) async {
      GlassCapabilityChecker.setMockSupported(true);
      final ctrl = AppThemeController.instance;
      expect(ctrl.uiStyle, 'classic');

      await tester.pumpWidget(
        MaterialApp(
          home: const StyleScreen(),
        ),
      );

      // Tap on Glass card
      final glassCard = find.text("Glass");
      expect(glassCard, findsOneWidget);
      await tester.tap(glassCard);
      await tester.pumpAndSettle();

      // No dialog shown, style switched to glass
      expect(find.text("Unsupported Device"), findsNothing);
      expect(ctrl.uiStyle, 'glass');
    });

    testWidgets('Incapable device: shows dialog, Cancel retains Classic style', (tester) async {
      GlassCapabilityChecker.setMockSupported(false);
      final ctrl = AppThemeController.instance;
      expect(ctrl.uiStyle, 'classic');

      await tester.pumpWidget(
        MaterialApp(
          home: const StyleScreen(),
        ),
      );

      // Tap on Glass card
      final glassCard = find.text("Glass");
      await tester.tap(glassCard);
      await tester.pumpAndSettle();

      // Dialog is displayed
      expect(find.text("Unsupported Device"), findsOneWidget);
      expect(find.text("Switch to Glass anyway?"), findsOneWidget);

      // Tap Cancel
      final cancelButton = find.text("Cancel");
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog dismissed, style remains classic
      expect(find.text("Unsupported Device"), findsNothing);
      expect(ctrl.uiStyle, 'classic');
    });

    testWidgets('Incapable device: shows dialog, OK forces Glass style', (tester) async {
      GlassCapabilityChecker.setMockSupported(false);
      final ctrl = AppThemeController.instance;
      expect(ctrl.uiStyle, 'classic');

      await tester.pumpWidget(
        MaterialApp(
          home: const StyleScreen(),
        ),
      );

      // Tap on Glass card
      final glassCard = find.text("Glass");
      await tester.tap(glassCard);
      await tester.pumpAndSettle();

      expect(find.text("Unsupported Device"), findsOneWidget);

      // Tap OK
      final okButton = find.text("OK");
      expect(okButton, findsOneWidget);
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      // Dialog dismissed, style forced to glass
      expect(find.text("Unsupported Device"), findsNothing);
      expect(ctrl.uiStyle, 'glass');
    });
  });
}

