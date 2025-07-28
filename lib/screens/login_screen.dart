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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header Section
                Expanded(
                  flex: 2,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo/Icon
                        Container(
                          width: 120,
                          height: 120,
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
                          child: const Icon(
                            Icons.school,
                            size: 60,
                            color: Color(0xFF6B73FF),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // App Title
                        Text(
                          'Little Learners Academy',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Subtitle
                        Text(
                          'Fun Learning Adventures for Kids',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Login Section
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Welcome Text
                          Text(
                            'Welcome Back!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: const Color(0xFF2C3E50),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          
                          Text(
                            'Sign in to continue your learning journey',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: const Color(0xFF7F8C8D),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          
                          // Google Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2C3E50),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: const Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF6B73FF),
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/google_logo.png',
                                      width: 24,
                                      height: 24,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.login,
                                          size: 24,
                                          color: Color(0xFF6B73FF),
                                        );
                                      },
                                    ),
                              label: Text(
                                _isLoading 
                                    ? 'Signing In...' 
                                    : 'Continue with Google',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Benefits Section
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                      ),
                                ),
                                const SizedBox(height: 16),
                                
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
                                        style: const TextStyle(fontSize: 16),
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
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Privacy Note
                          Text(
                            'By signing in, you agree to our Terms of Service and Privacy Policy',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF95A5A6),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
}
