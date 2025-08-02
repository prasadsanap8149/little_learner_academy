import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/admin_service.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_stats_cards.dart';
import '../widgets/admin_quick_actions.dart';
import '../widgets/admin_recent_activity.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  AdminUserInfo? _adminInfo;
  AdminDashboardStats? _dashboardStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAdminData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _fadeController.forward();
  }

  Future<void> _loadAdminData() async {
    try {
      final adminInfo = await _adminService.getAdminUserInfo();
      await _adminService.updateLastLogin();
      
      final stats = await _adminService.getDashboardStats();
      
      setState(() {
        _adminInfo = adminInfo;
        _dashboardStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading admin data: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Admin Dashboard',
        adminInfo: _adminInfo,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadAdminData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Header
                          _buildWelcomeHeader(user),
                          const SizedBox(height: 24),
                          
                          // Statistics Cards
                          if (_dashboardStats != null)
                            AdminStatsCards(stats: _dashboardStats!),
                          const SizedBox(height: 24),
                          
                          // Quick Actions
                          AdminQuickActions(adminRole: _adminInfo?.role),
                          const SizedBox(height: 24),
                          
                          // Recent Activity
                          const AdminRecentActivity(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B73FF), Color(0xFF9A8EFF)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${_adminInfo?.name ?? user?.displayName ?? 'Admin'}!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminInfo?.roleDisplayName ?? 'Administrator',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last login: ${_formatLastLogin(_adminInfo?.lastLoginAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastLogin(DateTime? lastLogin) {
    if (lastLogin == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastLogin.day}/${lastLogin.month}/${lastLogin.year}';
    }
  }
}
