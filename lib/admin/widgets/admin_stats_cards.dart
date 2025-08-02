import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminStatsCards extends StatelessWidget {
  final AdminDashboardStats stats;

  const AdminStatsCards({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isTablet 
            ? (constraints.maxWidth - 48) / 4 
            : (constraints.maxWidth - 16) / 2;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              title: 'Total Users',
              value: stats.totalUsers.toString(),
              icon: Icons.people,
              color: const Color(0xFF10B981),
              trend: '+12%',
              trendPositive: true,
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Active Users',
              value: stats.activeUsers.toString(),
              icon: Icons.person_outline,
              color: const Color(0xFF3B82F6),
              trend: '+5%',
              trendPositive: true,
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Premium Users',
              value: stats.premiumUsers.toString(),
              icon: Icons.star,
              color: const Color(0xFFF59E0B),
              trend: '+18%',
              trendPositive: true,
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Game Sessions',
              value: _formatNumber(stats.totalSessions),
              icon: Icons.gamepad,
              color: const Color(0xFF8B5CF6),
              trend: '+23%',
              trendPositive: true,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendPositive,
    required double width,
  }) {
    return Container(
      width: width,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendPositive 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: trendPositive ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        color: trendPositive ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}
