import '../services/encryption_service.dart';

/// Utility class for common encryption operations in the Little Learners Academy app
class EncryptionUtils {
  static final EncryptionService _encryptionService = EncryptionService();
  static bool _isInitialized = false;

  /// Initialize encryption service if not already initialized
  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _encryptionService.initialize();
      _isInitialized = true;
    }
  }

  /// Encrypt user profile data before storing
  static Future<Map<String, dynamic>> encryptUserProfile(Map<String, dynamic> profile) async {
    await ensureInitialized();
    return _encryptionService.encryptUserData(profile);
  }

  /// Decrypt user profile data after retrieving
  static Future<Map<String, dynamic>> decryptUserProfile(Map<String, dynamic> encryptedProfile) async {
    await ensureInitialized();
    return _encryptionService.decryptUserData(encryptedProfile);
  }

  /// Encrypt game progress data
  static Future<String> encryptGameProgress(String progressData) async {
    await ensureInitialized();
    return _encryptionService.encrypt(progressData);
  }

  /// Decrypt game progress data
  static Future<String> decryptGameProgress(String encryptedProgress) async {
    await ensureInitialized();
    return _encryptionService.decrypt(encryptedProgress);
  }

  /// Encrypt sensitive payment information
  static Future<String> encryptPaymentInfo(String paymentData) async {
    await ensureInitialized();
    return _encryptionService.encryptSensitiveData(paymentData);
  }

  /// Decrypt sensitive payment information
  static Future<String> decryptPaymentInfo(String encryptedPayment) async {
    await ensureInitialized();
    return _encryptionService.decryptSensitiveData(encryptedPayment);
  }

  /// Encrypt parent/guardian information
  static Future<Map<String, dynamic>> encryptParentInfo(Map<String, dynamic> parentData) async {
    await ensureInitialized();
    
    // Special handling for parent data - encrypt all string fields except system fields
    final encryptedData = <String, dynamic>{};
    
    for (final entry in parentData.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String && !_isSystemField(key)) {
        encryptedData[key] = _encryptionService.encrypt(value);
      } else {
        encryptedData[key] = value;
      }
    }
    
    return encryptedData;
  }

  /// Decrypt parent/guardian information
  static Future<Map<String, dynamic>> decryptParentInfo(Map<String, dynamic> encryptedParentData) async {
    await ensureInitialized();
    
    final decryptedData = <String, dynamic>{};
    
    for (final entry in encryptedParentData.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String && !_isSystemField(key)) {
        try {
          decryptedData[key] = _encryptionService.decrypt(value);
        } catch (e) {
          // If decryption fails, keep original value (might not be encrypted)
          decryptedData[key] = value;
        }
      } else {
        decryptedData[key] = value;
      }
    }
    
    return decryptedData;
  }

  /// Encrypt app settings that contain sensitive information
  static Future<String> encryptAppSettings(String settingsJson) async {
    await ensureInitialized();
    return _encryptionService.encrypt(settingsJson);
  }

  /// Decrypt app settings
  static Future<String> decryptAppSettings(String encryptedSettings) async {
    await ensureInitialized();
    return _encryptionService.decrypt(encryptedSettings);
  }

  /// Encrypt analytics data that might contain PII
  static Future<String> encryptAnalyticsData(String analyticsData) async {
    await ensureInitialized();
    return _encryptionService.encrypt(analyticsData);
  }

  /// Decrypt analytics data
  static Future<String> decryptAnalyticsData(String encryptedAnalytics) async {
    await ensureInitialized();
    return _encryptionService.decrypt(encryptedAnalytics);
  }

  /// Encrypt subscription information
  static Future<Map<String, dynamic>> encryptSubscriptionData(Map<String, dynamic> subscriptionData) async {
    await ensureInitialized();
    
    final sensitiveFields = {'paymentMethodId', 'customerId', 'subscriptionId'};
    final encryptedData = <String, dynamic>{};
    
    for (final entry in subscriptionData.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String && sensitiveFields.contains(key)) {
        encryptedData[key] = _encryptionService.encryptSensitiveData(value);
      } else if (value is String && !_isSystemField(key)) {
        encryptedData[key] = _encryptionService.encrypt(value);
      } else {
        encryptedData[key] = value;
      }
    }
    
    return encryptedData;
  }

  /// Decrypt subscription information
  static Future<Map<String, dynamic>> decryptSubscriptionData(Map<String, dynamic> encryptedSubscriptionData) async {
    await ensureInitialized();
    
    final sensitiveFields = {'paymentMethodId', 'customerId', 'subscriptionId'};
    final decryptedData = <String, dynamic>{};
    
    for (final entry in encryptedSubscriptionData.entries) {
      final key = entry.key;
      final value = entry.value;
      
      try {
        if (value is String && sensitiveFields.contains(key)) {
          decryptedData[key] = _encryptionService.decryptSensitiveData(value);
        } else if (value is String && !_isSystemField(key)) {
          decryptedData[key] = _encryptionService.decrypt(value);
        } else {
          decryptedData[key] = value;
        }
      } catch (e) {
        // If decryption fails, keep original value
        decryptedData[key] = value;
      }
    }
    
    return decryptedData;
  }

  /// Generate a secure token for API calls
  static Future<String> generateSecureToken(String baseData) async {
    await ensureInitialized();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final tokenData = '$baseData:$timestamp';
    return _encryptionService.encryptSensitiveData(tokenData);
  }

  /// Validate and extract data from a secure token
  static Future<String?> validateSecureToken(String token, {Duration? maxAge}) async {
    await ensureInitialized();
    
    try {
      final decryptedToken = _encryptionService.decryptSensitiveData(token);
      final parts = decryptedToken.split(':');
      
      if (parts.length >= 2) {
        final timestamp = int.tryParse(parts.last);
        if (timestamp != null) {
          final tokenAge = DateTime.now().millisecondsSinceEpoch - timestamp;
          final maxAgeMs = maxAge?.inMilliseconds ?? Duration(hours: 24).inMilliseconds;
          
          if (tokenAge <= maxAgeMs) {
            // Return the base data (everything except the timestamp)
            return parts.sublist(0, parts.length - 1).join(':');
          }
        }
      }
    } catch (e) {
      // Token is invalid
    }
    
    return null;
  }

  /// Check if a field should not be encrypted
  static bool _isSystemField(String key) {
    const systemFields = {
      'uid', 'id', 'timestamp', 'createdAt', 'updatedAt', 
      'version', 'type', 'status', 'isActive', 'level',
      'score', 'attempts', 'duration'
    };
    return systemFields.contains(key);
  }

  /// Get encryption service information
  static String get encryptionInfo => _encryptionService.encryptionInfo;

  /// Check if encryption is initialized
  static bool get isInitialized => _isInitialized && _encryptionService.isInitialized;

  /// Reset encryption keys (use with extreme caution)
  static Future<void> resetEncryptionKeys() async {
    await ensureInitialized();
    await _encryptionService.resetKeys();
  }
}
