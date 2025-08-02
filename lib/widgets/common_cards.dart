import 'package:flutter/material.dart';
import '../services/ui_service.dart';
import '../services/sound_service.dart';

class GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isLocked;
  final int? completedLevels;
  final int? totalLevels;
  final bool isOffline;

  const GameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
    this.isLocked = false,
    this.completedLevels,
    this.totalLevels,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = UIHelpers.isPhone(context);
    final cardColor = color ?? UIConstants.primaryColor;
    
    return UIWidgets.buildCard(
      onTap: isLocked ? null : () {
        SoundService().playClick();
        onTap?.call();
      },
      child: Container(
        height: isPhone ? 160 : 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLocked 
                ? [Colors.grey[400]!, Colors.grey[500]!]
                : [cardColor, cardColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(UIConstants.radiusL),
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(UIConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and offline indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(UIConstants.spacingS),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(UIConstants.radiusM),
                        ),
                        child: Icon(
                          isLocked ? Icons.lock : icon,
                          color: Colors.white,
                          size: isPhone ? 24 : 28,
                        ),
                      ),
                      if (isOffline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: UIConstants.spacingS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(UIConstants.radiusS),
                          ),
                          child: Text(
                            'Offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isPhone ? 10 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Title and subtitle
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isPhone ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isPhone ? 12 : 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Progress bar
                  if (completedLevels != null && totalLevels != null) ...[
                    const SizedBox(height: UIConstants.spacingS),
                    LinearProgressIndicator(
                      value: completedLevels! / totalLevels!,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedLevels/$totalLevels levels',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isPhone ? 10 : 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Lock overlay
            if (isLocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(UIConstants.radiusL),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = UIHelpers.isPhone(context);
    final cardColor = color ?? UIConstants.primaryColor;
    
    return UIWidgets.buildCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(UIConstants.spacingS),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(UIConstants.radiusM),
            ),
            child: Icon(
              icon,
              color: cardColor,
              size: isPhone ? 24 : 28,
            ),
          ),
          const SizedBox(height: UIConstants.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: isPhone ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: UIConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isPhone ? 12 : 14,
              color: UIConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: isPhone ? 10 : 12,
                color: UIConstants.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final int currentProgress;
  final int targetProgress;
  final int pointValue;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.currentProgress,
    required this.targetProgress,
    required this.pointValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = UIHelpers.isPhone(context);
    final progress = targetProgress > 0 ? currentProgress / targetProgress : 0.0;
    
    return UIWidgets.buildCard(
      onTap: onTap,
      child: Container(
        height: isPhone ? 140 : 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and points
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(UIConstants.spacingS),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? UIConstants.successColor.withOpacity(0.1)
                        : UIConstants.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.radiusM),
                  ),
                  child: Icon(
                    icon,
                    color: isUnlocked ? UIConstants.successColor : UIConstants.textMuted,
                    size: isPhone ? 20 : 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: UIConstants.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.radiusS),
                  ),
                  child: Text(
                    '${pointValue}pts',
                    style: TextStyle(
                      color: UIConstants.warningColor,
                      fontSize: isPhone ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: UIConstants.spacingS),
            
            // Title and description
            Text(
              title,
              style: TextStyle(
                fontSize: isPhone ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? UIConstants.textPrimary : UIConstants.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: isPhone ? 12 : 14,
                  color: isUnlocked ? UIConstants.textSecondary : UIConstants.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Progress section
            const SizedBox(height: UIConstants.spacingS),
            if (!isUnlocked) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: UIConstants.textMuted.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(UIConstants.primaryColor),
              ),
              const SizedBox(height: 4),
              Text(
                '$currentProgress/$targetProgress',
                style: TextStyle(
                  fontSize: isPhone ? 10 : 12,
                  color: UIConstants.textMuted,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: UIConstants.successColor,
                    size: isPhone ? 16 : 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unlocked!',
                    style: TextStyle(
                      fontSize: isPhone ? 12 : 14,
                      color: UIConstants.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = UIHelpers.isPhone(context);
    
    // Get button colors based on type
    Color backgroundColor;
    Color textColor;
    
    switch (type) {
      case ButtonType.primary:
        backgroundColor = UIConstants.primaryColor;
        textColor = Colors.white;
        break;
      case ButtonType.secondary:
        backgroundColor = UIConstants.secondaryColor;
        textColor = Colors.white;
        break;
      case ButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = UIConstants.primaryColor;
        break;
      case ButtonType.danger:
        backgroundColor = UIConstants.errorColor;
        textColor = Colors.white;
        break;
      case ButtonType.admin:
        backgroundColor = UIConstants.adminPrimary;
        textColor = Colors.white;
        break;
    }
    
    // Get button size
    double padding;
    double fontSize;
    
    switch (size) {
      case ButtonSize.small:
        padding = isPhone ? UIConstants.spacingS : UIConstants.spacingM;
        fontSize = isPhone ? 12 : 14;
        break;
      case ButtonSize.medium:
        padding = isPhone ? UIConstants.spacingM : UIConstants.spacingL;
        fontSize = isPhone ? 14 : 16;
        break;
      case ButtonSize.large:
        padding = isPhone ? UIConstants.spacingL : UIConstants.spacingXL;
        fontSize = isPhone ? 16 : 18;
        break;
    }
    
    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: fontSize,
            height: fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: UIConstants.spacingS),
        ] else if (icon != null) ...[
          Icon(icon, color: textColor, size: fontSize * 1.2),
          const SizedBox(width: UIConstants.spacingS),
        ],
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    
    if (type == ButtonType.outline) {
      return OutlinedButton(
        onPressed: isLoading ? null : () {
          SoundService().playClick();
          onPressed?.call();
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: UIConstants.primaryColor, width: 2),
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusM),
          ),
        ),
        child: buttonChild,
      );
    }
    
    return ElevatedButton(
      onPressed: isLoading ? null : () {
        SoundService().playClick();
        onPressed?.call();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
        ),
        elevation: UIConstants.elevationM,
      ),
      child: buttonChild,
    );
  }
}

enum ButtonType { primary, secondary, outline, danger, admin }
enum ButtonSize { small, medium, large }
