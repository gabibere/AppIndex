import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';
import '../utils/debug_logger.dart';

class EncryptionService {
  static late Encrypter _encrypter;
  static late Key _key;
  static late IV _iv;

  // Initialize encryption with a 32-byte key and 16-byte IV
  static void initialize() {
    // Use a fixed key and IV for demo purposes
    // In production, these should be securely generated and stored
    const keyString = '9(gBRk@+!F%mS@RA7TsL4=9t<vbgeMFl';
    const ivString = 'lDRdxt-iC>,a1PJ*';

    // Create exactly 32 bytes for AES-256 key
    final keyBytes = utf8.encode(keyString);
    final key32Bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key32Bytes[i] = i < keyBytes.length ? keyBytes[i] : 0;
    }

    // Create exactly 16 bytes for IV
    final ivBytes = utf8.encode(ivString);
    final iv16Bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      iv16Bytes[i] = i < ivBytes.length ? ivBytes[i] : 0;
    }

    _key = Key(key32Bytes);
    _iv = IV(iv16Bytes);
    _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

    if (AppConfig.showDebugInfo) {
      DebugLogger.api('🔐 [ENCRYPTION] Initialized with AES-256-CBC mode');
      DebugLogger.encryption(
          'Key length: ${key32Bytes.length} bytes (256-bit)');
      DebugLogger.encryption('IV length: ${iv16Bytes.length} bytes (128-bit)');
      DebugLogger.encryption('Encryption mode: CBC (Cipher Block Chaining)');
    }
  }

  // Encrypt data
  static String encrypt(String data) {
    if (!AppConfig.enableEncryption) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.encryption('Skipped encryption (disabled)');
      }
      return data;
    }

    try {
      if (AppConfig.showDebugInfo) {
        DebugLogger.api(
            '🔐 [ENCRYPTION] Encrypting data with AES-256-CBC mode');
        DebugLogger.api(
            '🔐 [ENCRYPTION] Data length: ${data.length} characters');
        DebugLogger.api('🔐 [ENCRYPTION] Original data: $data');
      }

      final encrypted = _encrypter.encrypt(data, iv: _iv);
      final result = encrypted.base64;

      if (AppConfig.showDebugInfo) {
        DebugLogger.encryption(
            'AES-256-CBC encrypted result (${result.length} characters): $result');
      }

      return result;
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.encryption('❌ [ENCRYPTION] Encryption failed: $e');
      }
      throw Exception('Encryption failed: $e');
    }
  }

  // Decrypt data
  static String decrypt(String encryptedData) {
    if (!AppConfig.enableEncryption) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.encryption('Skipped decryption (disabled)');
      }
      return encryptedData;
    }

    try {
      if (AppConfig.showDebugInfo) {
        DebugLogger.encryption(
            '🔓 [ENCRYPTION] Decrypting data with AES-256-CBC mode');
        DebugLogger.encryption(
            '🔓 [ENCRYPTION] Data length: ${encryptedData.length} characters');
        DebugLogger.encryption(
            '🔓 [ENCRYPTION] Encrypted data: $encryptedData');
      }

      final encrypted = Encrypted.fromBase64(encryptedData);
      final result = _encrypter.decrypt(encrypted, iv: _iv);

      if (AppConfig.showDebugInfo) {
        DebugLogger.encryption(
            'AES-256-CBC decrypted result (${result.length} characters): $result');
      }

      return result;
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.encryption('❌ [ENCRYPTION] Decryption failed: $e');
      }
      throw Exception('Decryption failed: $e');
    }
  }

  // Hash password using MD5
  static String hashPassword(String password) {
    if (!AppConfig.enableEncryption) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.encryption('Skipped password hashing (disabled)');
      }
      return password;
    }

    if (AppConfig.showDebugInfo) {
      DebugLogger.api(
          '🔐 [ENCRYPTION] Hashing password with MD5 algorithm: $password');
    }

    final bytes = utf8.encode(password);
    final digest = md5.convert(bytes);
    final result = digest.toString();

    if (AppConfig.showDebugInfo) {
      DebugLogger.api('🔐 [ENCRYPTION] MD5 password hash result: $result');
    }

    return result;
  }

  // Generate session token using SHA-256
  static String generateSessionToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    final result = digest.toString().substring(0, 32);

    if (AppConfig.showDebugInfo) {
      DebugLogger.api(
          '🔐 [ENCRYPTION] Generated session token with SHA-256: $result');
    }

    return result;
  }

  // Generate timestamp
  static String generateTimestamp() {
    return DateTime.now().toIso8601String();
  }
}
