import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType {
  firstGame,      // Complete first game
  streakMaster,   // 5 games in a row
  subjectExpert,  // Complete all games in a subject
  speedRunner,    // Complete game under time limit
  perfectionist,  // Get 3 stars on 10 games
  explorer,       // Try all game types
  dedication,     // Play for 7 consecutive days
  mathWizard,     // Complete all math games
  wordMaster,     // Complete all language games
  scientist,      // Complete all science games
  scholar,        // Complete all general knowledge games
  youngLearner,   // Unlock all age group content
}

class Achievement {
  final String id;
  final AchievementType type;
  final String title;
  final String description;
  final String icon;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int maxProgress;

  const Achievement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    required this.maxProgress,
  });

  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Achievement(
      id: doc.id,
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == 'AchievementType.${data['type']}',
        orElse: () => AchievementType.firstGame,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      points: data['points'] ?? 0,
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      progress: data['progress'] ?? 0,
      maxProgress: data['maxProgress'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'icon': icon,
      'points': points,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt,
      'progress': progress,
      'maxProgress': maxProgress,
    };
  }

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
  }) {
    return Achievement(
      id: id,
      type: type,
      title: title,
      description: description,
      icon: icon,
      points: points,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      maxProgress: maxProgress,
    );
  }

  double get progressPercentage => maxProgress > 0 ? progress / maxProgress : 0.0;

  // Static method to create default achievements
  static List<Achievement> getDefaultAchievements() {
    return [
      const Achievement(
        id: 'first_game',
        type: AchievementType.firstGame,
        title: 'First Steps',
        description: 'Complete your first game',
        icon: '🌟',
        points: 10,
        maxProgress: 1,
      ),
      const Achievement(
        id: 'streak_master',
        type: AchievementType.streakMaster,
        title: 'Streak Master',
        description: 'Complete 5 games in a row',
        icon: '🔥',
        points: 50,
        maxProgress: 5,
      ),
      const Achievement(
        id: 'math_expert',
        type: AchievementType.subjectExpert,
        title: 'Math Expert',
        description: 'Complete all math games',
        icon: '🧮',
        points: 100,
        maxProgress: 8, // Adjust based on actual math games count
      ),
      const Achievement(
        id: 'speed_runner',
        type: AchievementType.speedRunner,
        title: 'Speed Runner',
        description: 'Complete a game in under 2 minutes',
        icon: '⚡',
        points: 30,
        maxProgress: 1,
      ),
      const Achievement(
        id: 'perfectionist',
        type: AchievementType.perfectionist,
        title: 'Perfectionist',
        description: 'Get 3 stars on 10 different games',
        icon: '⭐',
        points: 75,
        maxProgress: 10,
      ),
      const Achievement(
        id: 'explorer',
        type: AchievementType.explorer,
        title: 'Explorer',
        description: 'Try all game types',
        icon: '🗺️',
        points: 40,
        maxProgress: 4, // Math, Language, Science, General Knowledge
      ),
      const Achievement(
        id: 'dedication',
        type: AchievementType.dedication,
        title: 'Dedication',
        description: 'Play for 7 consecutive days',
        icon: '📅',
        points: 60,
        maxProgress: 7,
      ),
      const Achievement(
        id: 'math_wizard',
        type: AchievementType.mathWizard,
        title: 'Math Wizard',
        description: 'Master all math challenges',
        icon: '🧙‍♂️',
        points: 150,
        maxProgress: 8,
      ),
      const Achievement(
        id: 'word_master',
        type: AchievementType.wordMaster,
        title: 'Word Master',
        description: 'Complete all language games',
        icon: '📚',
        points: 150,
        maxProgress: 8,
      ),
      const Achievement(
        id: 'scientist',
        type: AchievementType.scientist,
        title: 'Young Scientist',
        description: 'Explore all science topics',
        icon: '🔬',
        points: 150,
        maxProgress: 6,
      ),
      const Achievement(
        id: 'scholar',
        type: AchievementType.scholar,
        title: 'Scholar',
        description: 'Master general knowledge',
        icon: '🎓',
        points: 150,
        maxProgress: 6,
      ),
      const Achievement(
        id: 'young_learner',
        type: AchievementType.youngLearner,
        title: 'Young Learner',
        description: 'Unlock content for all age groups',
        icon: '👶',
        points: 200,
        maxProgress: 3,
      ),
    ];
  }
}
