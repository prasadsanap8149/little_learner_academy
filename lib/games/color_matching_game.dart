import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_level.dart';
import '../widgets/answer_options_grid.dart';
import '../services/sound_service.dart';

class ColorMatchingGame extends StatefulWidget {
  final GameLevel level;
  final Function(int) onScoreUpdate;
  final Function(int) onGameComplete;

  const ColorMatchingGame({
    super.key,
    required this.level,
    required this.onScoreUpdate,
    required this.onGameComplete,
  });

  @override
  State<ColorMatchingGame> createState() => _ColorMatchingGameState();
}

class _ColorMatchingGameState extends State<ColorMatchingGame>
    with TickerProviderStateMixin {
  final SoundService _soundService = SoundService();
  late AnimationController _cardAnimationController;
  late AnimationController _colorAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _colorPulseAnimation;

  int _currentQuestion = 0;
  int _score = 0;
  final int _totalQuestions = 8;
  final List<ColorQuestion> _questions = [];
  String? _selectedAnswer;
  bool _showResult = false;

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

    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _cardSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));

    _colorPulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));

    _cardAnimationController.forward();
    _colorAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _colorAnimationController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final colors = [
      ColorData('Red', Colors.red, '🍎'),
      ColorData('Blue', Colors.blue, '💙'),
      ColorData('Green', Colors.green, '🍃'),
      ColorData('Yellow', Colors.yellow, '🌞'),
      ColorData('Orange', Colors.orange, '🍊'),
      ColorData('Purple', Colors.purple, '🍇'),
      ColorData('Pink', Colors.pink, '🌸'),
      ColorData('Brown', Colors.brown, '🤎'),
    ];

    final random = Random();
    _questions.clear();

    for (int i = 0; i < _totalQuestions; i++) {
      final correctColor = colors[random.nextInt(colors.length)];

      Set<String> options = {correctColor.name};
      while (options.length < 4) {
        final wrongColor = colors[random.nextInt(colors.length)];
        if (wrongColor.name != correctColor.name) {
          options.add(wrongColor.name);
        }
      }

      List<String> shuffledOptions = options.toList()..shuffle();

      _questions.add(ColorQuestion(
        color: correctColor,
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
          ),
          const SizedBox(height: 20),

          // Question
          Text(
            'What color is this?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Color display with animations
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
                        colors: [Colors.orange[50]!, Colors.orange[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange[200]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
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
                              animation: _colorAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _colorPulseAnimation.value,
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: question.color.color,
                                      borderRadius: BorderRadius.circular(45),
                                      boxShadow: [
                                        BoxShadow(
                                          color: question.color.color
                                              .withOpacity(0.5),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        question.color.emoji,
                                        style: const TextStyle(fontSize: 36),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            flex: 1,
                            child: Text(
                              'Tap the correct color name!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF2C3E50),
                                    fontWeight: FontWeight.w600,
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

          const SizedBox(height: 15),

          // Answer options with animations
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: AnswerOptionsGrid<String>(
              options: question.options
                  .map((option) => AnswerOption<String>(value: option))
                  .toList(),
              selectedAnswer: _selectedAnswer,
              correctAnswer: question.color.name,
              showResult: _showResult,
              onOptionSelected: _selectAnswer,
              textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
            ),
          ),

          const SizedBox(height: 20),

          // Next button
          if (_showResult)
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
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

    if (answer == _questions[_currentQuestion].color.name) {
      _score += 20;
      widget.onScoreUpdate(20);
      try {
        _soundService.playSuccess();
      } catch (e) {
        print('Error playing success sound: $e');
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

class ColorData {
  final String name;
  final Color color;
  final String emoji;

  ColorData(this.name, this.color, this.emoji);
}

class ColorQuestion {
  final ColorData color;
  final List<String> options;

  ColorQuestion({
    required this.color,
    required this.options,
  });
}
