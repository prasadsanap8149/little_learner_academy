import 'package:flutter/material.dart';
import '../models/game_level.dart';

class LevelCard extends StatelessWidget {
  final GameLevel level;
  final bool isCompleted;
  final int score;
  final int stars;
  final VoidCallback onTap;

  const LevelCard({
    super.key,
    required this.level,
    required this.isCompleted,
    required this.score,
    this.stars = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: level.isUnlocked ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: level.isUnlocked ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: level.isUnlocked
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
          border: level.isUnlocked
              ? null
              : Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: level.isUnlocked
                          ? _getSubjectColor(level.subject)
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getGameTypeIcon(level.gameType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (!level.isUnlocked)
                    Icon(
                      Icons.lock,
                      color: Colors.grey[400],
                      size: 20,
                    )
                  else if (isCompleted)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                            5,
                            (index) => Icon(
                                  index < stars
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.orange,
                                  size: 16,
                                )),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                level.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: level.isUnlocked ? Colors.black : Colors.grey[500],
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                level.gameType.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: level.isUnlocked
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: level.isUnlocked
                            ? _getSubjectColor(level.subject).withOpacity(0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Level ${level.difficulty}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: level.isUnlocked
                                  ? _getSubjectColor(level.subject)
                                  : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCompleted && level.isUnlocked)
                    Flexible(
                      child: Text(
                        '$score pts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateStars(int score) {
    if (score >= 90) return 5;
    if (score >= 80) return 4;
    if (score >= 70) return 3;
    if (score >= 60) return 2;
    if (score >= 50) return 1;
    return 0;
  }

  Color _getSubjectColor(Subject subject) {
    switch (subject) {
      case Subject.math:
        return const Color(0xFF6B73FF);
      case Subject.language:
        return const Color(0xFF9B59B6);
      case Subject.science:
        return const Color(0xFF2ECC71);
      case Subject.general:
        return const Color(0xFFF39C12);
    }
  }

  IconData _getGameTypeIcon(GameType gameType) {
    switch (gameType) {
      case GameType.matching:
        return Icons.connect_without_contact;
      case GameType.puzzle:
        return Icons.extension;
      case GameType.adventure:
        return Icons.explore;
      case GameType.quiz:
        return Icons.quiz;
    }
  }
}
