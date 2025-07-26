import 'package:flutter/material.dart';

class AnswerOption<T> {
  final T value;
  final String displayText;

  AnswerOption({
    required this.value,
    String? displayText,
  }) : displayText = displayText ?? value.toString();
}

class AnswerOptionsGrid<T> extends StatelessWidget {
  final List<AnswerOption<T>> options;
  final T? selectedAnswer;
  final T? correctAnswer;
  final bool showResult;
  final Function(T) onOptionSelected;
  final double? height;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? spacing;
  final TextStyle? textStyle;

  const AnswerOptionsGrid({
    super.key,
    required this.options,
    this.selectedAnswer,
    this.correctAnswer,
    this.showResult = false,
    required this.onOptionSelected,
    this.height,
    this.crossAxisCount,
    this.childAspectRatio,
    this.spacing,
    this.textStyle,
  });

  double _getHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive height based on screen size
    if (screenHeight < 600) {
      // Small phones
      return height ?? 180;
    } else if (screenHeight < 1024) {
      // Regular phones and small tablets
      return height ?? 215;
    } else {
      // Large tablets and laptops
      return height ?? 260;
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive grid columns based on screen width
    if (screenWidth < 600) {
      // Mobile
      return crossAxisCount ?? 2;
    } else if (screenWidth < 1024) {
      // Tablet
      return crossAxisCount ?? 3;
    } else {
      // Laptop/Desktop
      return crossAxisCount ?? 4;
    }
  }

  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive aspect ratio based on screen size
    if (screenWidth < 600) {
      // Mobile
      return childAspectRatio ?? 1.5;
    } else if (screenWidth < 1024) {
      // Tablet
      return childAspectRatio ?? 1.8;
    } else {
      // Laptop/Desktop
      return childAspectRatio ?? 2.0;
    }
  }

  double _getSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive spacing based on screen size
    if (screenWidth < 600) {
      // Mobile
      return spacing ?? 12;
    } else if (screenWidth < 1024) {
      // Tablet
      return spacing ?? 16;
    } else {
      // Laptop/Desktop
      return spacing ?? 20;
    }
  }

  double _getFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive font size based on screen size
    if (screenWidth < 600) {
      // Mobile
      return 24;
    } else if (screenWidth < 1024) {
      // Tablet
      return 28;
    } else {
      // Laptop/Desktop
      return 32;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = _getSpacing(context);
    final responsiveFontSize = _getFontSize(context);

    return SizedBox(
      height: _getHeight(context),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: _getChildAspectRatio(context),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedAnswer == option.value;
          final isCorrect = option.value == correctAnswer;

          Color backgroundColor = Colors.white;
          Color borderColor = Colors.grey[300]!;
          Color textColor = const Color(0xFF2C3E50);

          if (showResult) {
            if (isCorrect) {
              backgroundColor = Colors.green[100]!;
              borderColor = Colors.green;
              textColor = Colors.green[800]!;
            } else if (isSelected && !isCorrect) {
              backgroundColor = Colors.red[100]!;
              borderColor = Colors.red;
              textColor = Colors.red[800]!;
            }
          } else if (isSelected) {
            backgroundColor = const Color(0xFF6B73FF).withOpacity(0.1);
            borderColor = const Color(0xFF6B73FF);
            textColor = const Color(0xFF6B73FF);
          }

          return GestureDetector(
            onTap: showResult ? null : () => onOptionSelected(option.value),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  option.displayText,
                  style:
                      (textStyle ?? Theme.of(context).textTheme.headlineMedium)
                          ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: responsiveFontSize,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
