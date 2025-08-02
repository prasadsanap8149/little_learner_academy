import 'package:flutter/material.dart';

class UIConstants {
  // Colors
  static const Color primaryColor = Color(0xFF6B73FF);
  static const Color primaryDark = Color(0xFF5A63E6);
  static const Color primaryLight = Color(0xFF9A8EFF);
  static const Color secondaryColor = Color(0xFF50C878);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color warningColor = Color(0xFFECC94B);
  static const Color successColor = Color(0xFF48BB78);
  
  // Admin colors
  static const Color adminPrimary = Color(0xFF2E3B4E);
  static const Color adminSecondary = Color(0xFF4A5568);
  static const Color adminAccent = Color(0xFF38B2AC);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF718096);
  static const Color textLight = Colors.white;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 50.0;
  
  // Elevations
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Breakpoints
  static const double breakpointPhone = 600;
  static const double breakpointTablet = 1200;
  static const double breakpointDesktop = 1600;
}

class UITheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: _createMaterialColor(UIConstants.primaryColor),
      primaryColor: UIConstants.primaryColor,
      colorScheme: const ColorScheme.light(
        primary: UIConstants.primaryColor,
        secondary: UIConstants.secondaryColor,
        surface: UIConstants.surfaceColor,
        error: UIConstants.errorColor,
      ),
      fontFamily: 'Roboto',
      textTheme: _textTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      cardTheme: _cardTheme,
      appBarTheme: _appBarTheme,
      inputDecorationTheme: _inputDecorationTheme,
    );
  }

  static ThemeData get adminTheme {
    return ThemeData(
      primarySwatch: _createMaterialColor(UIConstants.adminPrimary),
      primaryColor: UIConstants.adminPrimary,
      colorScheme: const ColorScheme.light(
        primary: UIConstants.adminPrimary,
        secondary: UIConstants.adminAccent,
        surface: UIConstants.surfaceColor,
        error: UIConstants.errorColor,
      ),
      fontFamily: 'Roboto',
      textTheme: _textTheme,
      elevatedButtonTheme: _adminElevatedButtonTheme,
      cardTheme: _cardTheme,
      appBarTheme: _adminAppBarTheme,
      inputDecorationTheme: _inputDecorationTheme,
    );
  }

  static MaterialColor _createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = (color.r * 255).round();
    final int g = (color.g * 255).round();
    final int b = (color.b * 255).round();

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value.toInt(), swatch);
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: UIConstants.textPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: UIConstants.textPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: UIConstants.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: UIConstants.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: UIConstants.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: UIConstants.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: UIConstants.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: UIConstants.textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: UIConstants.textSecondary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: UIConstants.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: UIConstants.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: UIConstants.textMuted,
    ),
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: UIConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: UIConstants.elevationM,
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingL, vertical: UIConstants.spacingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
    ),
  );

  static final ElevatedButtonThemeData _adminElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: UIConstants.adminPrimary,
      foregroundColor: Colors.white,
      elevation: UIConstants.elevationM,
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingL, vertical: UIConstants.spacingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
    ),
  );

  static final CardThemeData _cardTheme = CardThemeData(
    elevation: UIConstants.elevationM,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(UIConstants.radiusL),
    ),
    margin: const EdgeInsets.all(UIConstants.spacingS),
  );

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: UIConstants.primaryColor,
    foregroundColor: Colors.white,
    elevation: UIConstants.elevationM,
    centerTitle: true,
  );

  static const AppBarTheme _adminAppBarTheme = AppBarTheme(
    backgroundColor: UIConstants.adminPrimary,
    foregroundColor: Colors.white,
    elevation: UIConstants.elevationM,
    centerTitle: true,
  );

  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(UIConstants.radiusM),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(UIConstants.radiusM),
      borderSide: const BorderSide(color: UIConstants.primaryColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: UIConstants.spacingM,
      vertical: UIConstants.spacingM,
    ),
  );
}

class UIHelpers {
  // Responsive helpers
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < UIConstants.breakpointPhone;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= UIConstants.breakpointPhone &&
           MediaQuery.of(context).size.width < UIConstants.breakpointTablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= UIConstants.breakpointTablet;
  }

  static double getResponsiveFontSize(BuildContext context, {
    required double phone,
    required double tablet,
    required double desktop,
  }) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isPhone(context)) return UIConstants.spacingM;
    if (isTablet(context)) return UIConstants.spacingL;
    return UIConstants.spacingXL;
  }

  // Common animations
  static Widget fadeInAnimation({
    required Widget child,
    Duration duration = UIConstants.animationMedium,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  static Widget slideInAnimation({
    required Widget child,
    Duration duration = UIConstants.animationMedium,
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      builder: (context, value, child) {
        return Transform.translate(offset: value, child: child);
      },
      child: child,
    );
  }

  // Common shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Common gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [UIConstants.primaryColor, UIConstants.primaryLight],
  );

  static LinearGradient get adminGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [UIConstants.adminPrimary, UIConstants.adminSecondary],
  );

  static LinearGradient get successGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [UIConstants.successColor, Color(0xFF68D391)],
  );
}

class UIWidgets {
  // Common card widget
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    double? elevation,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(UIConstants.spacingS),
      child: Material(
        color: color ?? UIConstants.surfaceColor,
        elevation: elevation ?? UIConstants.elevationM,
        borderRadius: BorderRadius.circular(UIConstants.radiusL),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(UIConstants.radiusL),
          child: Container(
            padding: padding ?? const EdgeInsets.all(UIConstants.spacingM),
            child: child,
          ),
        ),
      ),
    );
  }

  // Loading indicator
  static Widget buildLoadingIndicator({
    String? message,
    Color? color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? UIConstants.primaryColor,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: UIConstants.spacingM),
            Text(
              message,
              style: const TextStyle(color: UIConstants.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // Empty state widget
  static Widget buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: UIConstants.textMuted,
            ),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: UIConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: UIConstants.spacingS),
              Text(
                subtitle,
                style: const TextStyle(
                  color: UIConstants.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: UIConstants.spacingL),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // Snackbar helpers
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: UIConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
        ),
      ),
    );
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: UIConstants.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
        ),
      ),
    );
  }

  static void showInfoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: UIConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
        ),
      ),
    );
  }
}
