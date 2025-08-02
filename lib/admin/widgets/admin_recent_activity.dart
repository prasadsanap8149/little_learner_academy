import 'package:flutter/material.dart';

class AdminRecentActivity extends StatelessWidget {
  const AdminRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample recent activities - in real app, fetch from database
    final activities = [
      {
        'type': 'user_signup',
        'message': 'New user registered: Emily Johnson',
        'time': '5 minutes ago',
        'icon': Icons.person_add,
        'color': const Color(0xFF10B981),
      },
      {
        'type': 'game_completed',
        'message': 'Math Counting Game completed by Alex',
        'time': '12 minutes ago',
        'icon': Icons.gamepad,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'type': 'subscription',
        'message': 'Premium subscription purchased',
        'time': '28 minutes ago',
        'icon': Icons.star,
        'color': const Color(0xFFF59E0B),
      },
      {
        'type': 'content_update',
        'message': 'Animal Science Game updated',
        'time': '1 hour ago',
        'icon': Icons.edit,
        'color': const Color(0xFF3B82F6),
      },
      {
        'type': 'support_ticket',
        'message': 'Support ticket resolved #1234',
        'time': '2 hours ago',
        'icon': Icons.support_agent,
        'color': const Color(0xFF6B7280),
      },
    ];

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
          Row(
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to full activity log
                  print('Navigate to Activity Log');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityItem(
                activity['message'] as String,
                activity['time'] as String,
                activity['icon'] as IconData,
                activity['color'] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String message,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {
              // Show activity options
            },
          ),
        ],
      ),
    );
  }
}
