import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/splash_screen.dart';
import '../admin/screens/admin_dashboard_screen.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Get the appropriate home screen based on user type
  static Widget getHomeScreen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }
    
    if (AdminService.isAdminUser()) {
      return const AdminDashboardScreen();
    }
    
    return const HomeScreen();
  }

  // Navigate to appropriate dashboard
  static void navigateToUserDashboard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    
    if (AdminService.isAdminUser()) {
      Navigator.of(context).pushReplacementNamed('/admin-dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  // Switch between admin and user mode (for super admins)
  static void switchUserMode(BuildContext context, {bool forceUserMode = false}) {
    if (AdminService.isSuperAdmin() || forceUserMode) {
      if (forceUserMode) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      }
    }
  }

  // Show user mode switcher dialog for super admins
  static void showUserModeSwitcher(BuildContext context) {
    if (!AdminService.isSuperAdmin()) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Switch Mode'),
          content: const Text('Choose your preferred mode:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('User Mode'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/admin-dashboard');
              },
              child: const Text('Admin Mode'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Custom app bar for different user types
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    bool showUserSwitcher = false,
  }) {
    final isAdmin = AdminService.isAdminUser();
    final isSuperAdmin = AdminService.isSuperAdmin();
    
    return AppBar(
      title: Text(title),
      backgroundColor: isAdmin ? const Color(0xFF2E3B4E) : const Color(0xFF6B73FF),
      foregroundColor: Colors.white,
      actions: [
        if (showUserSwitcher && isSuperAdmin)
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'user_mode':
                  Navigator.of(context).pushReplacementNamed('/home');
                  break;
                case 'admin_mode':
                  Navigator.of(context).pushReplacementNamed('/admin-dashboard');
                  break;
                case 'switch_dialog':
                  showUserModeSwitcher(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'user_mode',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('User Mode'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'admin_mode',
                child: ListTile(
                  leading: Icon(Icons.admin_panel_settings),
                  title: Text('Admin Mode'),
                ),
              ),
            ],
            icon: const Icon(Icons.swap_horiz),
          ),
        ...?actions,
      ],
    );
  }

  // Get routes for the app
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) => const SplashScreen(),
      '/login': (context) => const LoginScreen(),
      '/home': (context) => const HomeScreen(),
      '/admin-dashboard': (context) => const AdminDashboardScreen(),
    };
  }

  // Navigate with admin privilege check
  static Future<void> navigateWithPrivilegeCheck({
    required BuildContext context,
    required AdminPrivilege requiredPrivilege,
    required String route,
    Object? arguments,
  }) async {
    if (AdminService.hasAdminPrivilege(requiredPrivilege)) {
      Navigator.of(context).pushNamed(route, arguments: arguments);
    } else {
      showAccessDeniedDialog(context);
    }
  }

  // Show access denied dialog
  static void showAccessDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Access Denied'),
          content: const Text('You don\'t have permission to access this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Drawer widget that adapts based on user type
class AdaptiveDrawer extends StatelessWidget {
  const AdaptiveDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = AdminService.isAdminUser();
    final isSuperAdmin = AdminService.isSuperAdmin();
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: isAdmin ? const Color(0xFF2E3B4E) : const Color(0xFF6B73FF),
              ),
            ),
            decoration: BoxDecoration(
              color: isAdmin ? const Color(0xFF2E3B4E) : const Color(0xFF6B73FF),
            ),
          ),
          
          if (!isAdmin) ...[
            // Regular user menu items
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.games),
              title: const Text('Games'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to games section
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Achievements'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to achievements
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to settings
              },
            ),
          ],
          
          if (isAdmin) ...[
            // Admin menu items
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/admin-dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to user management
              },
            ),
            ListTile(
              leading: const Icon(Icons.games),
              title: const Text('Game Management'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to game management
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to analytics
              },
            ),
          ],
          
          if (isSuperAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Switch Mode'),
              onTap: () {
                Navigator.of(context).pop();
                NavigationService.showUserModeSwitcher(context);
              },
            ),
          ],
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
