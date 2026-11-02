import 'package:flutter/services.dart';

class WidgetSyncService {
  static const MethodChannel _homeWidgetChannel = MethodChannel('inotes/home_widget');
  static const MethodChannel _quickNoteChannel = MethodChannel('inotes/quick_note');

  /// Requests the native Android side to refresh all 6 homescreen widgets.
  static Future<void> updateWidgets() async {
    try {
      await _homeWidgetChannel.invokeMethod('updateWidget');
    } catch (_) {}
  }

  /// Checks if the app was launched via a Quick Settings tile, homescreen widget, or intent.
  static Future<Map<String, dynamic>?> getInitialIntent() async {
    try {
      final res = await _quickNoteChannel.invokeMethod('getInitialIntent');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return null;
  }
}

