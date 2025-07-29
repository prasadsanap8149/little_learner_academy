import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import 'user_setup_screen.dart';
import 'home_screen.dart';

enum AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AuthMode _authMode = AuthMode.signIn;
  
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
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        await _navigateAfterAuth();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorDialog(_getFirebaseErrorMessage(e));
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

  Future<void> _signInWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (userCredential != null && mounted) {
        await _navigateAfterAuth();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorDialog(_getFirebaseErrorMessage(e));
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

  Future<void> _signUpWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      
      if (userCredential != null && mounted) {
        // Send email verification
        await _authService.sendEmailVerification();
        _showSuccessDialog('Account created successfully! Please check your email for verification.');
        await _navigateAfterAuth();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorDialog(_getFirebaseErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to create account: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your email address first.');
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text.trim());
      _showSuccessDialog('Password reset email sent! Check your inbox.');
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(_getFirebaseErrorMessage(e));
    } catch (e) {
      _showErrorDialog('Failed to send reset email: ${e.toString()}');
    }
  }

  Future<void> _navigateAfterAuth() async {
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

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
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

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
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
              final headerHeight = isSmallScreen ? 150.0 : 200.0;
              
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
                                width: isSmallScreen ? 80 : 100,
                                height: isSmallScreen ? 80 : 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(50),
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
                                  size: isSmallScreen ? 40 : 50,
                                  color: const Color(0xFF6B73FF),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              
                              // App Title
                              Text(
                                'Little Learners Academy',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 18 : 24,
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
                          padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                
                                // Auth Mode Toggle
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _authMode = AuthMode.signIn),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _authMode == AuthMode.signIn 
                                                  ? const Color(0xFF6B73FF) 
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Sign In',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: _authMode == AuthMode.signIn 
                                                    ? Colors.white 
                                                    : const Color(0xFF7F8C8D),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _authMode = AuthMode.signUp),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _authMode == AuthMode.signUp 
                                                  ? const Color(0xFF6B73FF) 
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Sign Up',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: _authMode == AuthMode.signUp 
                                                    ? Colors.white 
                                                    : const Color(0xFF7F8C8D),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: isSmallScreen ? 20 : 24),
                                
                                // Title
                                Text(
                                  _authMode == AuthMode.signIn ? 'Welcome Back!' : 'Create Account',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: const Color(0xFF2C3E50),
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 18 : 22,
                                      ),
                                ),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                
                                Text(
                                  _authMode == AuthMode.signIn 
                                      ? 'Sign in to continue your learning journey'
                                      : 'Join us and start your learning adventure',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: const Color(0xFF7F8C8D),
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 24),
                                
                                // Name Field (for sign up only)
                                if (_authMode == AuthMode.signUp) ...[
                                  TextFormField(
                                    controller: _nameController,
                                    validator: _validateName,
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                
                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                
                                // Confirm Password Field (for sign up only)
                                if (_authMode == AuthMode.signUp) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    validator: _validateConfirmPassword,
                                    obscureText: _obscureConfirmPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                                
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                
                                // Forgot Password (for sign in only)
                                if (_authMode == AuthMode.signIn)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _resetPassword,
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ),
                                
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                
                                // Auth Button
                                SizedBox(
                                  width: double.infinity,
                                  height: isSmallScreen ? 45 : 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading 
                                        ? null 
                                        : (_authMode == AuthMode.signIn 
                                            ? _signInWithEmailPassword 
                                            : _signUpWithEmailPassword),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B73FF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _authMode == AuthMode.signIn ? 'Sign In' : 'Create Account',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                
                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                  ],
                                ),
                                
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                
                                // Google Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: isSmallScreen ? 45 : 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _signInWithGoogle,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF2C3E50),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: Color(0xFFE0E0E0),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    icon: SvgPicture.asset(
                                      'assets/images/google_logo.svg',
                                      width: 20,
                                      height: 20,
                                    ),
                                    label: Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                
                                // Privacy Note
                                Text(
                                  'By ${_authMode == AuthMode.signIn ? 'signing in' : 'creating an account'}, you agree to our Terms of Service and Privacy Policy',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF95A5A6),
                                        fontSize: isSmallScreen ? 10 : 11,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
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
