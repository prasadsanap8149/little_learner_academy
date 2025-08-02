import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_level.dart';
import '../widgets/answer_options_grid.dart';
import '../services/sound_service.dart';

class AlphabetMatchingGame extends StatefulWidget {
  final GameLevel level;
  final Function(int) onScoreUpdate;
  final Function(int) onGameComplete;

  const AlphabetMatchingGame({
    super.key,
    required this.level,
    required this.onScoreUpdate,
    required this.onGameComplete,
  });

  @override
  State<AlphabetMatchingGame> createState() => _AlphabetMatchingGameState();
}

class _AlphabetMatchingGameState extends State<AlphabetMatchingGame>
    with TickerProviderStateMixin {
  final SoundService _soundService = SoundService();
  int _currentQuestion = 0;
  int _score = 0;
  final int _totalQuestions = 8; // Increased from 5 to 8
  final List<AlphabetQuestion> _questions = [];
  String? _selectedAnswer;
  bool _showResult = false;

  late AnimationController _cardAnimationController;
  late AnimationController _emojiAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _emojiRotationAnimation;
  late Animation<double> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateQuestions();
    _initializeSoundService();
  }
  
  Future<void> _initializeSoundService() async {
    try {
      await _soundService.initialize();
    } catch (e) {
      print('Error initializing sound service: $e');
    }
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _emojiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _emojiRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _emojiAnimationController,
      curve: Curves.bounceIn,
    ));

    _cardSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));

    _cardAnimationController.forward();
    _emojiAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _emojiAnimationController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    final words = {
      'A': ['🍎', 'Apple'],
      'B': ['🎈', 'Balloon'],
      'C': ['🐱', 'Cat'],
      'D': ['🐶', 'Dog'],
      'E': ['🐘', 'Elephant'],
      'F': ['🐸', 'Frog'],
      'G': ['🍇', 'Grapes'],
      'H': ['🏠', 'House'],
      'I': ['🍦', 'Ice Cream'],
      'J': ['🧩', 'Jigsaw'],
      'K': ['🔑', 'Key'],
      'L': ['🦁', 'Lion'],
      'M': ['🐵', 'Monkey'],
      'N': ['🌙', 'Night'],
      'O': ['🐙', 'Octopus'],
      'P': ['🐷', 'Pig'],
      'Q': ['👑', 'Queen'],
      'R': ['🌈', 'Rainbow'],
      'S': ['☀️', 'Sun'],
      'T': ['🐅', 'Tiger'],
      'U': ['☂️', 'Umbrella'],
      'V': ['🎻', 'Violin'],
      'W': ['🐳', 'Whale'],
      'X': ['❌', 'X-ray'],
      'Y': ['💛', 'Yellow'],
      'Z': ['🦓', 'Zebra'],
    };

    final random = Random();
    _questions.clear();

    for (int i = 0; i < _totalQuestions; i++) {
      final correctLetter = letters[random.nextInt(letters.length)];
      final wordData = words[correctLetter]!;

      // Generate wrong options
      Set<String> options = {correctLetter};
      while (options.length < 4) {
        final wrongLetter = letters[random.nextInt(letters.length)];
        if (wrongLetter != correctLetter) {
          options.add(wrongLetter);
        }
      }

      List<String> shuffledOptions = options.toList()..shuffle();

      _questions.add(AlphabetQuestion(
        emoji: wordData[0],
        word: wordData[1],
        correctLetter: correctLetter,
        options: shuffledOptions,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentQuestion >= _totalQuestions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _soundService.playLevelComplete();
        } catch (e) {
          print('Error playing level complete sound: $e');
        }
        widget.onGameComplete(_score);
      });
      return const Center(child: CircularProgressIndicator());
    }

    final question = _questions[_currentQuestion];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestion + 1) / _totalQuestions,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B59B6)),
          ),
          const SizedBox(height: 20),

          // Question
          Text(
            'What letter does this start with?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
          ),
          const SizedBox(height: 20),

          // Image and word with animations
          AnimatedBuilder(
            animation: _cardAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _cardSlideAnimation.value),
                child: Transform.scale(
                  scale: _cardScaleAnimation.value,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.25,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple[50]!, Colors.purple[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple[200]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            flex: 3,
                            child: AnimatedBuilder(
                              animation: _emojiAnimationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _emojiRotationAnimation.value *
                                      2 *
                                      3.14159,
                                  child: Text(
                                    question.emoji,
                                    style: const TextStyle(
                                      fontSize: 80,
                                      height: 1.0,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            flex: 1,
                            child: Text(
                              question.word,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C3E50),
                                    fontSize: 24,
                                  ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Answer options with animations
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: AnswerOptionsGrid<String>(
              options: question.options
                  .map((option) => AnswerOption<String>(value: option))
                  .toList(),
              selectedAnswer: _selectedAnswer,
              correctAnswer: question.correctLetter,
              showResult: _showResult,
              onOptionSelected: _selectAnswer,
              textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
            ),
          ),

          const SizedBox(height: 20),

          // Next button
          if (_showResult)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B59B6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _currentQuestion + 1 < _totalQuestions
                      ? 'Next Question'
                      : 'Finish',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswer = answer;
      _showResult = true;
    });

    if (answer == _questions[_currentQuestion].correctLetter) {
      _score += 20;
      widget.onScoreUpdate(20);
      try {
        _soundService.playSuccess();
        _soundService.playLetterSound(); // Play letter pronunciation
      } catch (e) {
        print('Error playing success/letter sound: $e');
      }
    } else {
      try {
        _soundService.playError();
      } catch (e) {
        print('Error playing error sound: $e');
      }
    }
  }

  void _nextQuestion() {
    try {
      _soundService.playClick();
    } catch (e) {
      print('Error playing click sound: $e');
    }
    
    setState(() {
      _currentQuestion++;
      _selectedAnswer = null;
      _showResult = false;
    });

    // Restart animations for the new question
    _cardAnimationController.reset();
    _cardAnimationController.forward();
  }
}

class AlphabetQuestion {
  final String emoji;
  final String word;
  final String correctLetter;
  final List<String> options;

  AlphabetQuestion({
    required this.emoji,
    required this.word,
    required this.correctLetter,
    required this.options,
  });
}
