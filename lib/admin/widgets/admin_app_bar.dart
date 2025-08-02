import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AdminUserInfo? adminInfo;
  final List<Widget>? actions;

  const AdminAppBar({
    super.key,
    required this.title,
    this.adminInfo,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E3A8A),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Admin role indicator
        if (adminInfo != null)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(adminInfo!.role),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _getRoleShortName(adminInfo!.role),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        
        // Additional actions
        if (actions != null) ...actions!,
        
        // Admin menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'user_mode',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 20),
                  SizedBox(width: 8),
                  Text('Switch to User Mode'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getRoleIcon(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return Icons.admin_panel_settings;
      case AdminRole.contentManager:
        return Icons.edit;
      case AdminRole.support:
        return Icons.help;
    }
  }

  String _getRoleShortName(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Super';
      case AdminRole.contentManager:
        return 'Content';
      case AdminRole.support:
        return 'Support';
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        // Navigate to admin profile
        break;
      case 'settings':
        // Navigate to admin settings
        break;
      case 'user_mode':
        // Switch to user mode (go back to normal app)
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Perform logout
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
