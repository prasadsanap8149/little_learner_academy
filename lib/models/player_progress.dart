import 'dart:core';

import 'package:flutter/material.dart';
import 'age_group.dart';

class GameCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const GameCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class LevelProgress {
  final String levelId;
  final int stars; // 0-3 stars based on score
  final int highScore;
  final bool isCompleted;
  final DateTime? lastPlayed;

  const LevelProgress({
    required this.levelId,
    this.stars = 0,
    this.highScore = 0,
    this.isCompleted = false,
    this.lastPlayed,
  });

  LevelProgress copyWith({
    String? levelId,
    int? stars,
    int? highScore,
    bool? isCompleted,
    DateTime? lastPlayed,
  }) {
    return LevelProgress(
      levelId: levelId ?? this.levelId,
      stars: stars ?? this.stars,
      highScore: highScore ?? this.highScore,
      isCompleted: isCompleted ?? this.isCompleted,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'stars': stars,
        'highScore': highScore,
        'isCompleted': isCompleted,
        'lastPlayed': lastPlayed?.toIso8601String(),
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        levelId: json['levelId'],
        stars: json['stars'] ?? 0,
        highScore: json['highScore'] ?? 0,
        isCompleted: json['isCompleted'] ?? false,
        lastPlayed: json['lastPlayed'] != null
            ? DateTime.parse(json['lastPlayed'])
            : null,
      );
}

class CategoryProgress {
  final String categoryId;
  final Map<String, LevelProgress> levels; // levelId -> progress
  final int unlockedLevels;
  final AgeGroup currentAgeGroup;

  const CategoryProgress({
    required this.categoryId,
    required this.levels,
    required this.unlockedLevels,
    required this.currentAgeGroup,
  });

  bool isLevelUnlocked(String levelId) {
    final levelNumber = int.tryParse(levelId.split('_').last) ?? 0;
    return levelNumber <= unlockedLevels;
  }

  CategoryProgress copyWith({
    String? categoryId,
    Map<String, LevelProgress>? levels,
    int? unlockedLevels,
    AgeGroup? currentAgeGroup,
  }) {
    return CategoryProgress(
      categoryId: categoryId ?? this.categoryId,
      levels: levels ?? this.levels,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      currentAgeGroup: currentAgeGroup ?? this.currentAgeGroup,
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'levels': levels.map((key, value) => MapEntry(key, value.toJson())),
        'unlockedLevels': unlockedLevels,
        'currentAgeGroup': currentAgeGroup.toString(),
      };

  factory CategoryProgress.fromJson(Map<String, dynamic> json) =>
      CategoryProgress(
        categoryId: json['categoryId'],
        levels: (json['levels'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, LevelProgress.fromJson(value))),
        unlockedLevels: json['unlockedLevels'] ?? 1,
        currentAgeGroup: AgeGroup.values.firstWhere(
          (e) => e.toString() == json['currentAgeGroup'],
          orElse: () => AgeGroup.littleTots,
        ),
      );
}

class PlayerProgress {
  final String playerId;
  final String playerName;
  final int age;
  final Map<String, CategoryProgress> categories; // categoryId -> progress
  final List<String> achievements;
  final int totalStars;
  final DateTime lastPlayed;
  final AgeGroup highestUnlockedAgeGroup;

  const PlayerProgress({
    required this.playerId,
    required this.playerName,
    required this.age,
    required this.categories,
    required this.achievements,
    required this.totalStars,
    required this.lastPlayed,
    required this.highestUnlockedAgeGroup,
  });

  bool isCategoryUnlocked(GameCategory category, AgeGroup ageGroup) {
    if (ageGroup.index <= highestUnlockedAgeGroup.index) {
      return true;
    }
    // Check if previous age group's category is completed
    if (ageGroup.index > 0) {
      final previousAgeGroup = AgeGroup.values[ageGroup.index - 1];
      final categoryProgress = categories[category.id];
      if (categoryProgress != null &&
          categoryProgress.currentAgeGroup == previousAgeGroup) {
        return categoryProgress.levels.values
            .every((level) => level.isCompleted);
      }
    }
    return false;
  }

