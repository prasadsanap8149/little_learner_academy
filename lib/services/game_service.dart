import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/player_progress.dart';
import '../models/game_level.dart';
import '../models/age_group.dart';
import 'offline_service.dart';

class GameService {
  static const String _playerKey = 'player_progress';
  static const String _currentPlayerKey = 'current_player_id';
  static const String _offlineScoresKey = 'offline_scores';
  static const String _offlineProgressKey = 'offline_progress';

  late SharedPreferences _prefs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineService _offlineService = OfflineService();
  final OfflineManager _offlineManager = OfflineManager();
  PlayerProgress? _currentPlayer;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _offlineService.initialize();
    await _loadCurrentPlayer();
    await _loadOfflineData();
    
    // Listen for connectivity changes to sync offline data
    _offlineService.connectivityStream.listen((isOnline) {
      if (isOnline) {
        _syncOfflineData();
      }
    });
  }

  PlayerProgress? get currentPlayer => _currentPlayer;
  bool get isOnline => _offlineService.isOnline;

  // Enhanced player creation with offline support
  Future<void> createPlayer(String name, int age) async {
    final playerId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentPlayer = PlayerProgress.newPlayer(
      playerId: playerId,
      playerName: name,
      age: age,
    );

    await _saveCurrentPlayer();
    await _prefs.setString(_currentPlayerKey, playerId);
    
    // Cache player data for offline access
    _offlineManager.cacheData('current_player', _currentPlayer!.toJson());
  }

  // Load offline cached data
  Future<void> _loadOfflineData() async {
    final cachedPlayer = _offlineManager.getCachedData<Map<String, dynamic>>('current_player');
    if (cachedPlayer != null && _currentPlayer == null) {
      _currentPlayer = PlayerProgress.fromJson(cachedPlayer);
    }
  }

  // Save game progress with offline support
  Future<void> saveGameProgress({
    required String gameId,
    required int level,
    required int score,
    required int timeSpent,
    bool completed = false,
  }) async {
    if (_currentPlayer == null) return;

    // Always save locally first
    _currentPlayer!.updateGameProgress(
      gameId: gameId,
      level: level,
      score: score,
      timeSpent: timeSpent,
      completed: completed,
    );
    
    await _saveCurrentPlayer();

    if (isOnline) {
      // If online, save to Firestore immediately
      try {
        await _saveToFirestore();
      } catch (e) {
        print('Error saving to Firestore: $e');
        // If Firestore fails, save to offline queue
        _saveToOfflineQueue(gameId, level, score, timeSpent, completed);
      }
    } else {
      // If offline, save to offline queue
      _saveToOfflineQueue(gameId, level, score, timeSpent, completed);
    }
  }

  // Save to offline queue for later sync
  void _saveToOfflineQueue(String gameId, int level, int score, int timeSpent, bool completed) {
    final offlineProgress = {
      'gameId': gameId,
      'level': level,
      'score': score,
      'timeSpent': timeSpent,
      'completed': completed,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final existingProgress = _prefs.getStringList(_offlineProgressKey) ?? [];
    existingProgress.add(json.encode(offlineProgress));
    _prefs.setStringList(_offlineProgressKey, existingProgress);
    
    _offlineManager.addPendingOperation('game_progress_${DateTime.now().millisecondsSinceEpoch}');
  }

  // Sync offline data when connection is restored
  Future<void> _syncOfflineData() async {
    if (!isOnline) return;

    try {
      // Sync offline progress
      final offlineProgress = _prefs.getStringList(_offlineProgressKey) ?? [];
      
      for (final progressJson in offlineProgress) {
        final progress = json.decode(progressJson);
        // Update current player with offline progress
        if (_currentPlayer != null) {
          _currentPlayer!.updateGameProgress(
            gameId: progress['gameId'],
            level: progress['level'],
            score: progress['score'],
            timeSpent: progress['timeSpent'],
            completed: progress['completed'],
          );
        }
      }
      
      // Save all synced data to Firestore
      if (_currentPlayer != null) {
        await _saveToFirestore();
      }
      
      // Clear offline queue after successful sync
      await _prefs.remove(_offlineProgressKey);
      
      // Clear pending operations
      for (final operation in _offlineManager.getPendingOperations()) {
        _offlineManager.clearPendingOperation(operation);
      }
      
      print('Offline data synced successfully');
    } catch (e) {
      print('Error syncing offline data: $e');
    }
  }

  // Save to Firestore with error handling
  Future<void> _saveToFirestore() async {
    if (_currentPlayer == null || !isOnline) return;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('player_progress')
            .doc(user.uid)
            .set(_currentPlayer!.toJson());
      }
    } catch (e) {
      print('Error saving to Firestore: $e');
      rethrow;
    }
  }

  // Get cached game levels for offline play
  List<GameLevel> getCachedGameLevels(String gameId) {
    final cachedLevels = _offlineManager.getCachedData<List<dynamic>>('game_levels_$gameId');
    if (cachedLevels != null) {
      return cachedLevels.map((level) => GameLevel.fromJson(level)).toList();
    }
    return _getDefaultGameLevels(gameId);
  }

  // Cache game levels for offline access
  void cacheGameLevels(String gameId, List<GameLevel> levels) {
    _offlineManager.cacheData('game_levels_$gameId', levels.map((l) => l.toJson()).toList());
  }

  // Get offline playable games
  bool isGameAvailableOffline(String gameId) {
    final cachedLevels = _offlineManager.getCachedData<List<dynamic>>('game_levels_$gameId');
    return cachedLevels != null && cachedLevels.isNotEmpty;
  }

  // Get pending sync status
  bool hasPendingSync() {
    return _offlineManager.getPendingOperations().isNotEmpty;
  }

  // Get sync status message
  String getSyncStatusMessage() {
    if (isOnline && !hasPendingSync()) {
      return 'All data synced';
    } else if (isOnline && hasPendingSync()) {
      return 'Syncing...';
    } else if (!isOnline && hasPendingSync()) {
      return 'Will sync when online';
    } else {
      return 'Offline mode';
    }
  }

  Future<void> updatePlayer(PlayerProgress updatedPlayer) async {
    _currentPlayer = updatedPlayer.copyWith(lastPlayed: DateTime.now());
    await _saveCurrentPlayer();
    
    // Sync to Firebase if possible
    if (canSyncToFirebase) {
      await _saveProgressToFirebase();
    }
  }

  // Load current player from storage
  Future<void> _loadCurrentPlayer() async {
    try {
      final playerId = _prefs.getString(_currentPlayerKey);
      if (playerId != null) {
        final playerData = _prefs.getString('${_playerKey}_$playerId');
        if (playerData != null) {
          final json = jsonDecode(playerData) as Map<String, dynamic>;
          _currentPlayer = PlayerProgress.fromJson(json);
        }
      }
    } catch (e) {
      print('Error loading current player: $e');
    }
  }

  // Save current player to storage
  Future<void> _saveCurrentPlayer() async {
    if (_currentPlayer != null) {
      try {
        final json = _currentPlayer!.toJson();
        await _prefs.setString('${_playerKey}_${_currentPlayer!.playerId}', jsonEncode(json));
      } catch (e) {
        print('Error saving current player: $e');
      }
    }
  }

  // Get available levels for all games
  List<GameLevel> getAvailableLevels() {
    final List<GameLevel> allLevels = [];
    
    // Add levels from all game types
    allLevels.addAll(_getDefaultGameLevels('math_counting'));
    allLevels.addAll(_getDefaultGameLevels('alphabet_matching'));
    allLevels.addAll(_getDefaultGameLevels('color_matching'));
    allLevels.addAll(_getDefaultGameLevels('animal_science'));
    
    return allLevels;
  }

  // Get default game levels for a specific game
  List<GameLevel> _getDefaultGameLevels(String gameId) {
    switch (gameId) {
      case 'math_counting':
        return [
          GameLevel(
            id: 'math_1',
            gameId: gameId,
            levelNumber: 1,
            title: 'Count to 5',
            difficulty: 1,
            maxScore: 100,
            isUnlocked: true,
            ageGroup: AgeGroup.toddler,
          ),
          GameLevel(
            id: 'math_2',
            gameId: gameId,
            levelNumber: 2,
            title: 'Count to 10',
            difficulty: 2,
            maxScore: 100,
            isUnlocked: false,
            ageGroup: AgeGroup.toddler,
          ),
        ];
      case 'alphabet_matching':
        return [
          GameLevel(
            id: 'alphabet_1',
            gameId: gameId,
            levelNumber: 1,
            title: 'Letter A-E',
            difficulty: 1,
            maxScore: 100,
            isUnlocked: true,
            ageGroup: AgeGroup.toddler,
          ),
        ];
      case 'color_matching':
        return [
          GameLevel(
            id: 'color_1',
            gameId: gameId,
            levelNumber: 1,
            title: 'Basic Colors',
            difficulty: 1,
            maxScore: 100,
            isUnlocked: true,
            ageGroup: AgeGroup.toddler,
          ),
        ];
      case 'animal_science':
        return [
          GameLevel(
            id: 'animal_1',
            gameId: gameId,
            levelNumber: 1,
            title: 'Farm Animals',
            difficulty: 1,
            maxScore: 100,
            isUnlocked: true,
            ageGroup: AgeGroup.toddler,
          ),
        ];
      default:
        return [];
    }
  }

  // Update level score
  Future<void> updateLevelScore(String levelId, int score) async {
    if (_currentPlayer != null) {
      // Update score in player progress
      _currentPlayer = _currentPlayer!.copyWith(lastPlayed: DateTime.now());
      await _saveCurrentPlayer();
      
      // Queue for sync if offline
      if (!isOnline) {
        _offlineManager.queueOperation('updateScore', {
          'levelId': levelId,
          'score': score,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // Add achievement
  Future<void> addAchievement(String achievementId) async {
    if (_currentPlayer != null) {
      // Update achievement in player progress
      _currentPlayer = _currentPlayer!.copyWith(lastPlayed: DateTime.now());
      await _saveCurrentPlayer();
      
      // Queue for sync if offline
      if (!isOnline) {
        _offlineManager.queueOperation('addAchievement', {
          'achievementId': achievementId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // Logout
  Future<void> logout() async {
    _currentPlayer = null;
    await _prefs.remove(_currentPlayerKey);
    await _auth.signOut();
  }

  // Check if logged out
  bool isLoggedOut() {
    return _auth.currentUser == null || _currentPlayer == null;
  }

  // Load progress from Firebase
  Future<void> loadProgressFromFirebase() async {
    if (_auth.currentUser == null || !isOnline) return;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('progress')
          .doc('player_data')
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _currentPlayer = PlayerProgress.fromJson(data);
        await _saveCurrentPlayer();
      }
    } catch (e) {
      print('Error loading progress from Firebase: $e');
    }
  }

  // Check if can sync to Firebase
  bool get canSyncToFirebase => _auth.currentUser != null && isOnline;

  // Sync progress to Firebase
  Future<void> syncProgressToFirebase() async {
    if (!canSyncToFirebase || _currentPlayer == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('progress')
          .doc('player_data')
          .set(_currentPlayer!.toJson());
    } catch (e) {
      print('Error syncing to Firebase: $e');
    }
  }

  // Save progress to Firebase
  Future<void> _saveProgressToFirebase() async {
    await syncProgressToFirebase();
  }
}
