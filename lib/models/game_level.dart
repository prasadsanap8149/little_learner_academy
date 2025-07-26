import 'age_group.dart';

enum Subject {
  math('Math', '🔢', 'Numbers and problem solving'),
  language('Language', '📚', 'Reading and vocabulary'),
  science('Science', '🔬', 'Explore the world around us'),
  general('General', '🌟', 'Fun facts and knowledge');

  const Subject(this.name, this.icon, this.description);

  final String name;
  final String icon;
  final String description;
}

enum GameType {
  matching('Matching', 'Match similar items'),
  puzzle('Puzzle', 'Solve fun puzzles'),
  adventure('Adventure', 'Go on learning adventures'),
  quiz('Quiz', 'Test your knowledge');

  const GameType(this.name, this.description);

  final String name;
  final String description;
}

class GameLevel {
  final String id;
  final String title;
  final Subject subject;
  final AgeGroup ageGroup;
  final GameType gameType;
  final int difficulty; // 1-5
  final List<String> objectives;
  final int maxScore;
  final bool isUnlocked;

  GameLevel({
    required this.id,
    required this.title,
    required this.subject,
    required this.ageGroup,
    required this.gameType,
    required this.difficulty,
    required this.objectives,
    required this.maxScore,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject.name,
      'ageGroup': ageGroup.name,
      'gameType': gameType.name,
      'difficulty': difficulty,
      'objectives': objectives,
      'maxScore': maxScore,
      'isUnlocked': isUnlocked,
    };
  }

  factory GameLevel.fromJson(Map<String, dynamic> json) {
    return GameLevel(
      id: json['id'],
      title: json['title'],
      subject: Subject.values.firstWhere((s) => s.name == json['subject']),
      ageGroup: AgeGroup.values.firstWhere((a) => a.name == json['ageGroup']),
      gameType: GameType.values.firstWhere((g) => g.name == json['gameType']),
      difficulty: json['difficulty'],
      objectives: List<String>.from(json['objectives']),
      maxScore: json['maxScore'],
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}
