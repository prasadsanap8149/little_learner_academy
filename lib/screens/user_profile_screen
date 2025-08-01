import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../models/age_group.dart';
import '../services/game_provider.dart';
import '../services/sound_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  final SoundService _soundService = SoundService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  
  late AnimationController _profileAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _profileScaleAnimation;
  late Animation<Offset> _cardSlideAnimation;
  
  UserProfile? _userProfile;
  AgeGroup? _selectedAgeGroup;
  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserProfile();
  }

  void _initializeAnimations() {
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _profileScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _profileAnimationController,
      curve: Curves.elasticOut,
    ));

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));

    _profileAnimationController.forward();
    _cardAnimationController.forward();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userProfile = UserProfile.fromFirestore(doc);
            _nameController.text = _userProfile!.name;
            _isLoading = false;
          });
          
          // Load age group from game provider
          final gameProvider = Provider.of<GameProvider>(context, listen: false);
          setState(() {
            _selectedAgeGroup = gameProvider.selectedAgeGroup;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Update age group if changed
        if (_selectedAgeGroup != null) {
          final gameProvider = Provider.of<GameProvider>(context, listen: false);
          gameProvider.setAgeGroup(_selectedAgeGroup!);
        }
        
        setState(() => _isEditing = false);
        _soundService.playSuccess();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadUserProfile(); // Reload to show updated data
      } catch (e) {
        _soundService.playError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6B73FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _soundService.playClick();
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B73FF), Color(0xFF9A8EFF)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 32 : 16),
                  child: Column(
                    children: [
                      // Profile Header
                      ScaleTransition(
                        scale: _profileScaleAnimation,
                        child: _buildProfileHeader(),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Profile Information Cards
                      SlideTransition(
                        position: _cardSlideAnimation,
                        child: Column(
                          children: [
                            _buildPersonalInfoCard(),
                            const SizedBox(height: 20),
                            _buildLearningPreferencesCard(),
                            const SizedBox(height: 20),
                            _buildAccountInfoCard(),
                            const SizedBox(height: 20),
                            if (_isEditing) _buildActionButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B73FF), Color(0xFF9A8EFF)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B73FF).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            _userProfile?.name ?? 'Loading...',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6B73FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleDisplayName(_userProfile?.role),
              style: const TextStyle(
                color: Color(0xFF6B73FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return _buildInfoCard(
      title: '👤 Personal Information',
      children: [
        _buildEditableField(
          label: 'Name',
          value: _userProfile?.name ?? '',
          controller: _nameController,
          icon: Icons.person,
          enabled: _isEditing,
        ),
        const SizedBox(height: 16),
        _buildInfoField(
          label: 'Email',
          value: _userProfile?.email ?? '',
          icon: Icons.email,
        ),
      ],
    );
  }

  Widget _buildLearningPreferencesCard() {
    return _buildInfoCard(
      title: '🎓 Learning Preferences',
      children: [
        _buildAgeGroupSelector(),
        const SizedBox(height: 16),
        _buildInfoField(
          label: 'Account Type',
          value: _getAccountTypeDisplayName(_userProfile?.accountType),
          icon: Icons.card_membership,
        ),
      ],
    );
  }

  Widget _buildAccountInfoCard() {
    return _buildInfoCard(
      title: '📊 Account Statistics',
      children: [
        _buildInfoField(
          label: 'Member Since',
          value: _formatDate(_userProfile?.createdAt),
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? const Color(0xFF6B73FF) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF6B73FF)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              hintText: enabled ? 'Enter $label' : null,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6B73FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6B73FF), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgeGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age Group',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _isEditing ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing ? const Color(0xFF6B73FF) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: DropdownButtonFormField<AgeGroup>(
            value: _selectedAgeGroup,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.child_care, color: Color(0xFF6B73FF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            items: AgeGroup.values.map((group) {
              return DropdownMenuItem(
                value: group,
                child: Text(
                  _getAgeGroupDisplayName(group),
                  style: const TextStyle(color: Color(0xFF2D3748)),
                ),
              );
            }).toList(),
            onChanged: _isEditing
                ? (AgeGroup? value) {
                    if (value != null) {
                      setState(() => _selectedAgeGroup = value);
                      _soundService.playClick();
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final progress = gameProvider.playerProgress;
        final totalGames = gameProvider.allGameLevels.length;
        final completedGames = progress.completedLevels.length;
        final progressPercentage = totalGames > 0 ? completedGames / totalGames : 0.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning Progress',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${(progressPercentage * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B73FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '$completedGames of $totalGames games completed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _soundService.playClick();
              setState(() => _isEditing = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B73FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(UserRole? role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.schoolAdmin:
        return 'School Admin';
      case UserRole.teacher:
        return 'Teacher';
      default:
        return 'Student';
    }
  }

  String _getAccountTypeDisplayName(AccountType? accountType) {
    switch (accountType) {
      case AccountType.free:
        return 'Free Account';
      case AccountType.premiumIndividual:
        return 'Premium Individual';
      case AccountType.schoolMember:
        return 'School Member';
      default:
        return 'Free Account';
    }
  }

  String _getAgeGroupDisplayName(AgeGroup group) {
    switch (group) {
      case AgeGroup.littleTots:
        return 'Little Tots (3-5 years)';
      case AgeGroup.smartKids:
        return 'Smart Kids (6-8 years)';
      case AgeGroup.youngScholars:
        return 'Young Scholars (9-12 years)';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _profileAnimationController.dispose();
    _cardAnimationController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
