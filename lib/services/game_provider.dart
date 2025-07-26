import 'package:flutter/material.dart';
import 'game_service.dart';

class GameProvider extends ChangeNotifier {
  final GameService _gameService = GameService();
  bool _isLoading = true;
  
  GameService get gameService => _gameService;
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
}
