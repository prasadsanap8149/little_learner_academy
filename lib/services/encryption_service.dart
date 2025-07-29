import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late final Key _key;
  late final Encrypter _encrypter;
  final _storage = const FlutterSecureStorage();
  static const _keyString = 'encryption_key_aes256';
  static const _ivString = 'encryption_iv_aes256';
  
  bool _isInitialized = false;

  /// Initialize the encryption service with AES-256
  /// Generates a 256-bit (32-byte) key for AES-256 encryption
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Generate or retrieve encryption key
      String? storedKey = await _storage.read(key: _keyString);

      if (storedKey == null) {
        // Generate new 256-bit key if not exists
        _key = Key.fromSecureRandom(32); // 32 bytes = 256 bits for AES-256

        // Store it securely
        await _storage.write(key: _keyString, value: base64.encode(_key.bytes));
      } else {
        // Use existing key
        _key = Key(base64.decode(storedKey));
      }

      // Initialize AES-256 encrypter
      _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize encryption service: $e');
    }
  }

  /// Generate a secure random IV for each encryption operation
  IV _generateSecureIV() {
    return IV.fromSecureRandom(16); // 16 bytes for AES block size
  }

  /// Encrypt data using AES-256-CBC
  /// Returns base64 encoded string containing IV + encrypted data
  String encrypt(String data) {
    if (!_isInitialized) {
      throw StateError('EncryptionService not initialized. Call initialize() first.');
    }

    if (data.isEmpty) return '';

    try {
      // Generate a new IV for each encryption
      final iv = _generateSecureIV();
      
      // Encrypt the data
      final encrypted = _encrypter.encrypt(data, iv: iv);
      
      // Combine IV and encrypted data
      final combined = iv.bytes + encrypted.bytes;
      
      return base64.encode(combined);
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Decrypt data using AES-256-CBC
  /// Expects base64 encoded string containing IV + encrypted data
  String decrypt(String encryptedData) {
    if (!_isInitialized) {
      throw StateError('EncryptionService not initialized. Call initialize() first.');
    }

    if (encryptedData.isEmpty) return '';

    try {
      // Decode the base64 data
      final combined = base64.decode(encryptedData);
      
      if (combined.length < 16) {
        throw ArgumentError('Invalid encrypted data format');
      }
      
      // Extract IV (first 16 bytes) and encrypted data (remaining bytes)
      final iv = IV(Uint8List.fromList(combined.take(16).toList()));
      final encryptedBytes = Uint8List.fromList(combined.skip(16).toList());
      
      // Create Encrypted object and decrypt
      final encrypted = Encrypted(encryptedBytes);
      
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Encrypt user data with safe handling of different data types
  Map<String, dynamic> encryptUserData(Map<String, dynamic> userData) {
    if (!_isInitialized) {
      throw StateError('EncryptionService not initialized. Call initialize() first.');
    }

    return userData.map((key, value) {
      try {
        if (value is String && value.isNotEmpty) {
          return MapEntry(key, encrypt(value));
        }
        return MapEntry(key, value);
      } catch (e) {
        // Log error but don't fail the entire operation
        print('Warning: Failed to encrypt field $key: $e');
        return MapEntry(key, value);
      }
    });
  }

  /// Decrypt user data with safe handling of different data types
  Map<String, dynamic> decryptUserData(Map<String, dynamic> encryptedData) {
    if (!_isInitialized) {
      throw StateError('EncryptionService not initialized. Call initialize() first.');
    }

    return encryptedData.map((key, value) {
      try {
        // Don't decrypt certain system fields
        if (value is String && 
            value.isNotEmpty && 
            !_isSystemField(key)) {
          return MapEntry(key, decrypt(value));
        }
        return MapEntry(key, value);
      } catch (e) {
        // Log error but don't fail the entire operation
        print('Warning: Failed to decrypt field $key: $e');
        return MapEntry(key, value);
      }
    });
  }

  /// Check if a field is a system field that shouldn't be encrypted
  bool _isSystemField(String key) {
    const systemFields = {
      'uid', 'id', 'timestamp', 'createdAt', 'updatedAt', 
      'version', 'type', 'status'
    };
    return systemFields.contains(key);
  }

  /// Encrypt sensitive data like passwords with additional salt
  String encryptSensitiveData(String data, {String? additionalSalt}) {
    if (!_isInitialized) {
      throw StateError('EncryptionService not initialized. Call initialize() first.');
    }

    if (data.isEmpty) return '';

    try {
      // Add salt to the data for additional security
      final salt = additionalSalt ?? _generateRandomString(16);
      final saltedData = '$salt:$data';
      
      return encrypt(saltedData);
    } catch (e) {
      throw Exception('Failed to encrypt sensitive data: $e');
    }
  }

  /// Decrypt sensitive data and remove salt
  String decryptSensitiveData(String encryptedData) {
    if (!_isInitialized) {
      throw StateError('EncryptionService not initialized. Call initialize() first.');
    }

    if (encryptedData.isEmpty) return '';

    try {
      final decryptedData = decrypt(encryptedData);
      
      // Remove salt (format: salt:data)
      final colonIndex = decryptedData.indexOf(':');
      if (colonIndex != -1 && colonIndex < decryptedData.length - 1) {
        return decryptedData.substring(colonIndex + 1);
      }
      
      return decryptedData;
    } catch (e) {
      throw Exception('Failed to decrypt sensitive data: $e');
    }
  }

  /// Generate a random string for salting
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  /// Reset encryption keys (use with caution - will invalidate all encrypted data)
  Future<void> resetKeys() async {
    try {
      await _storage.delete(key: _keyString);
      _isInitialized = false;
      await initialize();
    } catch (e) {
      throw Exception('Failed to reset encryption keys: $e');
    }
  }

  /// Check if the service is properly initialized
  bool get isInitialized => _isInitialized;

  /// Get encryption algorithm info
  String get encryptionInfo => 'AES-256-CBC with random IV per operation';
}
}
