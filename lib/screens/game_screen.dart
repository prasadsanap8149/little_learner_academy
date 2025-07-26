import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../models/game_level.dart';
import '../games/alphabet_matching_game.dart';
import '../games/math_counting_game.dart';
import '../games/animal_science_game.dart';
import '../games/color_matching_game.dart';

class GameScreen extends StatefulWidget {
  final GameLevel level;

  const GameScreen({
    super.key,
    required this.level,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _currentScore = 0;
  bool _gameCompleted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getSubjectColor(widget.level.subject),
              _getSubjectColor(widget.level.subject).withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.level.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.yellow[300],
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Score: $_currentScore',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
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
                    IconButton(
                      onPressed: () {
                        // TODO: Pause/Settings
                      },
                      icon: const Icon(
                        Icons.pause,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Game Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildGameWidget(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameWidget() {
    switch (widget.level.id) {
      case 'math_count_1':
        return MathCountingGame(
          level: widget.level,
          onScoreUpdate: _updateScore,
          onGameComplete: _completeGame,
        );
      case 'lang_alphabet_1':
        return AlphabetMatchingGame(
          level: widget.level,
          onScoreUpdate: _updateScore,
          onGameComplete: _completeGame,
        );
      case 'science_animals_1':
        return AnimalScienceGame(
          level: widget.level,
          onScoreUpdate: _updateScore,
          onGameComplete: _completeGame,
        );
      case 'general_colors_1':
        return ColorMatchingGame(
          level: widget.level,
          onScoreUpdate: _updateScore,
          onGameComplete: _completeGame,
        );
      default:
        return _buildDefaultGame();
    }
  }

  Widget _buildDefaultGame() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Game Coming Soon!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'This exciting game is being prepared for you.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _completeGame(50), // Give some participation points
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSubjectColor(widget.level.subject),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Continue Learning'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateScore(int points) {
    setState(() {
      _currentScore += points;
    });
  }

  void _completeGame(int finalScore) async {
    if (_gameCompleted) return;
    
    setState(() {
      _gameCompleted = true;
      _currentScore = finalScore;
    });

    // Update progress
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.updateProgress(widget.level.id, finalScore);

    // Show completion dialog
    if (mounted) {
      _showCompletionDialog(finalScore);
    }
  }

  void _showCompletionDialog(int score) {
    final stars = _calculateStars(score);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.celebration,
                size: 64,
                color: _getSubjectColor(widget.level.subject),
              ),
              const SizedBox(height: 16),
              Text(
                'Great Job!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You earned $score points!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 32,
                )),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Go back to home
                      },
                      child: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        // Restart the game
                        setState(() {
                          _gameCompleted = false;
                          _currentScore = 0;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getSubjectColor(widget.level.subject),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Play Again'),
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
}
