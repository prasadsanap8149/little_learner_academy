import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_level.dart';
import '../models/age_group.dart';
import '../widgets/answer_options_grid.dart';
import '../services/sound_service.dart';

class MathCountingGame extends StatefulWidget {
  final GameLevel level;
  final Function(int) onScoreUpdate;
  final Function(int) onGameComplete;

  const MathCountingGame({
    super.key,
    required this.level,
    required this.onScoreUpdate,
    required this.onGameComplete,
  });

  @override
  State<MathCountingGame> createState() => _MathCountingGameState();
}

class _MathCountingGameState extends State<MathCountingGame>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _cardAnimationController;
  late AnimationController _itemAnimationController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _itemScaleAnimation;

  final SoundService _soundService = SoundService();
  int _currentQuestion = 0;
  int _score = 0;
  final int _totalQuestions = 8; // Increased from 5 to 8

  final List<CountingQuestion> _questions = [];
  int? _selectedAnswer;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateQuestions();
    _soundService.initialize(); // Initialize sound service
  }

  void _initializeAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _itemAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

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

    _itemScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _itemAnimationController,
      curve: Curves.elasticOut,
    ));

    _cardAnimationController.forward();
    _itemAnimationController.forward();
  }

  @override
  @override
  void dispose() {
    _bounceController.dispose();
    _cardAnimationController.dispose();
    _itemAnimationController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final random = Random();
    _questions.clear();

    for (int i = 0; i < _totalQuestions; i++) {
      // Generate counting questions based on age group
      int maxCount = widget.level.ageGroup == AgeGroup.toddler ? 5 : 10;
      int correctAnswer = random.nextInt(maxCount) + 1;

      // Generate wrong answers - ensure correct answer is always included
      Set<int> options = {correctAnswer};
      while (options.length < 4) {
        int wrongAnswer = random.nextInt(maxCount) + 1;
        if (wrongAnswer != correctAnswer && wrongAnswer > 0) {
          options.add(wrongAnswer);
        }
      }

      // Ensure we have exactly 4 options including the correct one
      List<int> shuffledOptions = options.toList();
      if (shuffledOptions.length < 4) {
        // Add more options if needed
        while (shuffledOptions.length < 4) {
          int newOption = random.nextInt(maxCount) + 1;
          if (!shuffledOptions.contains(newOption)) {
            shuffledOptions.add(newOption);
          }
        }
      }
      shuffledOptions.shuffle();

      _questions.add(CountingQuestion(
        animals: _generateAnimals(correctAnswer),
        correctAnswer: correctAnswer,
        options: shuffledOptions,
      ));
    }
  }

  List<String> _generateAnimals(int count) {
    final animals = [
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐸',
      '🐷',
      '🐵',
      '🐴'
    ];
    final random = Random();
    final selectedAnimal = animals[random.nextInt(animals.length)];

    return List.generate(count, (index) => selectedAnimal);
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentQuestion >= _totalQuestions) {
      // Game completed
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
          ),
          const SizedBox(height: 20),

          // Question
          Text(
            'Count the animals!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Animals display with animations
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
                        colors: [Colors.blue[50]!, Colors.blue[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: AnimatedBuilder(
                          animation: _itemAnimationController,
                          builder: (context, child) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children:
                                  question.animals.asMap().entries.map((entry) {
                                final index = entry.key;
                                final animal = entry.value;
                                final delay = index * 0.1;

                                return AnimatedBuilder(
                                  animation: _itemAnimationController,
                                  builder: (context, child) {
                                    final animationValue = Curves.elasticOut
                                        .transform(
                                            (_itemAnimationController.value -
                                                    delay)
                                                .clamp(0.0, 1.0));

                                    return Transform.scale(
                                      scale: animationValue,
                                      child: Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(22.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            animal,
                                            style:
                                                const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // Question text
          Text(
            'How many animals do you see?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2C3E50),
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 5),

          // Answer options
          AnswerOptionsGrid<int>(
            options: question.options
                .map((option) => AnswerOption<int>(value: option))
                .toList(),
            selectedAnswer: _selectedAnswer,
            correctAnswer: question.correctAnswer,
            showResult: _showResult,
            onOptionSelected: _selectAnswer,
          ),

          const SizedBox(height: 10),

          // Next button (shown after answering)
          if (_showResult)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B73FF),
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

  void _selectAnswer(int answer) {
    setState(() {
      _selectedAnswer = answer;
      _showResult = true;
    });

    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    // Check if correct and play appropriate sound
    if (answer == _questions[_currentQuestion].correctAnswer) {
      _score += 20; // 20 points per correct answer
      widget.onScoreUpdate(20);
      _soundService.playSuccess(); // Play success sound
    } else {
      _soundService.playError(); // Play error sound
    }
  }

  void _nextQuestion() {
    _soundService.playClick(); // Play click sound
    setState(() {
      
      _currentQuestion++;
      _selectedAnswer = null;
      _showResult = false;
    });
  }
}

class CountingQuestion {
  final List<String> animals;
  final int correctAnswer;
  final List<int> options;

  CountingQuestion({
    required this.animals,
    required this.correctAnswer,
    required this.options,
  });
}
