import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../screens/user_management_screen.dart';
import '../screens/game_management_screen.dart';

class AdminQuickActions extends StatelessWidget {
  final AdminRole? adminRole;

  const AdminQuickActions({
    super.key,
    this.adminRole,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _getActionsForRole(adminRole);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionCard(
                context,
                action['title']!,
                action['icon'] as IconData,
                action['color'] as Color,
                action['onTap'] as VoidCallback,
              );
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getActionsForRole(AdminRole? role) {
    final baseActions = <Map<String, dynamic>>[
      {
        'title': 'Analytics',
        'icon': Icons.analytics,
        'color': const Color(0xFF3B82F6),
        'onTap': () => print('Navigate to Analytics'),
      },
    ];

    if (role == AdminRole.superAdmin) {
      baseActions.addAll([
        {
          'title': 'User Management',
          'icon': Icons.people_alt,
          'color': const Color(0xFF10B981),
          'onTap': () => print('Navigate to User Management'),
        },
        {
          'title': 'Game Management',
          'icon': Icons.gamepad,
          'color': const Color(0xFF8B5CF6),
          'onTap': () => print('Navigate to Game Management'),
        },
        {
          'title': 'Content Editor',
          'icon': Icons.edit_note,
          'color': const Color(0xFFF59E0B),
          'onTap': () => print('Navigate to Content Editor'),
        },
        {
          'title': 'Subscriptions',
          'icon': Icons.payment,
          'color': const Color(0xFFEF4444),
          'onTap': () => print('Navigate to Subscriptions'),
        },
        {
          'title': 'System Settings',
          'icon': Icons.settings,
          'color': const Color(0xFF6B7280),
          'onTap': () => print('Navigate to System Settings'),
        },
      ]);
    } else if (role == AdminRole.contentManager) {
      baseActions.addAll([
        {
          'title': 'Game Management',
          'icon': Icons.gamepad,
          'color': const Color(0xFF8B5CF6),
          'onTap': () => print('Navigate to Game Management'),
        },
        {
          'title': 'Content Editor',
          'icon': Icons.edit_note,
          'color': const Color(0xFFF59E0B),
          'onTap': () => print('Navigate to Content Editor'),
        },
      ]);
    } else if (role == AdminRole.support) {
      baseActions.addAll([
        {
          'title': 'User Support',
          'icon': Icons.support_agent,
          'color': const Color(0xFF10B981),
          'onTap': () => print('Navigate to User Support'),
        },
        {
          'title': 'Subscriptions',
          'icon': Icons.payment,
          'color': const Color(0xFFEF4444),
          'onTap': () => print('Navigate to Subscriptions'),
        },
      ]);
    }

    return baseActions;
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        if (title == 'User Management') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const UserManagementScreen(),
            ),
          );
        } else if (title == 'Game Management') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GameManagementScreen(),
            ),
          );
        } else {
          onTap();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
