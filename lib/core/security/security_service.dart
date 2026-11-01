import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const MethodChannel _recentsChannel = MethodChannel('inotes/recents');

  String _hashPin(String pin) {
    return base64Encode(utf8.encode("salt_notes_$pin"));
  }

  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({String reason = "Unlock Notes"}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('app_passcode_hash');
  }

  Future<void> setPasscode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_passcode_hash', _hashPin(pin));
  }

  Future<bool> verifyPasscode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString('app_passcode_hash');
    if (savedHash == null) return true;
    return savedHash == _hashPin(pin);
  }

  Future<void> removePasscode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_passcode_hash');
  }

  Future<void> setRecentsScreenshotPolicy(bool secure) async {
    try {
      await _recentsChannel.invokeMethod('applyRecentsScreenshotPolicy', {'secure': secure});
    } catch (_) {}
  }
}
