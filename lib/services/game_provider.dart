import 'package:flutter/material.dart';
import 'package:little_learners_academy/screens/login_screen.dart';
import '../screens/welcome_screen.dart';
import 'game_service.dart';
import 'auth_service.dart';

class GameProvider extends ChangeNotifier {
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  
  GameService get gameService => _gameService;
  AuthService get authService => _authService;
  bool get isLoading => _isLoading;
  
  GameProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _gameService.initialize();
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> createPlayer(String name, int age) async {
    await _gameService.createPlayer(name, age);
    
    // If user is authenticated, sync with Firebase
    if (_authService.isAuthenticated) {
      try {
        // Update player data in user's profile metadata
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          // This could be handled by the auth service
          // For now, we'll just notify listeners
        }
      } catch (e) {
        print('Error syncing player data: $e');
      }
    }
    
    notifyListeners();
  }
  
  Future<void> updateProgress(String levelId, int score) async {
    await _gameService.updateLevelScore(levelId, score);
    notifyListeners();
  }
  
  Future<void> addAchievement(String achievement) async {
    await _gameService.addAchievement(achievement);
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Logging out...'),
            ],
          ),
        ),
      );

      // Clear local game data
      await _gameService.logout();
      
      // Sign out from Firebase if user is authenticated
      if (_authService.currentUser != null) {
        await _authService.signOut();
      }
      
      // Verify logout was successful
      final isLoggedOut = _gameService.isLoggedOut();
      print('Logout verification: ${isLoggedOut ? "SUCCESS" : "FAILED"}');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Update UI state
      notifyListeners();

      // Navigate to login screen and clear navigation stack
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      // Handle logout errors gracefully
      print('Error during logout: $e');
      
      // Close loading dialog if it's still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Still try to navigate even if there's an error
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

}
