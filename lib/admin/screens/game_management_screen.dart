import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/game.dart';
import '../../models/age_group.dart';
import '../widgets/admin_app_bar.dart';

class GameManagementScreen extends StatefulWidget {
  const GameManagementScreen({super.key});

  @override
  State<GameManagementScreen> createState() => _GameManagementScreenState();
}

class _GameManagementScreenState extends State<GameManagementScreen> {
  final AdminService _adminService = AdminService();
  final List<String> _subjects = ['Math', 'Language', 'Science', 'General Knowledge'];
  final List<AgeGroup> _ageGroups = AgeGroup.values;

  String _selectedSubject = 'Math';
  AgeGroup _selectedAgeGroup = AgeGroup.littleTots;
  bool _isLoading = false;

  // Sample game data - in real app, fetch from database
  List<Map<String, dynamic>> _games = [
    {
      'id': 'math_counting_1',
      'title': 'Math Counting Game',
      'subject': 'Math',
      'ageGroup': AgeGroup.littleTots,
      'isActive': true,
      'totalLevels': 10,
      'difficulty': 'Easy',
      'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      'lastUpdated': DateTime.now().subtract(const Duration(days: 5)),
      'playCount': 1250,
    },
    {
      'id': 'alphabet_matching_1',
      'title': 'Alphabet Matching Game',
      'subject': 'Language',
      'ageGroup': AgeGroup.littleTots,
      'isActive': true,
      'totalLevels': 8,
      'difficulty': 'Easy',
      'createdAt': DateTime.now().subtract(const Duration(days: 25)),
      'lastUpdated': DateTime.now().subtract(const Duration(days: 2)),
      'playCount': 890,
    },
    {
      'id': 'animal_science_1',
      'title': 'Animal Science Game',
      'subject': 'Science',
      'ageGroup': AgeGroup.smartKids,
      'isActive': true,
      'totalLevels': 12,
      'difficulty': 'Medium',
      'createdAt': DateTime.now().subtract(const Duration(days: 20)),
      'lastUpdated': DateTime.now().subtract(const Duration(days: 1)),
      'playCount': 654,
    },
    {
      'id': 'color_matching_1',
      'title': 'Color Matching Game',
      'subject': 'General Knowledge',
      'ageGroup': AgeGroup.littleTots,
      'isActive': false,
      'totalLevels': 6,
      'difficulty': 'Easy',
      'createdAt': DateTime.now().subtract(const Duration(days: 15)),
      'lastUpdated': DateTime.now().subtract(const Duration(days: 10)),
      'playCount': 423,
    },
  ];

  List<Map<String, dynamic>> get _filteredGames {
    return _games.where((game) {
      final matchesSubject = _selectedSubject == 'All' || game['subject'] == _selectedSubject;
      final matchesAgeGroup = game['ageGroup'] == _selectedAgeGroup;
      return matchesSubject && matchesAgeGroup;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Game Management'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Filters and controls
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Subject',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedSubject,
                                onChanged: (value) {
                                  setState(() => _selectedSubject = value!);
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: ['All', ..._subjects].map((subject) {
                                  return DropdownMenuItem(
                                    value: subject,
                                    child: Text(subject),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Age Group',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<AgeGroup>(
                                value: _selectedAgeGroup,
                                onChanged: (value) {
                                  setState(() => _selectedAgeGroup = value!);
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: _ageGroups.map((ageGroup) {
                                  return DropdownMenuItem(
                                    value: ageGroup,
                                    child: Text(_getAgeGroupDisplayName(ageGroup)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCreateGameDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Game'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              // Refresh games
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Games list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _filteredGames.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.gamepad_outlined,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No games found for the selected filters',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredGames.length,
                            itemBuilder: (context, index) {
                              final game = _filteredGames[index];
                              return _buildGameCard(game);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    final isActive = game['isActive'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.red,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSubjectColor(game['subject']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getSubjectIcon(game['subject']),
                    color: _getSubjectColor(game['subject']),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            game['subject'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleGameAction(value, game),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Game'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'levels',
                      child: Row(
                        children: [
                          Icon(Icons.layers, size: 16),
                          SizedBox(width: 8),
                          Text('Manage Levels'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.pause : Icons.play_arrow,
                            size: 16,
                            color: isActive ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive ? 'Deactivate' : 'Activate',
                            style: TextStyle(
                              color: isActive ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'analytics',
                      child: Row(
                        children: [
                          Icon(Icons.analytics, size: 16),
                          SizedBox(width: 8),
                          Text('View Analytics'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.layers,
                  '${game['totalLevels']} Levels',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.difficulty,
                  game['difficulty'],
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.play_arrow,
                  '${game['playCount']} plays',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_formatDate(game['lastUpdated'] as DateTime)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getAgeGroupDisplayName(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.littleTots:
        return 'Little Tots (3-5)';
      case AgeGroup.smartKids:
        return 'Smart Kids (6-8)';
      case AgeGroup.youngScholars:
        return 'Young Scholars (9-12)';
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Math':
        return const Color(0xFF3B82F6);
      case 'Language':
        return const Color(0xFF10B981);
      case 'Science':
        return const Color(0xFF8B5CF6);
      case 'General Knowledge':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Math':
        return Icons.calculate;
      case 'Language':
        return Icons.abc;
      case 'Science':
        return Icons.science;
      case 'General Knowledge':
        return Icons.public;
      default:
        return Icons.gamepad;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleGameAction(String action, Map<String, dynamic> game) {
    switch (action) {
      case 'edit':
        _showEditGameDialog(game);
        break;
      case 'levels':
        _showManageLevelsDialog(game);
        break;
      case 'activate':
      case 'deactivate':
        _toggleGameStatus(game);
        break;
      case 'analytics':
        _showGameAnalytics(game);
        break;
      case 'delete':
        _showDeleteGameDialog(game);
        break;
    }
  }

  void _showCreateGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Game'),
        content: const Text('Game creation wizard coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditGameDialog(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${game['title']}'),
        content: const Text('Game editing interface coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showManageLevelsDialog(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Levels - ${game['title']}'),
        content: const Text('Level management interface coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleGameStatus(Map<String, dynamic> game) {
    setState(() {
      game['isActive'] = !(game['isActive'] as bool);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${game['title']} ${game['isActive'] ? 'activated' : 'deactivated'}',
        ),
        backgroundColor: game['isActive'] ? Colors.green : Colors.orange,
      ),
    );
  }

  void _showGameAnalytics(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analytics - ${game['title']}'),
        content: const Text('Game analytics dashboard coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGameDialog(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game'),
        content: Text(
          'Are you sure you want to delete "${game['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _games.removeWhere((g) => g['id'] == game['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${game['title']} deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
