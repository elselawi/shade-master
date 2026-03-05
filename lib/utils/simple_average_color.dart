import 'package:flutter/material.dart';

/// Finds the average color in a list of colors
///
/// This is an over-simplification and not used in the comparison logic
/// However, we're using it in the widget to show which tooth is closest to
/// which shade.
///
/// - [colors]: A list of [Color].
///
/// Returns single [Color]
Color simpleAverageColor(List<Color> colors) {
  if (colors.isEmpty) {
    return Colors.transparent; // Return transparent if the list is empty
  }

  double red = 0;
  double green = 0;
  double blue = 0;
  double alpha = 0;

  for (Color color in colors) {
    red += color.r;
    green += color.g;
    blue += color.b;
    alpha += color.a;
  }

  // Calculate the average of each component
  double avgRed = (red / colors.length);
  double avgGreen = (green / colors.length);
  double avgBlue = (blue / colors.length);
  double avgAlpha = (alpha / colors.length);

  return Color.from(
    alpha: avgAlpha,
    red: avgRed,
    green: avgGreen,
    blue: avgBlue,
  );
}