  PlayerProgress copyWith({
    String? playerId,
    String? playerName,
    int? age,
    Map<String, CategoryProgress>? categories,
    List<String>? achievements,
    int? totalStars,
    DateTime? lastPlayed,
    AgeGroup? highestUnlockedAgeGroup,
  }) {
    return PlayerProgress(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      age: age ?? this.age,
      categories: categories ?? this.categories,
      achievements: achievements ?? this.achievements,
      totalStars: totalStars ?? this.totalStars,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      highestUnlockedAgeGroup:
          highestUnlockedAgeGroup ?? this.highestUnlockedAgeGroup,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'playerName': playerName,
        'age': age,
        'categories':
            categories.map((key, value) => MapEntry(key, value.toJson())),
        'achievements': achievements,
        'totalStars': totalStars,
        'lastPlayed': lastPlayed.toIso8601String(),
        'highestUnlockedAgeGroup': highestUnlockedAgeGroup.toString(),
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) => PlayerProgress(
        playerId: json['playerId'],
        playerName: json['playerName'],
        age: json['age'],
        categories: (json['categories'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, CategoryProgress.fromJson(value))),
        achievements: List<String>.from(json['achievements'] ?? []),
        totalStars: json['totalStars'] ?? 0,
        lastPlayed: DateTime.parse(json['lastPlayed']),
        highestUnlockedAgeGroup: AgeGroup.values.firstWhere(
          (e) => e.toString() == json['highestUnlockedAgeGroup'],
          orElse: () => AgeGroup.littleTots,
        ),
      );

  factory PlayerProgress.newPlayer({
    required String playerId,
    required String playerName,
    required int age,
  }) {
    return PlayerProgress(
      playerId: playerId,
      playerName: playerName,
      age: age,
      categories: {},
      achievements: [],
      totalStars: 0,
      lastPlayed: DateTime.now(),
      highestUnlockedAgeGroup: AgeGroup.values[age <= 5
          ? 0
          : age <= 7
              ? 1
              : 2],
    );
  }

  /// Returns a list of all completed level IDs across all categories
  List<String> get completedLevels {
    final completedLevelIds = <String>[];
    for (final categoryProgress in categories.values) {
      for (final levelProgress in categoryProgress.levels.values) {
        if (levelProgress.isCompleted) {
          completedLevelIds.add(levelProgress.levelId);
        }
      }
    }
    return completedLevelIds;
  }

  /// Returns the total number of completed levels
  int get completedLevelsCount => completedLevels.length;

  /// Returns a set of completed level IDs for achievement checking
  Set<String> get completedLevelsSet => completedLevels.toSet();

  /// Update game progress for a specific level
  PlayerProgress updateGameProgress(String levelId, int score, int stars) {
    final updatedCategories = Map<String, CategoryProgress>.from(categories);

    // Find which category this level belongs to
    String? targetCategoryId;
    for (final entry in categories.entries) {
      if (entry.value.levels.containsKey(levelId)) {
        targetCategoryId = entry.key;
        break;
      }
    }

    if (targetCategoryId != null) {
      final categoryProgress = updatedCategories[targetCategoryId]!;
      final currentLevel = categoryProgress.levels[levelId];

      if (currentLevel != null) {
        // Update level progress
        final updatedLevel = currentLevel.copyWith(
          highScore: score > currentLevel.highScore ? score : currentLevel.highScore,
          stars: stars > currentLevel.stars ? stars : currentLevel.stars,
          isCompleted: true,
          lastPlayed: DateTime.now(),
        );

        // Update category progress
        final updatedLevels = Map<String, LevelProgress>.from(categoryProgress.levels);
        updatedLevels[levelId] = updatedLevel;

        final updatedCategoryProgress = categoryProgress.copyWith(
          levels: updatedLevels,
          totalStars: updatedLevels.values.fold(0, (sum, level) => sum + level.stars),
        );

        updatedCategories[targetCategoryId] = updatedCategoryProgress;
      }
    }

    // Calculate new total stars
    final newTotalStars = updatedCategories.values
        .fold(0, (sum, category) => sum + category.totalStars);

    return copyWith(
      categories: updatedCategories,
      totalStars: newTotalStars,
      lastPlayed: DateTime.now(),
    );
  }
}
