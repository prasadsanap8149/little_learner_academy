import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'user_setup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        // Check if user setup is completed
        final userProfile = await _authService.getCurrentUserProfile();
        final setupCompleted = userProfile?.metadata?['setupCompleted'] ?? false;
        
        if (setupCompleted) {
          // Navigate to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Navigate to user setup screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const UserSetupScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign in';
      
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'Account exists with different credentials';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'user-not-found':
          errorMessage = 'No account found';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }
      
      if (mounted) {
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to sign in: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxHeight < 700;
              final headerHeight = isSmallScreen ? 200.0 : 280.0;
              
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Header Section
                    SizedBox(
                      height: headerHeight,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App Logo/Icon
                              Container(
                                width: isSmallScreen ? 100 : 120,
                                height: isSmallScreen ? 100 : 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(60),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.school,
                                  size: isSmallScreen ? 50 : 60,
                                  color: const Color(0xFF6B73FF),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 24 : 32),
                              
                              // App Title
                              Text(
                                'Little Learners Academy',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 22 : 28,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 16),
                              
                              // Subtitle
                              Text(
                                'Fun Learning Adventures for Kids',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Login Section
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: isSmallScreen ? 24 : 40),
                              
                              // Welcome Text
                              Text(
                                'Welcome Back!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: const Color(0xFF2C3E50),
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 20 : 24,
                                    ),
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              
                              Text(
                                'Sign in to continue your learning journey',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: const Color(0xFF7F8C8D),
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isSmallScreen ? 32 : 48),
                              
                              // Google Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: isSmallScreen ? 48 : 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _signInWithGoogle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF2C3E50),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  icon: _isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Color(0xFF6B73FF),
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.login,
                                          size: 24,
                                          color: Color(0xFF6B73FF),
                                        ),
                                  label: Text(
                                    _isLoading 
                                        ? 'Signing In...' 
                                        : 'Continue with Google',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 24 : 32),
                              
                              // Benefits Section
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Why sign in?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: const Color(0xFF2C3E50),
                                            fontWeight: FontWeight.w600,
                                            fontSize: isSmallScreen ? 16 : 18,
                                          ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 12 : 16),
                                    
                                    // Benefits List
                                    ...[
                                      '🎯 Track your child\'s progress',
                                      '🏆 Unlock achievements and badges',
                                      '📊 Get detailed learning reports',
                                      '☁️ Sync across all devices',
                                      '🎮 Access premium content',
                                    ].map((benefit) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Text(
                                            benefit.split(' ')[0],
                                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              benefit.substring(benefit.indexOf(' ') + 1),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: const Color(0xFF5D6D7E),
                                                    fontSize: isSmallScreen ? 12 : 14,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 24 : 32),
                              
                              // Privacy Note
                              Text(
                                'By signing in, you agree to our Terms of Service and Privacy Policy',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF95A5A6),
                                      fontSize: isSmallScreen ? 11 : 12,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              
                              // Extra padding for small screens
                              SizedBox(height: isSmallScreen ? 20 : 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
