import 'package:flutter/material.dart';
import 'package:little_learners_academy/screens/login_screen.dart';
import '../screens/welcome_screen.dart';
import '../models/age_group.dart';
import '../models/player_progress.dart';
import '../models/game_level.dart';
import 'game_service.dart';
import 'auth_service.dart';

class GameProvider extends ChangeNotifier {
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  
  GameService get gameService => _gameService;
  AuthService get authService => _authService;
  bool get isLoading => _isLoading;
  
  // Add missing getter methods
  PlayerProgress? get playerProgress => _gameService.currentPlayer;
  List<GameLevel> get allGameLevels => _gameService.getAvailableLevels();
  AgeGroup? get selectedAgeGroup => _gameService.currentPlayer != null 
      ? AgeGroup.fromAge(_gameService.currentPlayer!.age) 
      : null;
  
  GameProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _gameService.initialize();
    
    // If user is authenticated, try to load from Firebase
    if (_authService.isAuthenticated) {
      await loadPlayerFromFirebase();
    }
    
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

  // Load player data from Firebase if authenticated user has completed setup
  Future<void> loadPlayerFromFirebase() async {
    if (!_authService.isAuthenticated) return;
    
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) return;
      
      final setupCompleted = userProfile.metadata?['setupCompleted'] ?? false;
      final childName = userProfile.metadata?['childName'] as String?;
      final childAge = userProfile.metadata?['childAge'] as int?;
      
      if (setupCompleted && childName != null && childAge != null) {
        // First try to load existing progress from Firebase
        await _gameService.loadProgressFromFirebase();
        
        // If no progress exists, create new player
        if (_gameService.currentPlayer == null) {
          await createPlayer(childName, childAge);
          print('New player created from Firebase profile: $childName, age $childAge');
        } else {
          print('Player progress loaded from Firebase: ${_gameService.currentPlayer!.playerName}');
        }
      }
    } catch (e) {
      print('Error loading player from Firebase: $e');
    }
  }

  // Manual sync method for UI
  Future<void> syncToFirebase() async {
    if (_gameService.canSyncToFirebase) {
      await _gameService.syncProgressToFirebase();
      print('Progress manually synced to Firebase');
    }
  }

  // Check if Firebase sync is available
  bool get canSyncToFirebase => _gameService.canSyncToFirebase;

  // Method to update age group
  Future<void> setAgeGroup(AgeGroup ageGroup) async {
    if (_gameService.currentPlayer != null) {
      // Update the player's age based on the selected age group
      int newAge;
      switch (ageGroup) {
        case AgeGroup.littleTots:
          newAge = 4; // Representative age for little tots (3-5)
          break;
        case AgeGroup.smartKids:
          newAge = 7; // Representative age for smart kids (6-8)
          break;
        case AgeGroup.youngScholars:
          newAge = 10; // Representative age for young scholars (9-12)
          break;
      }
      
      // Update the player's age
      final updatedPlayer = _gameService.currentPlayer!.copyWith(age: newAge);
      await _gameService.updatePlayer(updatedPlayer);
      notifyListeners();
    }
  }
}
