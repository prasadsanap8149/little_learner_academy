import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/achievement.dart';
import '../models/game_level.dart';
import '../models/age_group.dart';
import 'sound_service.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SoundService _soundService = SoundService();
  
  List<Achievement> _userAchievements = [];
  
  List<Achievement> get userAchievements => _userAchievements;

  Future<void> initializeAchievements() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if user has achievements initialized
      final userAchievementsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .get();

      if (userAchievementsDoc.docs.isEmpty) {
        // Initialize with default achievements
        await _createDefaultAchievements(user.uid);
      }

      // Load user achievements
      await _loadUserAchievements(user.uid);
    } catch (e) {
      print('Error initializing achievements: $e');
    }
  }

  Future<void> _createDefaultAchievements(String userId) async {
    final defaultAchievements = Achievement.getDefaultAchievements();
    
    final batch = _firestore.batch();
    for (final achievement in defaultAchievements) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id);
      
      batch.set(docRef, achievement.toFirestore());
    }
    
    await batch.commit();
  }

  Future<void> _loadUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      _userAchievements = snapshot.docs
          .map((doc) => Achievement.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading user achievements: $e');
    }
  }

  Future<void> checkAchievements({
    GameLevel? completedGame,
    int? score,
    int? stars,
    bool? isNewStreak,
    Duration? completionTime,
    Set<String>? completedLevels,
    Set<AgeGroup>? unlockedAgeGroups,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newlyUnlockedAchievements = <Achievement>[];

    for (int i = 0; i < _userAchievements.length; i++) {
      final achievement = _userAchievements[i];
      if (achievement.isUnlocked) continue;

      Achievement? updatedAchievement;

      switch (achievement.type) {
        case AchievementType.firstGame:
          if (completedGame != null) {
            updatedAchievement = achievement.copyWith(
              isUnlocked: true,
              unlockedAt: DateTime.now(),
              progress: 1,
            );
          }
          break;

        case AchievementType.streakMaster:
          if (isNewStreak == true) {
            final newProgress = achievement.progress + 1;
            updatedAchievement = achievement.copyWith(
              progress: newProgress,
              isUnlocked: newProgress >= achievement.maxProgress,
              unlockedAt: newProgress >= achievement.maxProgress ? DateTime.now() : null,
            );
          }
          break;

        case AchievementType.speedRunner:
          if (completionTime != null && completionTime.inSeconds < 120) {
            updatedAchievement = achievement.copyWith(
              isUnlocked: true,
              unlockedAt: DateTime.now(),
              progress: 1,
            );
          }
          break;

        case AchievementType.perfectionist:
          if (stars != null && stars == 3) {
            final newProgress = achievement.progress + 1;
            updatedAchievement = achievement.copyWith(
              progress: newProgress,
              isUnlocked: newProgress >= achievement.maxProgress,
              unlockedAt: newProgress >= achievement.maxProgress ? DateTime.now() : null,
            );
          }
          break;

        case AchievementType.subjectExpert:
        case AchievementType.mathWizard:
          if (completedGame?.subject.toString().contains('math') == true) {
            final newProgress = achievement.progress + 1;
            updatedAchievement = achievement.copyWith(
              progress: newProgress,
              isUnlocked: newProgress >= achievement.maxProgress,
              unlockedAt: newProgress >= achievement.maxProgress ? DateTime.now() : null,
            );
          }
          break;

        case AchievementType.wordMaster:
          if (completedGame?.subject.toString().contains('language') == true) {
            final newProgress = achievement.progress + 1;
            updatedAchievement = achievement.copyWith(
              progress: newProgress,
              isUnlocked: newProgress >= achievement.maxProgress,
              unlockedAt: newProgress >= achievement.maxProgress ? DateTime.now() : null,
            );
          }
          break;

        case AchievementType.scientist:
          if (completedGame?.subject.toString().contains('science') == true) {
            final newProgress = achievement.progress + 1;
            updatedAchievement = achievement.copyWith(
              progress: newProgress,
              isUnlocked: newProgress >= achievement.maxProgress,
              unlockedAt: newProgress >= achievement.maxProgress ? DateTime.now() : null,
            );
          }
          break;

        case AchievementType.scholar:
          if (completedGame?.subject.toString().contains('general') == true) {
            final newProgress = achievement.progress + 1;
            updatedAchievement = achievement.copyWith(
              progress: newProgress,
              isUnlocked: newProgress >= achievement.maxProgress,
              unlockedAt: newProgress >= achievement.maxProgress ? DateTime.now() : null,
            );
          }
          break;

        case AchievementType.explorer:
          if (completedGame != null) {
            // This would need more complex logic to track unique subjects
            final newProgress = achievement.progress + 1;
            updatedAchievement = achievement.copyWith(
              progress: newProgress.clamp(0, achievement.maxProgress),
              isUnlocked: newProgress >= achievement.maxProgress,
              unlockedAt: newProgress >= achievement.maxProgress ? DateTime.now() : null,
            );
          }
          break;

        case AchievementType.youngLearner:
          if (unlockedAgeGroups != null && unlockedAgeGroups.length >= 3) {
            updatedAchievement = achievement.copyWith(
              isUnlocked: true,
              unlockedAt: DateTime.now(),
              progress: unlockedAgeGroups.length,
            );
          }
          break;

        case AchievementType.dedication:
          // This would need daily login tracking - placeholder for now
          break;
      }

      if (updatedAchievement != null) {
        _userAchievements[i] = updatedAchievement;
        
        // Save to Firestore
        await _saveAchievement(user.uid, updatedAchievement);
        
        // Check if newly unlocked
        if (updatedAchievement.isUnlocked && !achievement.isUnlocked) {
          newlyUnlockedAchievements.add(updatedAchievement);
        }
      }
    }

    // Show achievement notifications
    for (final achievement in newlyUnlockedAchievements) {
      await _showAchievementUnlocked(achievement);
    }
  }

  Future<void> _saveAchievement(String userId, Achievement achievement) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .update(achievement.toFirestore());
    } catch (e) {
      print('Error saving achievement: $e');
    }
  }

  Future<void> _showAchievementUnlocked(Achievement achievement) async {
    // Play achievement sound
    await _soundService.playAchievement();
    
    // Show notification (this would typically be handled by the UI layer)
    print('🎉 Achievement Unlocked: ${achievement.title}');
    print('${achievement.description} (+${achievement.points} points)');
  }

  int getTotalPoints() {
    return _userAchievements
        .where((achievement) => achievement.isUnlocked)
        .fold<int>(0, (total, achievement) => total + achievement.points);
  }

  int getUnlockedCount() {
    return _userAchievements.where((achievement) => achievement.isUnlocked).length;
  }

  int getTotalCount() {
    return _userAchievements.length;
  }

  List<Achievement> getUnlockedAchievements() {
    return _userAchievements.where((achievement) => achievement.isUnlocked).toList();
  }

  List<Achievement> getLockedAchievements() {
    return _userAchievements.where((achievement) => !achievement.isUnlocked).toList();
  }

  Achievement? getAchievementById(String id) {
    try {
      return _userAchievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get recently unlocked achievements
  List<Achievement> getRecentlyUnlockedAchievements({int limit = 5}) {
    final unlockedAchievements = _userAchievements
        .where((achievement) => achievement.isUnlocked)
        .toList();
    
    // Sort by unlock date (most recent first)
    unlockedAchievements.sort((a, b) {
      if (a.unlockedAt == null && b.unlockedAt == null) return 0;
      if (a.unlockedAt == null) return 1;
      if (b.unlockedAt == null) return -1;
      return b.unlockedAt!.compareTo(a.unlockedAt!);
    });
    
    return unlockedAchievements.take(limit).toList();
  }

  // Get featured achievement (highest point value or most recent)
  Achievement? getFeaturedAchievement() {
    if (_userAchievements.isEmpty) return null;
    
    // First, try to get a recently unlocked high-value achievement
    final recentHighValue = _userAchievements
        .where((a) => a.isUnlocked && a.points >= 50)
        .toList();
    
    if (recentHighValue.isNotEmpty) {
      recentHighValue.sort((a, b) {
        if (a.unlockedAt == null && b.unlockedAt == null) return b.points.compareTo(a.points);
        if (a.unlockedAt == null) return 1;
        if (b.unlockedAt == null) return -1;
        return b.unlockedAt!.compareTo(a.unlockedAt!);
      });
      return recentHighValue.first;
    }
    
    // Otherwise, get the highest value achievement
    final sorted = List<Achievement>.from(_userAchievements)
      ..sort((a, b) => b.points.compareTo(a.points));
    return sorted.first;
  }

  // Get achievements by category
  List<Achievement> getAchievementsByCategory(String category) {
    if (category == 'All') return _userAchievements;
    return _userAchievements
        .where((achievement) => achievement.category.name == category.toLowerCase())
        .toList();
  }

  // Get achievement progress for a specific game
  Map<String, double> getGameAchievementProgress(String gameId) {
    final gameAchievements = _userAchievements
        .where((a) => a.gameId == gameId)
        .toList();
    
    final progress = <String, double>{};
    for (final achievement in gameAchievements) {
      progress[achievement.id] = achievement.progress / achievement.maxProgress;
    }
    
    return progress;
  }

  // Check for milestone achievements
  Future<void> checkMilestoneAchievements(String userId) async {
    final unlockedCount = getUnlockedCount();
    final totalPoints = getTotalPoints();
    
    // Check for milestone achievements
    await checkAndUnlockAchievement(
      'milestone_5_achievements',
      unlockedCount >= 5 ? 1 : 0,
      userId,
    );
    
    await checkAndUnlockAchievement(
      'milestone_10_achievements',
      unlockedCount >= 10 ? 1 : 0,
      userId,
    );
    
    await checkAndUnlockAchievement(
      'milestone_100_points',
      totalPoints >= 100 ? 1 : 0,
      userId,
    );
    
    await checkAndUnlockAchievement(
      'milestone_500_points',
      totalPoints >= 500 ? 1 : 0,
      userId,
    );
  }

  // Check and unlock specific achievement
  Future<void> checkAndUnlockAchievement(
    String achievementId,
    int progress,
    String userId,
  ) async {
    try {
      final achievementIndex = _userAchievements.indexWhere(
        (achievement) => achievement.id == achievementId,
      );
      
      if (achievementIndex == -1) return;
      
      final achievement = _userAchievements[achievementIndex];
      
      // Update progress
      final updatedAchievement = achievement.copyWith(
        progress: progress,
      );
      
      // Check if achievement should be unlocked
      if (!achievement.isUnlocked && progress >= achievement.maxProgress) {
        final unlockedAchievement = updatedAchievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        
        // Update local list
        _userAchievements[achievementIndex] = unlockedAchievement;
        
        // Update in Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievementId)
            .update(unlockedAchievement.toFirestore());
        
        // Play achievement sound - placeholder until SoundService is enhanced
        // await _soundService.playAchievementSound();
        
        print('Achievement unlocked: ${achievement.title}');
      } else if (achievement.progress != progress) {
        // Update progress only
        _userAchievements[achievementIndex] = updatedAchievement;
        
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievementId)
            .update({'progress': progress});
      }
    } catch (e) {
      print('Error checking achievement $achievementId: $e');
    }
  }
}
