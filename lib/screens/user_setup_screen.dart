import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../models/subscription_plan.dart';
import 'subscription_screen.dart';
import 'home_screen.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> 
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  
  // Form controllers
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  
  int _currentPage = 0;
  int _selectedAge = 5;
  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _parentNameController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (_childNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter child\'s name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.completeUserSetup(
        childName: _childNameController.text.trim(),
        childAge: _selectedAge,
        parentName: _parentNameController.text.trim().isEmpty 
            ? null 
            : _parentNameController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        // Navigate to subscription screen for premium options
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SubscriptionScreen(isInitialSetup: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error completing setup: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B73FF),
              Color(0xFF9B59B6),
              Color(0xFFE74C3C),
              Color(0xFFF39C12),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header with progress indicator
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (_currentPage > 0)
                            IconButton(
                              onPressed: _previousPage,
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          const Spacer(),
                          Text(
                            'Setup Profile',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          if (_currentPage > 0) const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress indicator
                      Row(
                        children: List.generate(3, (index) {
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                right: index < 2 ? 8 : 0,
                              ),
                              height: 4,
                              decoration: BoxDecoration(
                                color: index <= _currentPage 
                                    ? Colors.white 
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        _buildWelcomePage(),
                        _buildChildDetailsPage(),
                        _buildAccountTypePage(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Welcome illustration
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(75),
            ),
            child: const Icon(
              Icons.family_restroom,
              size: 80,
              color: Color(0xFF6B73FF),
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Let\'s Get Started!',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  color: const Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'We need a few details to personalize your child\'s learning experience and create the perfect educational journey.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  color: const Color(0xFF7F8C8D),
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B73FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildDetailsPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          Text(
            'Tell us about your child',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  color: const Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'This helps us customize the learning experience',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: const Color(0xFF7F8C8D),
                ),
          ),
          const SizedBox(height: 32),
          
          // Child's name
          Text(
            'Child\'s Name *',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  color: const Color(0xFF2C3E50),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _childNameController,
            decoration: InputDecoration(
              hintText: 'Enter child\'s name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Child's age
          Text(
            'Child\'s Age',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  color: const Color(0xFF2C3E50),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _selectedAge.toDouble(),
                    min: 3,
                    max: 12,
                    divisions: 9,
                    label: '$_selectedAge years old',
                    onChanged: (value) {
                      setState(() {
                        _selectedAge = value.round();
                      });
                    },
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B73FF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      '$_selectedAge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _childNameController.text.trim().isEmpty 
                  ? null 
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B73FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          Text(
            'Account Type',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  color: const Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Who will be using this account?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: const Color(0xFF7F8C8D),
                ),
          ),
          const SizedBox(height: 32),
          
          // Account type selection
          Column(
            children: [
              _buildRoleOption(
                role: UserRole.student,
                title: 'Student Account',
                description: 'Child will use the app independently',
                icon: Icons.child_care,
              ),
              const SizedBox(height: 16),
              _buildRoleOption(
                role: UserRole.parent,
                title: 'Parent Account',
                description: 'Parent managing child\'s learning',
                icon: Icons.person,
              ),
            ],
          ),
          
          // Parent name (only if parent role selected)
          if (_selectedRole == UserRole.parent) ...[
            const SizedBox(height: 24),
            Text(
              'Parent\'s Name (Optional)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: const Color(0xFF2C3E50),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _parentNameController,
              decoration: InputDecoration(
                hintText: 'Enter parent\'s name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ],
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _completeSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B73FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Complete Setup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF6B73FF).withOpacity(0.1)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF6B73FF)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF6B73FF)
                    : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: const Color(0xFF2C3E50),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: const Color(0xFF7F8C8D),
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF6B73FF),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
