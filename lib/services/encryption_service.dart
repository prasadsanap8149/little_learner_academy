import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late final Key _key;
  late final IV _iv;
  late final Encrypter _encrypter;
  final _storage = const FlutterSecureStorage();
  static const _keyString = 'encryption_key';
  static const _ivString = 'encryption_iv';

  Future<void> initialize() async {
    // Generate or retrieve encryption key
    String? storedKey = await _storage.read(key: _keyString);
    String? storedIV = await _storage.read(key: _ivString);

    if (storedKey == null || storedIV == null) {
      // Generate new key and IV if not exists
      _key = Key.fromSecureRandom(32);
      _iv = IV.fromSecureRandom(16);

      // Store them securely
      await _storage.write(key: _keyString, value: base64.encode(_key.bytes));
      await _storage.write(key: _ivString, value: base64.encode(_iv.bytes));
    } else {
      // Use existing key and IV
      _key = Key(base64.decode(storedKey));
      _iv = IV(base64.decode(storedIV));
    }

    _encrypter = Encrypter(AES(_key));
  }

  String encrypt(String data) {
    return _encrypter.encrypt(data, iv: _iv).base64;
  }

  String decrypt(String encryptedData) {
    return _encrypter.decrypt64(encryptedData, iv: _iv);
  }

  // Encrypt user data
  Map<String, dynamic> encryptUserData(Map<String, dynamic> userData) {
    return userData.map((key, value) {
      if (value is String) {
        return MapEntry(key, encrypt(value));
      }
      return MapEntry(key, value);
    });
  }

  // Decrypt user data
  Map<String, dynamic> decryptUserData(Map<String, dynamic> encryptedData) {
    return encryptedData.map((key, value) {
      if (value is String && key != 'uid') {
        return MapEntry(key, decrypt(value));
      }
      return MapEntry(key, value);
    });
  }
}
