import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class UserRoleManagementWidget extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRoleUpdated;

  const UserRoleManagementWidget({
    super.key,
    required this.user,
    required this.onRoleUpdated,
  });

  @override
  State<UserRoleManagementWidget> createState() => _UserRoleManagementWidgetState();
}

class _UserRoleManagementWidgetState extends State<UserRoleManagementWidget> {
  final AdminService _adminService = AdminService();
  bool _isUpdating = false;
  
  final List<Map<String, String>> _availableRoles = [
    {'value': 'user', 'label': 'Regular User', 'icon': 'person'},
    {'value': 'support', 'label': 'Support Agent', 'icon': 'support_agent'},
    {'value': 'content_manager', 'label': 'Content Manager', 'icon': 'edit'},
    {'value': 'super_admin', 'label': 'Super Admin', 'icon': 'admin_panel_settings'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentRole = widget.user['role'] ?? 'user';
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(currentRole),
          child: Icon(
            _getRoleIcon(currentRole),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          widget.user['displayName'] ?? widget.user['email'] ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.user['email'] ?? ''),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(currentRole).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getRoleColor(currentRole)),
              ),
              child: Text(
                _getRoleLabel(currentRole),
                style: TextStyle(
                  color: _getRoleColor(currentRole),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        children: [
          if (AdminService.isSuperAdmin()) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change User Role:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableRoles.map((role) {
                      final isSelected = role['value'] == currentRole;
                      return FilterChip(
                        selected: isSelected,
                        onSelected: _isUpdating ? null : (selected) {
                          if (selected && role['value'] != currentRole) {
                            _updateUserRole(role['value']!);
                          }
                        },
                        avatar: Icon(
                          _getIconFromString(role['icon']!),
                          size: 16,
                          color: isSelected ? Colors.white : _getRoleColor(role['value']!),
                        ),
                        label: Text(role['label']!),
                        backgroundColor: isSelected ? _getRoleColor(role['value']!) : null,
                        selectedColor: _getRoleColor(role['value']!),
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  if (_isUpdating) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Only super admins can modify user roles.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateUserRole(String newRole) async {
    setState(() => _isUpdating = true);

    try {
      final success = await _adminService.updateUserRole(
        widget.user['id'] ?? widget.user['uid'] ?? '',
        newRole,
      );

      if (success) {
        widget.onRoleUpdated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User role updated to ${_getRoleLabel(newRole)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update user role'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return const Color(0xFF1976D2); // Blue
      case 'content_manager':
        return const Color(0xFF388E3C); // Green
      case 'support':
        return const Color(0xFFFF9800); // Orange
      case 'user':
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'content_manager':
        return Icons.edit;
      case 'support':
        return Icons.support_agent;
      case 'user':
      default:
        return Icons.person;
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'support_agent':
        return Icons.support_agent;
      case 'edit':
        return Icons.edit;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return 'Super Admin';
      case 'content_manager':
        return 'Content Manager';
      case 'support':
        return 'Support Agent';
      case 'user':
      default:
        return 'Regular User';
    }
  }
}
