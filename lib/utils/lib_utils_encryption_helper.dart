import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  /// Hash mật khẩu bằng SHA-256
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Verify mật khẩu
  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  /// Hash mã PIN
  static String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  /// Verify mã PIN
  static bool verifyPin(String pin, String hash) {
    return hashPin(pin) == hash;
  }
}