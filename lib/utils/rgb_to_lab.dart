import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Represents a color in CIELAB (L*a*b*) color space.
///
/// CIELAB is a perceptually uniform color space designed to match
/// human vision, making it ideal for color difference calculations.
///
/// - [l]: Lightness (0-100) - 0=black, 100=white
/// - [a]: Green-Red axis (-128 to +127) - negative=green, positive=red
/// - [b]: Blue-Yellow axis (-128 to +127) - negative=blue, positive=yellow
class LabColor {
  final double l;
  final double a;
  final double b;

  const LabColor(this.l, this.a, this.b);

  @override
  String toString() =>
      'Lab(L: ${l.toStringAsFixed(2)}, a: ${a.toStringAsFixed(2)}, b: ${b.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabColor &&
          (l - other.l).abs() < 0.001 &&
          (a - other.a).abs() < 0.001 &&
          (b - other.b).abs() < 0.001;

  @override
  int get hashCode => Object.hash(
        (l * 1000).round(),
        (a * 1000).round(),
        (b * 1000).round(),
      );
}

/// Converts a Flutter Color to CIELAB color space.
///
/// Performs accurate sRGB → Linear RGB → XYZ → LAB conversion using
/// standard illuminant D65 and proper gamma correction.
///
/// The conversion process:
/// 1. Extract RGB components from Flutter Color
/// 2. Apply sRGB gamma correction to get linear RGB
/// 3. Transform to CIE XYZ color space using sRGB matrix
/// 4. Normalize using D65 reference white point
/// 5. Convert XYZ to perceptually uniform LAB space
///
/// Parameters:
/// - [color]: Flutter Color object to convert
///
/// Returns: [LabColor] with L (0-100), a (-128 to +127), b (-128 to +127)
///
/// Example:
/// ```dart
/// final lab = rgbToLab(Colors.red);
/// print(lab); // Lab(L: 53.24, a: 80.09, b: 67.20)
/// ```
LabColor rgbToLab(Color color) {
  // Extract RGB using efficient bit operations
  // Extract RGB and scale to 0-255 since Flutter Color components are 0.0-1.0
  final double r = color.r * 255.0;
  final double g = color.g * 255.0;
  final double b = color.b * 255.0;

  // Convert sRGB to linear RGB with gamma correction
  double srgbToLinear(double value) {
    final normalized = value / 255.0;
    return ((normalized <= 0.04045)
            ? normalized / 12.92
            : math.pow((normalized + 0.055) / 1.055, 2.4))
        .toDouble();
  }

  final rLinear = srgbToLinear(r);
  final gLinear = srgbToLinear(g);
  final bLinear = srgbToLinear(b);

  // Transform linear RGB to XYZ using sRGB transformation matrix
  // Matrix values from IEC 61966-2-1:1999 standard
  final x = rLinear * 0.4124564 + gLinear * 0.3575761 + bLinear * 0.1804375;
  final y = rLinear * 0.2126729 + gLinear * 0.7151522 + bLinear * 0.0721750;
  final z = rLinear * 0.0193339 + gLinear * 0.1191920 + bLinear * 0.9503041;

  // Normalize using D65 reference white point
  // D65 values: X=0.95047, Y=1.00000, Z=1.08883
  final xNorm = x / 0.95047;
  final yNorm = y / 1.00000;
  final zNorm = z / 1.08883;

  // Convert normalized XYZ to LAB
  double xyzToLabComponent(double component) {
    const epsilon = 0.008856; // (6/29)³
    const kappa = 903.3; // (29/3)³

    return ((component > epsilon)
            ? math.pow(component, 1.0 / 3.0)
            : (kappa * component + 16) / 116)
        .toDouble();
  }

  final fx = xyzToLabComponent(xNorm);
  final fy = xyzToLabComponent(yNorm);
  final fz = xyzToLabComponent(zNorm);

  // Calculate final LAB values
  final L = 116 * fy - 16;
  final A = 500 * (fx - fy);
  final B = 200 * (fy - fz);

  return LabColor(L, A, B);
}
