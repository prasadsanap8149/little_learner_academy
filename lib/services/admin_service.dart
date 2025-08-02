import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_security_utils.dart';

enum AdminRole {
  superAdmin,    // Full access to everything
  contentManager, // Game and content management
  support        // User support and basic analytics
}

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin email addresses with their roles
  static const Map<String, AdminRole> adminEmails = {
    'admin@littlelearnersacademy.com': AdminRole.superAdmin,
    'prasad@littlelearnersacademy.com': AdminRole.superAdmin,
    'content@littlelearnersacademy.com': AdminRole.contentManager,
    'support@littlelearnersacademy.com': AdminRole.support,
    // Add more admin emails as needed
  };

  /// Check if the current user is an admin
  static bool isAdminUser([String? email]) {
    final userEmail = email ?? FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return false;
    return adminEmails.containsKey(userEmail.toLowerCase());
  }

  /// Get the admin role for the current user
  static AdminRole? getAdminRole([String? email]) {
    final userEmail = email ?? FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return null;
    return adminEmails[userEmail.toLowerCase()];
  }

  /// Check if the current user has a specific admin privilege
  static bool hasAdminPrivilege(AdminPrivilege privilege, [String? email]) {
    final role = getAdminRole(email);
    if (role == null) return false;

    switch (privilege) {
      case AdminPrivilege.userManagement:
        return role == AdminRole.superAdmin || role == AdminRole.support;
      case AdminPrivilege.contentManagement:
        return role == AdminRole.superAdmin || role == AdminRole.contentManager;
      case AdminPrivilege.gameManagement:
        return role == AdminRole.superAdmin || role == AdminRole.contentManager;
      case AdminPrivilege.analytics:
        return true; // All admin roles can view analytics
      case AdminPrivilege.systemSettings:
        return role == AdminRole.superAdmin;
      case AdminPrivilege.subscriptionManagement:
        return role == AdminRole.superAdmin || role == AdminRole.support;
    }
  }

  /// Check if the current user is a super admin
  static bool isSuperAdmin([String? email]) {
    final role = getAdminRole(email);
    return role == AdminRole.superAdmin;
  }

  /// Get admin user info
  Future<AdminUserInfo?> getAdminUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !isAdminUser()) return null;

    try {
      final doc = await _firestore.collection('admin_users').doc(user.uid).get();
      if (doc.exists) {
        return AdminUserInfo.fromFirestore(doc);
      } else {
        // Create admin user document if it doesn't exist
        final adminInfo = AdminUserInfo(
          uid: user.uid,
          email: user.email!,
          name: user.displayName ?? 'Admin User',
          role: getAdminRole()!,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await _firestore.collection('admin_users').doc(user.uid).set(adminInfo.toFirestore());
        return adminInfo;
      }
    } catch (e) {
      print('Error getting admin user info: $e');
      return null;
    }
  }

  /// Update admin user's last login time
  Future<void> updateLastLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !isAdminUser()) return;

    try {
      await _firestore.collection('admin_users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  /// Get all users for admin management
  Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    // Enhanced security check with logging
    if (!await AdminSecurityUtils.checkPrivilegeWithRateLimit(
      AdminPrivilege.userManagement,
      'get_all_users',
      'users',
    )) {
      throw Exception('Insufficient privileges for user management');
    }

    try {
      Query query = _firestore.collection('users').limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final users = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();

      // Log the admin action
      await AdminSecurityUtils.logAdminAction(
        action: 'get_all_users',
        resourceType: 'users',
        additionalData: {'count': users.length, 'limit': limit},
      );

      return users;
    } catch (e) {
      await AdminSecurityUtils.logAdminAction(
        action: 'get_all_users_failed',
        resourceType: 'users',
        additionalData: {'error': e.toString()},
      );
      print('Error getting all users: $e');
      throw Exception('Failed to fetch users');
    }
  }

  /// Get user statistics for admin dashboard
  Future<AdminDashboardStats> getDashboardStats() async {
    // Enhanced security check with logging
    if (!await AdminSecurityUtils.checkPrivilegeWithRateLimit(
      AdminPrivilege.analytics,
      'get_dashboard_stats',
      'analytics',
    )) {
      throw Exception('Insufficient privileges for analytics');
    }

    try {
      // Get user count
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.size;

      // Get active users (logged in within last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('lastLoginAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();
      final activeUsers = activeUsersSnapshot.size;

      // Get premium subscribers
      final premiumSnapshot = await _firestore
          .collection('users')
          .where('subscriptionStatus', isEqualTo: 'active')
          .get();
      final premiumUsers = premiumSnapshot.size;

      // Get game sessions count
      final sessionsSnapshot = await _firestore.collection('game_sessions').get();
      final totalSessions = sessionsSnapshot.size;

      final stats = AdminDashboardStats(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        premiumUsers: premiumUsers,
        totalSessions: totalSessions,
        lastUpdated: DateTime.now(),
      );

      // Log the admin action
      await AdminSecurityUtils.logAdminAction(
        action: 'get_dashboard_stats',
        resourceType: 'analytics',
        additionalData: {
          'totalUsers': totalUsers,
          'activeUsers': activeUsers,
          'premiumUsers': premiumUsers,
          'totalSessions': totalSessions,
        },
      );

      return stats;
    } catch (e) {
      await AdminSecurityUtils.logAdminAction(
        action: 'get_dashboard_stats_failed',
        resourceType: 'analytics',
        additionalData: {'error': e.toString()},
      );
      print('Error getting dashboard stats: $e');
      throw Exception('Failed to fetch dashboard statistics');
    }
  }
  
  /// Update user data (admin only)
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    if (!await AdminSecurityUtils.checkPrivilegeWithRateLimit(
      AdminPrivilege.userManagement,
      'update_user_data',
      'users',
      userId,
    )) {
      throw Exception('Insufficient privileges for user management');
    }

    try {
      // Get current data for audit trail
      final currentDoc = await _firestore.collection('users').doc(userId).get();
      final beforeState = currentDoc.exists ? currentDoc.data() : null;

      await _firestore.collection('users').doc(userId).update(data);

      // Record audit trail
      await AdminAuditTrail.recordAction(
        action: 'update_user_data',
        targetResource: 'users',
        targetUserId: userId,
        beforeState: beforeState,
        afterState: data,
      );

      await AdminSecurityUtils.logAdminAction(
        action: 'update_user_data',
        resourceType: 'users',
        resourceId: userId,
        additionalData: {'updatedFields': data.keys.toList()},
      );
    } catch (e) {
      await AdminSecurityUtils.logAdminAction(
        action: 'update_user_data_failed',
        resourceType: 'users',
        resourceId: userId,
        additionalData: {'error': e.toString()},
      );
      throw Exception('Failed to update user data');
    }
  }

  /// Delete user account (super admin only)
  Future<void> deleteUser(String userId, String reason) async {
    if (!isSuperAdmin()) {
      throw Exception('Only super admin can delete user accounts');
    }

    if (!await AdminSecurityUtils.checkPrivilegeWithRateLimit(
      AdminPrivilege.userManagement,
      'delete_user',
      'users',
      userId,
    )) {
      throw Exception('Rate limit exceeded for user deletion');
    }

    try {
      // Get user data before deletion for audit
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.exists ? userDoc.data() : null;

      // Delete user data
      await _firestore.collection('users').doc(userId).delete();

      // Record audit trail
      await AdminAuditTrail.recordAction(
        action: 'delete_user',
        targetResource: 'users',
        targetUserId: userId,
        beforeState: userData,
        reason: reason,
      );

      await AdminSecurityUtils.logAdminAction(
        action: 'delete_user',
        resourceType: 'users',
        resourceId: userId,
        additionalData: {'reason': reason},
      );
    } catch (e) {
      await AdminSecurityUtils.logAdminAction(
        action: 'delete_user_failed',
        resourceType: 'users',
        resourceId: userId,
        additionalData: {'error': e.toString(), 'reason': reason},
      );
      throw Exception('Failed to delete user');
    }
  }

  /// Get security logs (super admin only)
  Future<List<Map<String, dynamic>>> getSecurityLogs({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    if (!isSuperAdmin()) {
      throw Exception('Only super admin can view security logs');
    }

    return await AdminSecurityUtils.getSecurityLogs(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Get audit trail (super admin only)
  Future<List<Map<String, dynamic>>> getAuditTrail({
    String? targetUserId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    if (!isSuperAdmin()) {
      throw Exception('Only super admin can view audit trail');
    }

    return await AdminAuditTrail.getAuditTrail(
      targetUserId: targetUserId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Update user role (Super Admin only)
  Future<bool> updateUserRole(String userId, String newRole) async {
    if (!await AdminSecurityUtils.checkPrivilegeWithRateLimit(
      AdminPrivilege.userManagement,
      'update_user_role',
      'users',
    )) {
      throw Exception('Insufficient privileges to update user roles');
    }

    if (!isSuperAdmin()) {
      throw Exception('Only super admins can modify user roles');
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log the admin action
      await AdminSecurityUtils.logAdminAction(
        action: 'update_user_role',
        resourceType: 'users',
        resourceId: userId,
        additionalData: {'newRole': newRole},
      );

      return true;
    } catch (e) {
      print('Error updating user role: $e');
      await AdminSecurityUtils.logAdminAction(
        action: 'update_user_role_failed',
        resourceType: 'users',
        resourceId: userId,
        additionalData: {'error': e.toString(), 'newRole': newRole},
      );
      return false;
    }
  }

  /// Get user role from Firebase
  static Future<String?> getUserRoleFromFirebase([String? userId]) async {
    try {
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role from Firebase: $e');
      return null;
    }
  }

  /// Check if user has specific role (checks both hardcoded and Firebase)
  static Future<bool> hasRole(String role, [String? userId]) async {
    // First check hardcoded admin emails for backward compatibility
    if (isAdminUser()) {
      final adminRole = getAdminRole();
      if (adminRole != null) {
        switch (role.toLowerCase()) {
          case 'superadmin':
          case 'super_admin':
            return adminRole == AdminRole.superAdmin;
          case 'contentmanager':
          case 'content_manager':
            return adminRole == AdminRole.contentManager;
          case 'support':
            return adminRole == AdminRole.support;
          case 'admin':
            return true; // Any admin role
        }
      }
    }

    // Then check Firebase role
    final firebaseRole = await getUserRoleFromFirebase(userId);
    return firebaseRole?.toLowerCase() == role.toLowerCase();
  }

  /// Get comprehensive user role (combines hardcoded and Firebase)
  static Future<String> getComprehensiveUserRole([String? userId]) async {
    // Check hardcoded admin roles first
    final adminRole = getAdminRole();
    if (adminRole != null) {
      switch (adminRole) {
        case AdminRole.superAdmin:
          return 'super_admin';
        case AdminRole.contentManager:
          return 'content_manager';
        case AdminRole.support:
          return 'support';
      }
    }

    // Check Firebase role
    final firebaseRole = await getUserRoleFromFirebase(userId);
    if (firebaseRole != null) {
      return firebaseRole;
    }

    // Default role
    return 'user';
  }

  /// Switch user to different role (for testing/demo purposes - Super Admin only)
  static Future<bool> switchUserRole(BuildContext context, String targetRole) async {
    if (!isSuperAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only super admins can switch roles'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Update role in Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'role': targetRole,
        'email': user.email,
        'displayName': user.displayName,
        'lastRoleSwitch': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log the action
      await AdminSecurityUtils.logAdminAction(
        action: 'role_switch',
        resourceType: 'users',
        resourceId: user.uid,
        additionalData: {'targetRole': targetRole},
      );

      // Navigate based on new role
      await _navigateBasedOnRole(context, targetRole);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to $targetRole mode'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Navigate based on user role
  static Future<void> _navigateBasedOnRole(BuildContext context, String role) async {
    switch (role.toLowerCase()) {
      case 'super_admin':
      case 'content_manager':
      case 'support':
      case 'admin':
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
        break;
      case 'user':
      default:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
    }
  }

  /// Create or update user profile with role
  Future<bool> createUserWithRole({
    required String email,
    required String name,
    required String role,
    String? userId,
  }) async {
    if (!await AdminSecurityUtils.checkPrivilegeWithRateLimit(
      AdminPrivilege.userManagement,
      'create_user_with_role',
      'users',
    )) {
      throw Exception('Insufficient privileges to create users');
    }

    try {
      final docId = userId ?? email.replaceAll('@', '_').replaceAll('.', '_');
      
      await _firestore.collection('users').doc(docId).set({
        'email': email,
        'displayName': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));

      // Log the admin action
      await AdminSecurityUtils.logAdminAction(
        action: 'create_user_with_role',
        resourceType: 'users',
        resourceId: docId,
        additionalData: {'email': email, 'role': role, 'name': name},
      );

      return true;
    } catch (e) {
      print('Error creating user with role: $e');
      return false;
    }
  }
}

enum AdminPrivilege {
  userManagement,
  contentManagement,
  gameManagement,
  analytics,
  systemSettings,
  subscriptionManagement,
}

class AdminUserInfo {
  final String uid;
  final String email;
  final String name;
  final AdminRole role;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  AdminUserInfo({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory AdminUserInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUserInfo(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: AdminRole.values.firstWhere(
        (role) => role.toString().split('.').last == data['role'],
        orElse: () => AdminRole.support,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  String get roleDisplayName {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.contentManager:
        return 'Content Manager';
      case AdminRole.support:
        return 'Support';
    }
  }
}

class AdminDashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int premiumUsers;
  final int totalSessions;
  final DateTime lastUpdated;

  AdminDashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.premiumUsers,
    required this.totalSessions,
    required this.lastUpdated,
  });
}
