import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_level.dart';
import '../widgets/answer_options_grid.dart';

class AnimalScienceGame extends StatefulWidget {
  final GameLevel level;
  final Function(int) onScoreUpdate;
  final Function(int) onGameComplete;

  const AnimalScienceGame({
    super.key,
    required this.level,
    required this.onScoreUpdate,
    required this.onGameComplete,
  });

  @override
  State<AnimalScienceGame> createState() => _AnimalScienceGameState();
}

class _AnimalScienceGameState extends State<AnimalScienceGame>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _animalAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _animalBounceAnimation;

  int _currentQuestion = 0;
  int _score = 0;
  final int _totalQuestions = 8;
  final List<AnimalQuestion> _questions = [];
  String? _selectedAnswer;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateQuestions();
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animalAnimationController = AnimationController(
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

    _cardSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));

    _animalBounceAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _animalAnimationController,
      curve: Curves.easeInOut,
    ));

    _cardAnimationController.forward();
    _animalAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _animalAnimationController.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final animals = [
      AnimalData('🐶', 'Dog', 'Woof!'),
      AnimalData('🐱', 'Cat', 'Meow!'),
      AnimalData('🐮', 'Cow', 'Moo!'),
      AnimalData('🐷', 'Pig', 'Oink!'),
      AnimalData('🐸', 'Frog', 'Ribbit!'),
      AnimalData('🐔', 'Chicken', 'Cluck!'),
      AnimalData('🐴', 'Horse', 'Neigh!'),
      AnimalData('🐑', 'Sheep', 'Baa!'),
      AnimalData('🦆', 'Duck', 'Quack!'),
      AnimalData('🐺', 'Wolf', 'Howl!'),
    ];

    final random = Random();
    _questions.clear();

    for (int i = 0; i < _totalQuestions; i++) {
      final correctAnimal = animals[random.nextInt(animals.length)];

      // Generate wrong options
      Set<String> soundOptions = {correctAnimal.sound};
      while (soundOptions.length < 4) {
        final wrongAnimal = animals[random.nextInt(animals.length)];
        if (wrongAnimal.sound != correctAnimal.sound) {
          soundOptions.add(wrongAnimal.sound);
        }
      }

      List<String> shuffledOptions = soundOptions.toList()..shuffle();

      _questions.add(AnimalQuestion(
        animal: correctAnimal,
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
          ),
          const SizedBox(height: 20),

          // Question
          Text(
            'What sound does this animal make?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Animal display with animations
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
                        colors: [Colors.green[50]!, Colors.green[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green[200]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
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
                              animation: _animalAnimationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset:
                                      Offset(0, _animalBounceAnimation.value),
                                  child: Text(
                                    question.animal.emoji,
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
                              question.animal.name,
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

          // Answer options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: AnswerOptionsGrid<String>(
              options: question.options
                  .map((option) => AnswerOption<String>(value: option))
                  .toList(),
              selectedAnswer: _selectedAnswer,
              correctAnswer: question.animal.sound,
              showResult: _showResult,
              onOptionSelected: _selectAnswer,
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
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
                  backgroundColor: const Color(0xFF2ECC71),
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

    if (answer == _questions[_currentQuestion].animal.sound) {
      _score += 20;
      widget.onScoreUpdate(20);
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion++;
      _selectedAnswer = null;
      _showResult = false;
    });
  }
}

class AnimalData {
  final String emoji;
  final String name;
  final String sound;

  AnimalData(this.emoji, this.name, this.sound);
}

class AnimalQuestion {
  final AnimalData animal;
  final List<String> options;

  AnimalQuestion({
    required this.animal,
    required this.options,
  });
}
