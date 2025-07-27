import 'package:cloud_firestore/cloud_firestore.dart';

enum GameAccessLevel { free, premium }

class Game {
  final String id;
  final String name;
  final String description;
  final String category; // e.g., 'math', 'language', 'science'
  final String imageUrl;
  final GameAccessLevel accessLevel;
  final int ageMin;
  final int ageMax;
  final Map<String, dynamic> gameData;
  final bool isActive;

  Game({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.accessLevel,
    required this.ageMin,
    required this.ageMax,
    required this.gameData,
    this.isActive = true,
  });

  factory Game.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      accessLevel: data['isPremium'] == true
          ? GameAccessLevel.premium
          : GameAccessLevel.free,
      ageMin: data['ageMin'] ?? 3,
      ageMax: data['ageMax'] ?? 12,
      gameData: data['gameData'] ?? {},
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'isPremium': accessLevel == GameAccessLevel.premium,
      'ageMin': ageMin,
      'ageMax': ageMax,
      'gameData': gameData,
      'isActive': isActive,
    };
  }
}
