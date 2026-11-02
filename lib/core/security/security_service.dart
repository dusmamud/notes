import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const MethodChannel _recentsChannel = MethodChannel('com.dusrel.note/recents');

  static const String _passcodeHashKey = 'app_passcode_hash';
  static const String _passcodeSaltKey = 'app_passcode_salt';
  static const String _failedAttemptsKey = 'app_passcode_failed_attempts';
  static const String _lockoutTimestampKey = 'app_passcode_lockout_until';

  static const int maxAttempts = 5;
  static const int lockoutDurationSeconds = 30;

  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  String _computeSha256(String pin, String salt) {
    final bytes = utf8.encode("$salt#dusrel_note_kdf#$pin");
    return sha256.convert(bytes).toString();
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
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_passcodeHashKey) && prefs.containsKey(_passcodeSaltKey);
  }

  Future<void> setPasscode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _computeSha256(pin, salt);
    await prefs.setString(_passcodeSaltKey, salt);
    await prefs.setString(_passcodeHashKey, hash);
    await prefs.setInt(_failedAttemptsKey, 0);
    await prefs.remove(_lockoutTimestampKey);
  }

  Future<int> getRemainingLockoutSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_lockoutTimestampKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (until > now) {
      return ((until - now) / 1000).ceil();
    }
    return 0;
  }

  Future<bool> verifyPasscode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final remainingLockout = await getRemainingLockoutSeconds();
    if (remainingLockout > 0) {
      return false;
    }

    final savedHash = prefs.getString(_passcodeHashKey);
    final savedSalt = prefs.getString(_passcodeSaltKey);
    if (savedHash == null || savedSalt == null) {
      // Fail closed: if no passcode exists, cannot verify
      return false;
    }

    final computed = _computeSha256(pin, savedSalt);
    if (computed == savedHash) {
      // Reset failed attempts on success
      await prefs.setInt(_failedAttemptsKey, 0);
      await prefs.remove(_lockoutTimestampKey);
      return true;
    } else {
      // Increment failed attempts
      final attempts = (prefs.getInt(_failedAttemptsKey) ?? 0) + 1;
      await prefs.setInt(_failedAttemptsKey, attempts);
      if (attempts >= maxAttempts) {
        final lockoutUntil = DateTime.now().millisecondsSinceEpoch + (lockoutDurationSeconds * 1000);
        await prefs.setInt(_lockoutTimestampKey, lockoutUntil);
      }
      return false;
    }
  }

  Future<void> removePasscode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passcodeHashKey);
    await prefs.remove(_passcodeSaltKey);
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lockoutTimestampKey);
  }

  Future<void> setRecentsScreenshotPolicy(bool secure) async {
    try {
      await _recentsChannel.invokeMethod('applyRecentsScreenshotPolicy', {'hideInRecents': secure});
    } catch (_) {}
  }

  /// AES-256 CBC local encryption for locked note content
  String encryptNoteContent(String plainText, String keyString) {
    if (plainText.isEmpty) return "";
    final keyBytes = sha256.convert(utf8.encode(keyString)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return "${base64Url.encode(iv.bytes)}:${encrypted.base64}";
  }

  String decryptNoteContent(String cipherTextWithIv, String keyString) {
    if (cipherTextWithIv.isEmpty) return "";
    final parts = cipherTextWithIv.split(':');
    if (parts.length != 2) return cipherTextWithIv; // Fallback to raw if not encrypted
    try {
      final ivBytes = base64Url.decode(parts[0]);
      final keyBytes = sha256.convert(utf8.encode(keyString)).bytes;
      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key));
      return encrypter.decrypt(enc.Encrypted.fromBase64(parts[1]), iv: iv);
    } catch (_) {
      return cipherTextWithIv;
    }
  }
}
