import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    if (!hasAdminPrivilege(AdminPrivilege.userManagement)) {
      throw Exception('Insufficient privileges for user management');
    }

    try {
      Query query = _firestore.collection('users').limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      throw Exception('Failed to fetch users');
    }
  }

  /// Get user statistics for admin dashboard
  Future<AdminDashboardStats> getDashboardStats() async {
    if (!hasAdminPrivilege(AdminPrivilege.analytics)) {
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

      return AdminDashboardStats(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        premiumUsers: premiumUsers,
        totalSessions: totalSessions,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error getting dashboard stats: $e');
      throw Exception('Failed to fetch dashboard statistics');
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
