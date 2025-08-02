import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../services/sound_service.dart';
import '../services/offline_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  final AchievementService _achievementService = AchievementService();
  final SoundService _soundService = SoundService();
  
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late AnimationController _topBarAnimationController;
  late Animation<double> _headerScaleAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _topBarSlideAnimation;
  
  String _selectedCategory = 'All';
  bool _showUnlockedOnly = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAchievements();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _topBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _topBarSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _topBarAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _topBarAnimationController.forward();
    _headerAnimationController.forward();
    _cardsAnimationController.forward();
  }

  Future<void> _loadAchievements() async {
    await _achievementService.initializeAchievements();
    setState(() {});
  }

  // Get filtered achievements based on category and unlock status
  List<Achievement> _getFilteredAchievements() {
    var achievements = _selectedCategory == 'All' 
        ? _achievementService.userAchievements
        : _achievementService.userAchievements.where((a) => 
            a.category.toString().split('.').last.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    
    if (_showUnlockedOnly) {
      achievements = achievements.where((a) => a.isUnlocked).toList();
    }
    
    return achievements;
  }

  // Top Achievement Bar showing recent unlocks and featured achievements
  Widget _buildTopAchievementBar(bool isPhone, bool isTablet) {
    final recentAchievements = _achievementService.getRecentlyUnlockedAchievements(limit: 3);
    final featuredAchievement = _achievementService.getFeaturedAchievement();
    
    return AnimatedBuilder(
      animation: _topBarSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _topBarSlideAnimation.value)),
          child: Opacity(
            opacity: _topBarSlideAnimation.value,
            child: Container(
              height: isPhone ? 120 : 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF8BC34A),
                    const Color(0xFFCDDC39),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      
                      // Title and recent achievements
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Achievements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isPhone ? 20 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (recentAchievements.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Latest: ${recentAchievements.first.title}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isPhone ? 12 : 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Featured achievement or progress
                      if (featuredAchievement != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.yellow[300],
                                size: isPhone ? 20 : 24,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isPhone ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Quick stats
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_achievementService.getUnlockedCount()}/${_achievementService.getTotalCount()}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isPhone ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Enhanced filter section with category tabs
  Widget _buildEnhancedFilterSection(double horizontalPadding, bool isPhone) {
    final categories = ['All', 'Math', 'Language', 'Science', 'General'];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          // Category tabs
          Container(
            height: isPhone ? 40 : 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: MaterialButton(
                    onPressed: () {
                      _soundService.playClick();
                      setState(() => _selectedCategory = category);
                    },
                    padding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 16 : 20,
                      vertical: isPhone ? 8 : 10,
                    ),
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                    elevation: isSelected ? 4 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF6B73FF) : Colors.white,
                        fontSize: isPhone ? 12 : 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filter toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showUnlockedOnly ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: isPhone ? 16 : 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showUnlockedOnly ? 'Unlocked Only' : 'Show All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isPhone ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _showUnlockedOnly,
                      onChanged: (value) {
                        _soundService.playClick();
                        setState(() => _showUnlockedOnly = value);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.3),
                      inactiveThumbColor: Colors.white.withOpacity(0.7),
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Enhanced responsive breakpoints
    final isPhone = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    final isLargeTablet = screenWidth >= 800 && screenWidth < 1200;
    
    // Dynamic spacing based on screen size
    final horizontalPadding = isPhone ? 16.0 : isTablet ? 24.0 : 32.0;
    final verticalSpacing = isPhone ? 12.0 : isTablet ? 16.0 : 20.0;
    
    final achievements = _getFilteredAchievements();

    return Scaffold(
      body: OfflineWidget(
        child: Column(
          children: [
            // Top Achievement Bar
            _buildTopAchievementBar(isPhone, isTablet),
            
            // Main Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B73FF), Color(0xFF9A8EFF)],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // Offline Banner
                      const OfflineBanner(),
                      
                      // Header with statistics
                      SlideTransition(
                        position: _headerSlideAnimation,
                        child: ScaleTransition(
                          scale: _headerScaleAnimation,
                          child: _buildHeader(horizontalPadding, isPhone, isTablet),
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Enhanced Filter Section
                      _buildEnhancedFilterSection(horizontalPadding, isPhone),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Achievements grid
                      Expanded(
                        child: achievements.isEmpty
                            ? _buildEmptyState(isPhone)
                            : _buildAchievementsGrid(
                                achievements, 
                                horizontalPadding, 
                                verticalSpacing,
                                isPhone,
                                isTablet,
                                isDesktop,
                                isLargeTablet
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double horizontalPadding, bool isPhone, bool isTablet) {
    final totalPoints = _achievementService.getTotalPoints();
    final unlockedCount = _achievementService.getUnlockedCount();
    final totalCount = _achievementService.getTotalCount();
    final progressPercentage = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    // Responsive sizing
    final headerPadding = isPhone ? 20.0 : isTablet ? 28.0 : 32.0;
    final iconSize = isPhone ? 60.0 : isTablet ? 80.0 : 100.0;
    final titleFontSize = isPhone ? 14.0 : isTablet ? 16.0 : 18.0;
    final valueFontSize = isPhone ? 16.0 : isTablet ? 18.0 : 20.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      padding: EdgeInsets.all(headerPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Trophy icon with enhanced design
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                  Color(0xFFFF8C00),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              Icons.emoji_events,
              size: iconSize * 0.5,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: isPhone ? 20 : 24),
          
          // Statistics with enhanced layout
          Wrap(
            spacing: isPhone ? 16 : 24,
            runSpacing: isPhone ? 16 : 20,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Achievements',
                '$unlockedCount/$totalCount',
                Icons.star_rounded,
                const Color(0xFF6B73FF),
                isPhone,
                titleFontSize,
                valueFontSize,
              ),
              _buildStatCard(
                'Total Points',
                '$totalPoints',
                Icons.score_rounded,
                const Color(0xFF50C878),
                isPhone,
                titleFontSize,
                valueFontSize,
              ),
              _buildStatCard(
                'Progress',
                '${(progressPercentage * 100).round()}%',
                Icons.trending_up_rounded,
                const Color(0xFFFF6B6B),
                isPhone,
                titleFontSize,
                valueFontSize,
              ),
            ],
          ),
          
          SizedBox(height: isPhone ? 20 : 24),
          
          // Enhanced progress bar
          Container(
            padding: EdgeInsets.all(isPhone ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${(progressPercentage * 100).round()}%',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6B73FF),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isPhone ? 8 : 12),
                Container(
                  height: isPhone ? 8 : 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B73FF), Color(0xFF9A8EFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isPhone, double titleFontSize, double valueFontSize) {
    final cardPadding = isPhone ? 12.0 : 16.0;
    final iconSize = isPhone ? 20.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isPhone ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: isPhone ? 8 : 10),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: isPhone ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: titleFontSize - 2,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons(double horizontalPadding, bool isPhone) {
    final buttonHeight = isPhone ? 44.0 : 48.0;
    final fontSize = isPhone ? 14.0 : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              'All Achievements',
              !_showUnlockedOnly,
              () {
                _soundService.playClick();
                setState(() => _showUnlockedOnly = false);
              },
              buttonHeight,
              fontSize,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterButton(
              'Unlocked Only',
              _showUnlockedOnly,
              () {
                _soundService.playClick();
                setState(() => _showUnlockedOnly = true);
              },
              buttonHeight,
              fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onTap, double height, double fontSize) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? const Color(0xFF6B73FF) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsGrid(
    List<Achievement> achievements, 
    double horizontalPadding, 
    double verticalSpacing,
    bool isPhone,
    bool isTablet,
    bool isDesktop,
    bool isLargeTablet
  ) {
    // Responsive grid configuration
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (isDesktop) {
      crossAxisCount = 4;
      childAspectRatio = 0.85;
      crossAxisSpacing = 24;
      mainAxisSpacing = 24;
    } else if (isLargeTablet) {
      crossAxisCount = 3;
      childAspectRatio = 0.8;
      crossAxisSpacing = 20;
      mainAxisSpacing = 20;
    } else if (isTablet) {
      crossAxisCount = 3;
      childAspectRatio = 0.75;
      crossAxisSpacing = 16;
      mainAxisSpacing = 16;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.9;
      crossAxisSpacing = 12;
      mainAxisSpacing = 16;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return AnimatedBuilder(
            animation: _cardsAnimationController,
            builder: (context, child) {
              final delay = index * 0.1;
              final animationValue = Curves.easeOutBack.transform(
                ((_cardsAnimationController.value - delay).clamp(0.0, 1.0)),
              );
              
              return Transform.scale(
                scale: animationValue,
                child: _buildAchievementCard(achievement, isPhone, isTablet),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isPhone, bool isTablet) {
    // Responsive sizing
    final cardPadding = isPhone ? 16.0 : isTablet ? 20.0 : 24.0;
    final iconSize = isPhone ? 50.0 : isTablet ? 60.0 : 70.0;
    final titleFontSize = isPhone ? 14.0 : isTablet ? 15.0 : 16.0;
    final subtitleFontSize = isPhone ? 12.0 : isTablet ? 13.0 : 14.0;
    final borderRadius = isPhone ? 20.0 : 24.0;

    return GestureDetector(
      onTap: () {
        _soundService.playClick();
        _showAchievementDetails(achievement);
      },
      child: Container(
        decoration: BoxDecoration(
          color: achievement.isUnlocked ? Colors.white : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: achievement.isUnlocked 
                ? const Color(0xFFFFD700).withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: achievement.isUnlocked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: achievement.isUnlocked
                  ? const Color(0xFFFFD700).withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
              blurRadius: achievement.isUnlocked ? 20 : 15,
              offset: const Offset(0, 8),
              spreadRadius: achievement.isUnlocked ? 2 : 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Achievement icon with enhanced design
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: achievement.isUnlocked
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFA500),
                            Color(0xFFFF8C00),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey[300]!,
                            Colors.grey[400]!,
                            Colors.grey[500]!,
                          ],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: achievement.isUnlocked ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: iconSize * 0.4,
                      shadows: achievement.isUnlocked ? [
                        const Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ] : null,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: isPhone ? 12 : 16),
              
              // Achievement title with better typography
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: achievement.isUnlocked
                      ? const Color(0xFF2D3748)
                      : Colors.grey[600],
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: isPhone ? 8 : 12),
              
              // Progress or points with enhanced design
              if (achievement.isUnlocked) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? 10 : 12,
                    vertical: isPhone ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF50C878), Color(0xFF32CD32)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF50C878).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${achievement.points}',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Enhanced progress bar for locked achievements
                Container(
                  padding: EdgeInsets.all(isPhone ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${achievement.progress}/${achievement.maxProgress}',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isPhone ? 4 : 6),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.grey[300],
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: achievement.progressPercentage,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6B73FF), Color(0xFF9A8EFF)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Lock indicator with enhanced design
              if (!achievement.isUnlocked) ...[
                SizedBox(height: isPhone ? 6 : 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: isPhone ? 14 : 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isPhone) {
    final iconSize = isPhone ? 80.0 : 100.0;
    final titleFontSize = isPhone ? 18.0 : 22.0;
    final subtitleFontSize = isPhone ? 14.0 : 16.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: iconSize * 0.6,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isPhone ? 16 : 20),
          Text(
            'No achievements found',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isPhone ? 8 : 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isPhone ? 32 : 48),
            child: Text(
              _showUnlockedOnly
                  ? 'Complete games to unlock achievements!'
                  : 'Start playing to earn achievements!',
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.white.withOpacity(0.8),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8F9FA)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Achievement icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: achievement.isUnlocked
                      ? const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        )
                      : LinearGradient(
                          colors: [Colors.grey[400]!, Colors.grey[600]!],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (achievement.isUnlocked 
                          ? const Color(0xFFFFD700) 
                          : Colors.grey[400]!).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Achievement title
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Achievement description
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Progress and points
              if (achievement.isUnlocked) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF50C878).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Color(0xFF50C878),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${achievement.points} points earned',
                        style: const TextStyle(
                          color: Color(0xFF50C878),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlocked on ${_formatDate(achievement.unlockedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ] else ...[
                // Progress for locked achievements
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${achievement.progress}/${achievement.maxProgress}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B73FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: achievement.progressPercentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
                      minHeight: 8,
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B73FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    super.dispose();
  }
}
