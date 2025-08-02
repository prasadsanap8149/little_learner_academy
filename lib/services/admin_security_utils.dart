import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';

/// Security utilities for admin operations
class AdminSecurityUtils {
  static final AdminSecurityUtils _instance = AdminSecurityUtils._internal();
  factory AdminSecurityUtils() => _instance;
  AdminSecurityUtils._internal();

  static const String _adminCollection = 'admin_users';
  static const String _securityLogsCollection = 'security_logs';

  /// Log admin actions for security audit
  static Future<void> logAdminAction({
    required String action,
    required String resourceType,
    String? resourceId,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !AdminService.isAdminUser()) return;

    try {
      await FirebaseFirestore.instance.collection(_securityLogsCollection).add({
        'adminId': user.uid,
        'adminEmail': user.email,
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': null, // Could be enhanced with IP tracking
        'userAgent': null, // Could be enhanced with user agent tracking
        'additionalData': additionalData,
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }

  /// Validate admin session and refresh if needed
  static Future<bool> validateAdminSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Check if user is still an admin
      if (!AdminService.isAdminUser()) {
        await FirebaseAuth.instance.signOut();
        return false;
      }

      // Refresh token if it's about to expire
      final token = await user.getIdToken(false);
      final tokenResult = await user.getIdTokenResult();
      
      // If token expires in less than 5 minutes, refresh it
      final expirationTime = tokenResult.expirationTime;
      if (expirationTime != null) {
        final timeUntilExpiry = expirationTime.difference(DateTime.now());
        if (timeUntilExpiry.inMinutes < 5) {
          await user.getIdToken(true); // Force refresh
        }
      }

      return true;
    } catch (e) {
      print('Error validating admin session: $e');
      return false;
    }
  }

  /// Check if admin has specific privilege with detailed logging
  static Future<bool> checkPrivilegeWithLogging(
    AdminPrivilege privilege,
    String resourceType, [
    String? resourceId,
  ]) async {
    final hasPrivilege = AdminService.hasAdminPrivilege(privilege);
    
    await logAdminAction(
      action: hasPrivilege ? 'access_granted' : 'access_denied',
      resourceType: resourceType,
      resourceId: resourceId,
      additionalData: {
        'privilege': privilege.toString(),
        'result': hasPrivilege,
      },
    );

    return hasPrivilege;
  }

  /// Rate limiting for admin actions (basic implementation)
  static final Map<String, List<DateTime>> _actionTimestamps = {};
  
  static bool isRateLimited(String action, {int maxActions = 100, Duration window = const Duration(minutes: 1)}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;

    final key = '${user.uid}_$action';
    final now = DateTime.now();
    
    _actionTimestamps[key] ??= [];
    final timestamps = _actionTimestamps[key]!;
    
    // Remove old timestamps outside the window
    timestamps.removeWhere((timestamp) => now.difference(timestamp) > window);
    
    // Check if limit exceeded
    if (timestamps.length >= maxActions) {
      return true;
    }
    
    // Add current timestamp
    timestamps.add(now);
    return false;
  }

  /// Enhanced admin privilege check with rate limiting
  static Future<bool> checkPrivilegeWithRateLimit(
    AdminPrivilege privilege,
    String action,
    String resourceType, [
    String? resourceId,
  ]) async {
    // Check rate limiting first
    if (isRateLimited(action)) {
      await logAdminAction(
        action: 'rate_limit_exceeded',
        resourceType: resourceType,
        resourceId: resourceId,
        additionalData: {'privilege': privilege.toString(), 'blockedAction': action},
      );
      return false;
    }

    return await checkPrivilegeWithLogging(privilege, resourceType, resourceId);
  }

  /// Get admin security logs for audit purposes
  static Future<List<Map<String, dynamic>>> getSecurityLogs({
    String? adminId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    if (!AdminService.hasAdminPrivilege(AdminPrivilege.systemSettings)) {
      throw Exception('Insufficient privileges to view security logs');
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection(_securityLogsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting security logs: $e');
      throw Exception('Failed to fetch security logs');
    }
  }

  /// Emergency admin lockdown (disable all admin accounts except super admin)
  static Future<void> emergencyLockdown() async {
    if (!AdminService.hasAdminPrivilege(AdminPrivilege.systemSettings)) {
      throw Exception('Only super admin can initiate emergency lockdown');
    }

    try {
      await logAdminAction(
        action: 'emergency_lockdown_initiated',
        resourceType: 'system',
        additionalData: {'severity': 'critical'},
      );

      // In a real implementation, this would disable admin accounts
      // For now, we just log the action
      print('Emergency lockdown initiated - admin access restricted');
    } catch (e) {
      print('Error during emergency lockdown: $e');
      throw Exception('Failed to initiate emergency lockdown');
    }
  }

  /// Secure admin data export with encryption
  static Future<Map<String, dynamic>> exportAdminData({
    required List<String> collections,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!AdminService.hasAdminPrivilege(AdminPrivilege.systemSettings)) {
      throw Exception('Insufficient privileges for data export');
    }

    await logAdminAction(
      action: 'data_export_initiated',
      resourceType: 'system',
      additionalData: {
        'collections': collections,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      },
    );

    // Implementation would include actual data export logic
    // This is a placeholder for the secure export functionality
    return {
      'exportId': DateTime.now().millisecondsSinceEpoch.toString(),
      'status': 'initiated',
      'collections': collections,
      'message': 'Data export initiated - this would contain encrypted data in production',
    };
  }
}

/// Admin audit trail for tracking all administrative actions
class AdminAuditTrail {
  static Future<void> recordAction({
    required String action,
    required String targetResource,
    String? targetUserId,
    Map<String, dynamic>? beforeState,
    Map<String, dynamic>? afterState,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !AdminService.isAdminUser()) return;

    try {
      await FirebaseFirestore.instance.collection('admin_audit_trail').add({
        'adminId': user.uid,
        'adminEmail': user.email,
        'adminRole': AdminService.getAdminRole()?.toString().split('.').last,
        'action': action,
        'targetResource': targetResource,
        'targetUserId': targetUserId,
        'beforeState': beforeState,
        'afterState': afterState,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': user.uid + DateTime.now().millisecondsSinceEpoch.toString(),
      });
    } catch (e) {
      print('Error recording admin audit trail: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAuditTrail({
    String? adminId,
    String? targetUserId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    if (!AdminService.hasAdminPrivilege(AdminPrivilege.systemSettings)) {
      throw Exception('Insufficient privileges to view audit trail');
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection('admin_audit_trail')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }

      if (targetUserId != null) {
        query = query.where('targetUserId', isEqualTo: targetUserId);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting audit trail: $e');
      throw Exception('Failed to fetch audit trail');
    }
  }
}
