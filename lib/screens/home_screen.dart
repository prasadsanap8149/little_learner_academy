import 'package:flutter/material.dart';
import 'package:little_learners_academy/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../models/game_level.dart';
import '../models/age_group.dart';
import '../widgets/level_card.dart';
import '../widgets/progress_card.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Ensure player data is loaded from Firebase if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      gameProvider.loadPlayerFromFirebase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final player = gameProvider.gameService.currentPlayer;
        final availableLevels = gameProvider.gameService.getAvailableLevels();

        if (player == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6B73FF),
                  Color(0xFFF8F9FA),
                ],
                stops: [0.0, 0.3],
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
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: Text(
                            player.playerName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B73FF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${player.playerName}!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                '${AgeGroup.fromAge(player.age).displayName} • ${player.totalStars} ⭐',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // TODO: Settings screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ProgressCard(player: player),
                  ),

                  const SizedBox(height: 20),

                  // Subject Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF6B73FF),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF6B73FF),
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      tabs: Subject.values
                          .map((subject) => Tab(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(subject.icon,
                                          style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          subject.name,
                                          style: const TextStyle(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: Subject.values.map((subject) {
                        final subjectLevels = availableLevels
                            .where((level) => level.subject == subject)
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: subjectLevels.isEmpty
                              ? Center(
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
                                        'Coming Soon!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'More ${subject.name} games are being prepared for you.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.grey[500],
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.85,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: subjectLevels.length,
                                  itemBuilder: (context, index) {
                                    final level = subjectLevels[index];
                                    final categoryId =
                                        level.id.split('_').take(2).join('_');
                                    final categoryProgress =
                                        player.categories[categoryId];
                                    final levelProgress =
                                        categoryProgress?.levels[level.id];

                                    return LevelCard(
                                      level: level,
                                      isCompleted:
                                          levelProgress?.isCompleted ?? false,
                                      score: levelProgress?.highScore ?? 0,
                                      stars: levelProgress?.stars ?? 0,
                                      onTap: () => _playLevel(level),
                                    );
                                  },
                                ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _playLevel(GameLevel level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(level: level),
      ),
    );
  }
}
