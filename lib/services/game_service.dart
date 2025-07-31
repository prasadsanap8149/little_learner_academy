import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/player_progress.dart';
import '../models/game_level.dart';
import '../models/age_group.dart';

class GameService {
  static const String _playerKey = 'player_progress';
  static const String _currentPlayerKey = 'current_player_id';

  late SharedPreferences _prefs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  PlayerProgress? _currentPlayer;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCurrentPlayer();
  }

  PlayerProgress? get currentPlayer => _currentPlayer;

  Future<void> createPlayer(String name, int age) async {
    final playerId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentPlayer = PlayerProgress.newPlayer(
      playerId: playerId,
      playerName: name,
      age: age,
    );

    await _saveCurrentPlayer();
    await _prefs.setString(_currentPlayerKey, playerId);
  }

  Future<void> _loadCurrentPlayer() async {
    final playerId = _prefs.getString(_currentPlayerKey);
    if (playerId != null) {
      final playerData = _prefs.getString('${_playerKey}_$playerId');
      if (playerData != null) {
        _currentPlayer = PlayerProgress.fromJson(json.decode(playerData));
      }
    }
  }

  Future<void> _saveCurrentPlayer() async {
    if (_currentPlayer != null) {
      // Save to local storage
      final playerData = json.encode(_currentPlayer!.toJson());
      await _prefs.setString(
          '${_playerKey}_${_currentPlayer!.playerId}', playerData);
      
      // Save to Firebase if user is authenticated
      await _saveProgressToFirebase();
    }
  }

  Future<void> _saveProgressToFirebase() async {
    if (_auth.currentUser == null || _currentPlayer == null) return;
    
    try {
      final progressRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('progress')
          .doc('player_data');
      
      final progressData = {
        'playerName': _currentPlayer!.playerName,
        'playerAge': _currentPlayer!.age,
        'totalStars': _currentPlayer!.totalStars,
        'playerId': _currentPlayer!.playerId,
        'lastPlayed': Timestamp.fromDate(_currentPlayer!.lastPlayed),
        'achievements': _currentPlayer!.achievements,
        'highestUnlockedAgeGroup': _currentPlayer!.highestUnlockedAgeGroup.toString(),
        'categories': _currentPlayer!.categories.map((key, value) => MapEntry(key, {
          'categoryId': value.categoryId,
          'unlockedLevels': value.unlockedLevels,
          'currentAgeGroup': value.currentAgeGroup.toString(),
          'levels': value.levels.map((levelKey, level) => MapEntry(levelKey, {
            'levelId': level.levelId,
            'stars': level.stars,
            'highScore': level.highScore,
            'isCompleted': level.isCompleted,
            'lastPlayed': level.lastPlayed != null 
                ? Timestamp.fromDate(level.lastPlayed!) 
                : null,
          })),
        })),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await progressRef.set(progressData, SetOptions(merge: true));
      print('Player progress saved to Firebase successfully');
    } catch (e) {
      print('Error saving progress to Firebase: $e');
      // Don't throw error to avoid breaking local functionality
    }
  }

  // Manual sync method for periodic syncing
  Future<void> syncProgressToFirebase() async {
    await _saveProgressToFirebase();
  }

  // Method to check if Firebase sync is available
  bool get canSyncToFirebase => _auth.currentUser != null && _currentPlayer != null;

  Future<void> updateLevelScore(String levelId, int score) async {
    if (_currentPlayer != null) {
      // Parse category ID from level ID (format: "category_name_number")
      final categoryId = levelId.split('_').take(2).join('_');

      // Get current categories map
      final categories =
          Map<String, CategoryProgress>.from(_currentPlayer!.categories);

      // Get or create category progress
      final categoryProgress = categories[categoryId] ??
          CategoryProgress(
            categoryId: categoryId,
            levels: {},
            unlockedLevels: 1,
            currentAgeGroup: AgeGroup.fromAge(_currentPlayer!.age),
          );

      // Update levels map for the category
      final levels = Map<String, LevelProgress>.from(categoryProgress.levels);

      // Calculate stars (assuming max score of 100 per level)
      int stars = (score / 33.33).ceil().clamp(0, 3); // 3 stars max per level

      // Update or create level progress
      levels[levelId] = LevelProgress(
        levelId: levelId,
        stars: stars,
        highScore: score,
        isCompleted: true,
        lastPlayed: DateTime.now(),
      );

      // Update category with new levels
      categories[categoryId] = categoryProgress.copyWith(levels: levels);

      // Calculate total stars across all categories and levels
      int totalStars = categories.values
          .expand((cat) => cat.levels.values)
          .fold(0, (sum, level) => sum + level.stars);

      _currentPlayer = _currentPlayer!.copyWith(
        categories: categories,
        totalStars: totalStars,
        lastPlayed: DateTime.now(),
      );

      await _saveCurrentPlayer();
    }
  }

  Future<void> addAchievement(String achievement) async {
    if (_currentPlayer != null &&
        !_currentPlayer!.achievements.contains(achievement)) {
      final achievements = List<String>.from(_currentPlayer!.achievements);
      achievements.add(achievement);

      _currentPlayer = _currentPlayer!.copyWith(
        achievements: achievements,
        lastPlayed: DateTime.now(),
      );

      await _saveCurrentPlayer();

      // Check if achievement unlocks a new age group
      _checkAndUpdateAgeGroupProgress();
    }
  }

  void _checkAndUpdateAgeGroupProgress() {
    if (_currentPlayer == null) return;

    // Example logic - can be customized based on game requirements
    final currentAgeGroup = AgeGroup.fromAge(_currentPlayer!.age);
    final achievementCount = _currentPlayer!.achievements.length;
    final totalStars = _currentPlayer!.totalStars;

    // Unlock next age group if player has enough achievements and stars
    if (currentAgeGroup != AgeGroup.tween &&
        achievementCount >= 5 &&
        totalStars >= 50 &&
        currentAgeGroup.index < _currentPlayer!.highestUnlockedAgeGroup.index) {
      final nextAgeGroup = AgeGroup.values[currentAgeGroup.index + 1];
      _currentPlayer = _currentPlayer!.copyWith(
        highestUnlockedAgeGroup: nextAgeGroup,
      );
    }
  }

  List<GameLevel> getAvailableLevels() {
    if (_currentPlayer == null) return [];

    final ageGroup = AgeGroup.fromAge(_currentPlayer!.age);
    return _generateLevelsForAgeGroup(ageGroup);
  }

  List<GameLevel> _generateLevelsForAgeGroup(AgeGroup ageGroup) {
    List<GameLevel> levels = [];

    // Math levels
    levels.addAll(_generateMathLevels(ageGroup));

    // Language levels
    levels.addAll(_generateLanguageLevels(ageGroup));

    // Science levels
    levels.addAll(_generateScienceLevels(ageGroup));

    // General levels
    levels.addAll(_generateGeneralLevels(ageGroup));

    return levels;
  }

  List<GameLevel> _generateMathLevels(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.toddler:
        return [
          GameLevel(
            id: 'math_count_1',
            title: 'Count the Animals',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Count objects 1-5', 'Recognize numbers'],
            maxScore: 100,
            isUnlocked: true,
          ),
          GameLevel(
            id: 'math_count_2',
            title: 'More Counting Fun',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Count objects 1-10', 'Number recognition'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'math_shapes_1',
            title: 'Shape Safari',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.puzzle,
            difficulty: 1,
            objectives: ['Identify basic shapes', 'Match shapes'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'math_sizes_1',
            title: 'Big and Small',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Compare sizes', 'Size recognition'],
            maxScore: 100,
          ),
        ];

      case AgeGroup.elementary:
        return [
          GameLevel(
            id: 'math_count_1',
            title: 'Count Everything',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Count objects 1-20', 'Number patterns'],
            maxScore: 100,
            isUnlocked: true,
          ),
          GameLevel(
            id: 'math_add_1',
            title: 'Addition Adventure',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.adventure,
            difficulty: 2,
            objectives: ['Simple addition', 'Number bonds'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'math_subtract_1',
            title: 'Subtraction Space',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.quiz,
            difficulty: 2,
            objectives: ['Basic subtraction', 'Problem solving'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'math_patterns_1',
            title: 'Pattern Detective',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.puzzle,
            difficulty: 2,
            objectives: ['Number patterns', 'Sequence completion'],
            maxScore: 100,
          ),
        ];

      case AgeGroup.tween:
        return [
          GameLevel(
            id: 'math_count_1',
            title: 'Advanced Counting',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Count objects 1-50', 'Skip counting'],
            maxScore: 100,
            isUnlocked: true,
          ),
          GameLevel(
            id: 'math_multiply_1',
            title: 'Multiplication Mountain',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.adventure,
            difficulty: 3,
            objectives: ['Times tables', 'Mental math'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'math_fraction_1',
            title: 'Fraction Fortress',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.puzzle,
            difficulty: 4,
            objectives: ['Understand fractions', 'Compare fractions'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'math_division_1',
            title: 'Division Challenge',
            subject: Subject.math,
            ageGroup: ageGroup,
            gameType: GameType.quiz,
            difficulty: 4,
            objectives: ['Division basics', 'Equal groups'],
            maxScore: 100,
          ),
        ];
    }
  }

  List<GameLevel> _generateLanguageLevels(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.toddler:
        return [
          GameLevel(
            id: 'lang_alphabet_1',
            title: 'Alphabet Zoo',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Learn letter sounds', 'Recognize letters A-Z'],
            maxScore: 100,
            isUnlocked: true,
          ),
          GameLevel(
            id: 'lang_sounds_1',
            title: 'First Sounds',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Letter sounds', 'Beginning sounds'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'lang_words_1',
            title: 'First Words',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.puzzle,
            difficulty: 1,
            objectives: ['Simple words', 'Picture matching'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'lang_rhymes_1',
            title: 'Rhyme Time',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Rhyming words', 'Sound patterns'],
            maxScore: 100,
          ),
        ];

      case AgeGroup.elementary:
        return [
          GameLevel(
            id: 'lang_alphabet_1',
            title: 'Advanced Alphabet',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Letter recognition', 'Alphabetical order'],
            maxScore: 100,
            isUnlocked: true,
          ),
          GameLevel(
            id: 'lang_phonics_1',
            title: 'Phonics Forest',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.adventure,
            difficulty: 2,
            objectives: ['Sound out words', 'Simple reading'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'lang_spelling_1',
            title: 'Spelling Bee',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.quiz,
            difficulty: 2,
            objectives: ['Spell simple words', 'Letter patterns'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'lang_reading_1',
            title: 'Reading Adventures',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.adventure,
            difficulty: 3,
            objectives: ['Read sentences', 'Comprehension'],
            maxScore: 100,
          ),
        ];

      case AgeGroup.tween:
        return [
          GameLevel(
            id: 'lang_alphabet_1',
            title: 'Perfect Alphabet',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Speed recognition', 'Advanced patterns'],
            maxScore: 100,
            isUnlocked: true,
          ),
          GameLevel(
            id: 'lang_vocabulary_1',
            title: 'Word Wizard',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.quiz,
            difficulty: 3,
            objectives: ['Expand vocabulary', 'Reading comprehension'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'lang_grammar_1',
            title: 'Grammar Guardian',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.puzzle,
            difficulty: 4,
            objectives: ['Grammar rules', 'Sentence structure'],
            maxScore: 100,
          ),
          GameLevel(
            id: 'lang_writing_1',
            title: 'Story Creator',
            subject: Subject.language,
            ageGroup: ageGroup,
            gameType: GameType.adventure,
            difficulty: 4,
            objectives: ['Creative writing', 'Story elements'],
            maxScore: 100,
          ),
        ];
    }
  }

  List<GameLevel> _generateScienceLevels(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.toddler:
        return [
          GameLevel(
            id: 'science_animals_1',
            title: 'Animal Friends',
            subject: Subject.science,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Identify animals', 'Animal sounds'],
            maxScore: 100,
            isUnlocked: true,
          ),
        ];

      case AgeGroup.elementary:
        return [
          GameLevel(
            id: 'science_plants_1',
            title: 'Plant Paradise',
            subject: Subject.science,
            ageGroup: ageGroup,
            gameType: GameType.adventure,
            difficulty: 2,
            objectives: ['Learn about plants', 'How plants grow'],
            maxScore: 100,
            isUnlocked: true,
          ),
        ];

      case AgeGroup.tween:
        return [
          GameLevel(
            id: 'science_space_1',
            title: 'Space Explorer',
            subject: Subject.science,
            ageGroup: ageGroup,
            gameType: GameType.quiz,
            difficulty: 3,
            objectives: ['Solar system', 'Space facts'],
            maxScore: 100,
            isUnlocked: true,
          ),
        ];
    }
  }

  List<GameLevel> _generateGeneralLevels(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.toddler:
        return [
          GameLevel(
            id: 'general_colors_1',
            title: 'Color Carnival',
            subject: Subject.general,
            ageGroup: ageGroup,
            gameType: GameType.matching,
            difficulty: 1,
            objectives: ['Learn colors', 'Color matching'],
            maxScore: 100,
            isUnlocked: true,
          ),
        ];

      case AgeGroup.elementary:
        return [
          GameLevel(
            id: 'general_world_1',
            title: 'World Wonders',
            subject: Subject.general,
            ageGroup: ageGroup,
            gameType: GameType.adventure,
            difficulty: 2,
            objectives: ['Learn about countries', 'Famous landmarks'],
            maxScore: 100,
            isUnlocked: true,
          ),
        ];

      case AgeGroup.tween:
        return [
          GameLevel(
            id: 'general_history_1',
            title: 'Time Travel',
            subject: Subject.general,
            ageGroup: ageGroup,
            gameType: GameType.quiz,
            difficulty: 3,
            objectives: ['Historical events', 'Famous people'],
            maxScore: 100,
            isUnlocked: true,
          ),
        ];
    }
  }

  Future<void> logout() async {
    try {
      // Clear current player in memory
      _currentPlayer = null;
      
      // Clear current player ID from SharedPreferences
      await _prefs.remove(_currentPlayerKey);
      
      // Clear all player data from SharedPreferences
      final keys = _prefs.getKeys();
      final playerKeys = keys.where((key) => key.startsWith(_playerKey));
      for (final key in playerKeys) {
        await _prefs.remove(key);
      }
      
      // Optionally clear all app preferences (uncomment if you want to clear everything)
      // await _prefs.clear();
      
      print('Logout completed successfully - all user data cleared');
    } catch (e) {
      print('Error during logout: $e');
      // Fallback: try to clear everything if selective clearing fails
      try {
        _currentPlayer = null;
        await _prefs.clear();
        print('Fallback logout completed - all preferences cleared');
      } catch (fallbackError) {
        print('Fallback logout also failed: $fallbackError');
      }
    }
  }

  // Method to verify logout was successful
  bool isLoggedOut() {
    return _currentPlayer == null && 
           !_prefs.containsKey(_currentPlayerKey);
  }

  // Method to get all stored player keys (for debugging)
  List<String> getStoredPlayerKeys() {
    final keys = _prefs.getKeys();
    return keys.where((key) => key.startsWith(_playerKey)).toList();
  }

  // Load player progress from Firebase
  Future<void> loadProgressFromFirebase() async {
    if (_auth.currentUser == null) return;
    
    try {
      final progressRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('progress')
          .doc('player_data');
      
      final doc = await progressRef.get();
      if (!doc.exists) return;
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Only load if we don't have local data or Firebase data is newer
      final firebaseUpdated = (data['updatedAt'] as Timestamp?)?.toDate();
      final localLastPlayed = _currentPlayer?.lastPlayed;
      
      if (_currentPlayer == null || 
          (firebaseUpdated != null && 
           (localLastPlayed == null || firebaseUpdated.isAfter(localLastPlayed)))) {
        
        // Reconstruct PlayerProgress from Firebase data
        final playerName = data['playerName'] as String? ?? 'Player';
        final playerAge = data['playerAge'] as int? ?? 5;
        final playerId = data['playerId'] as String? ?? _auth.currentUser!.uid;
        
        // Create categories map from Firebase data
        final Map<String, CategoryProgress> categories = {};
        final categoriesData = data['categories'] as Map<String, dynamic>? ?? {};
        
        categoriesData.forEach((categoryKey, categoryValue) {
          final catData = categoryValue as Map<String, dynamic>;
          final levelsData = catData['levels'] as Map<String, dynamic>? ?? {};
          
          final Map<String, LevelProgress> levels = {};
          levelsData.forEach((levelKey, levelValue) {
            final levelData = levelValue as Map<String, dynamic>;
            levels[levelKey] = LevelProgress(
              levelId: levelData['levelId'] as String? ?? levelKey,
              stars: levelData['stars'] as int? ?? 0,
              highScore: levelData['highScore'] as int? ?? 0,
              isCompleted: levelData['isCompleted'] as bool? ?? false,
              lastPlayed: (levelData['lastPlayed'] as Timestamp?)?.toDate(),
            );
          });
          
          categories[categoryKey] = CategoryProgress(
            categoryId: catData['categoryId'] as String? ?? categoryKey,
            unlockedLevels: catData['unlockedLevels'] as int? ?? 1,
            currentAgeGroup: AgeGroup.values.firstWhere(
              (e) => e.toString() == catData['currentAgeGroup'],
              orElse: () => AgeGroup.toddler,
            ),
            levels: levels,
          );
        });
        
        final highestUnlockedAgeGroup = AgeGroup.values.firstWhere(
          (e) => e.toString() == data['highestUnlockedAgeGroup'],
          orElse: () => AgeGroup.toddler,
        );
        
        _currentPlayer = PlayerProgress(
          playerId: playerId,
          playerName: playerName,
          age: playerAge,
          totalStars: data['totalStars'] as int? ?? 0,
          lastPlayed: (data['lastPlayed'] as Timestamp?)?.toDate() ?? DateTime.now(),
          achievements: List<String>.from(data['achievements'] ?? []),
          categories: categories,
          highestUnlockedAgeGroup: highestUnlockedAgeGroup,
        );
        
        // Save the loaded data locally
        final playerData = json.encode(_currentPlayer!.toJson());
        await _prefs.setString(
            '${_playerKey}_${_currentPlayer!.playerId}', playerData);
        await _prefs.setString(_currentPlayerKey, _currentPlayer!.playerId);
        
        print('Player progress loaded from Firebase successfully');
      }
    } catch (e) {
      print('Error loading progress from Firebase: $e');
      // Don't throw error to avoid breaking local functionality
    }
  }
}
