import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const MethodChannel _recentsChannel = MethodChannel('com.dusrel.note/recents');

  static const String _passcodeHashKey = 'app_passcode_hash';
  static const String _passcodeSaltKey = 'app_passcode_salt';
  static const String _failedAttemptsKey = 'app_passcode_failed_attempts';
  static const String _lockoutTimestampKey = 'app_passcode_lockout_until';

  // Separate Note Lock credentials
  static const String _notePasswordHashKey = 'note_lock_password_hash';
  static const String _notePasswordSaltKey = 'note_lock_password_salt';

  static const int maxAttempts = 5;
  static const int lockoutDurationSeconds = 30;
  static const int pbkdf2Iterations = 10000;
  static const int pbkdf2KeyLength = 32;

  String _generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  Uint8List _deriveKeyPbkdf2(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, pbkdf2Iterations, pbkdf2KeyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
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

  // App Lock Passcode methods
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
      // Fail closed
      return false;
    }

    final computed = _computeSha256(pin, savedSalt);
    if (computed == savedHash) {
      await prefs.setInt(_failedAttemptsKey, 0);
      await prefs.remove(_lockoutTimestampKey);
      return true;
    } else {
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

  // Note Lock separate password methods
  Future<bool> hasNotePassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_notePasswordHashKey) && prefs.containsKey(_notePasswordSaltKey);
  }

  Future<void> setNotePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _computeSha256(password, salt);
    await prefs.setString(_notePasswordSaltKey, salt);
    await prefs.setString(_notePasswordHashKey, hash);
  }

  Future<bool> verifyNotePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString(_notePasswordHashKey);
    final savedSalt = prefs.getString(_notePasswordSaltKey);
    if (savedHash == null || savedSalt == null) return false;
    return _computeSha256(password, savedSalt) == savedHash;
  }

  Future<void> setRecentsScreenshotPolicy(bool secure) async {
    try {
      await _recentsChannel.invokeMethod('applyRecentsScreenshotPolicy', {'hideInRecents': secure});
    } catch (_) {}
  }

  /// AES-256 CBC local encryption for locked note content with PBKDF2 key derivation.
  /// Format: saltBase64:ivBase64:cipherBase64
  String encryptNoteContent(String plainText, String keyString) {
    if (plainText.isEmpty) return "";
    final salt = Uint8List.fromList(List<int>.generate(16, (i) => Random.secure().nextInt(256)));
    final keyBytes = _deriveKeyPbkdf2(keyString, salt);
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return "${base64Url.encode(salt)}:${base64Url.encode(iv.bytes)}:${encrypted.base64}";
  }

  /// Fail-closed decryption: on incorrect key or format mismatch, returns empty string.
  /// NEVER returns plaintext or raw input on failure.
  String decryptNoteContent(String cipherTextWithSaltIv, String keyString) {
    if (cipherTextWithSaltIv.isEmpty) return "";
    final parts = cipherTextWithSaltIv.split(':');
    if (parts.length != 3) {
      // Fail-closed: invalid format
      return "";
    }
    try {
      final salt = base64Url.decode(parts[0]);
      final ivBytes = base64Url.decode(parts[1]);
      final keyBytes = _deriveKeyPbkdf2(keyString, salt);
      final key = enc.Key(keyBytes);
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key));
      return encrypter.decrypt(enc.Encrypted.fromBase64(parts[2]), iv: iv);
    } catch (_) {
      // Fail-closed: never return ciphertext or raw input
      return "";
    }
  }
}
