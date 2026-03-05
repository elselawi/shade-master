import 'dart:math' as math;
import 'package:shadesmaster/utils/rgb_to_lab.dart';

/// DeltaE2000 comparison algorithm, gives the visual distance
/// between two colors.
/// The given colors must be CIELAB colors.
///
/// - color1 [LabColor] the first color in question
/// - color2 [LabColor] the second color in question
///
/// returns: the distance between the two colors
double deltaE(
  LabColor color1,
  LabColor color2, {
  double lightness = 1.0,
  double chroma = 1.0,
  double hue = 1.0,
}) {
  final double ksubL = lightness;
  final double ksubC = chroma;
  final double ksubH = hue;

  // Delta L Prime
  final double deltaLPrime = color2.l - color1.l;

  // L Bar
  final double lBar = (color1.l + color2.l) * 0.5;

  // C1 & C2 - use single sqrt call with pre-computed squares
  final double color1A2 = color1.a * color1.a;
  final double color1B2 = color1.b * color1.b;
  final double color2A2 = color2.a * color2.a;
  final double color2B2 = color2.b * color2.b;

  final double c1 = math.sqrt(color1A2 + color1B2);
  final double c2 = math.sqrt(color2A2 + color2B2);

  // C Bar
  final double cBar = (c1 + c2) * 0.5;
  final double cBar7 = math.pow(cBar, 7.0).toDouble();

  // Pre-compute the G factor used in both aPrime calculations
  final double G = 0.5 * (1.0 - math.sqrt(cBar7 / (cBar7 + _pow25_7)));

  // A Prime 1 & 2
  final double aPrime1 = color1.a * (1.0 + G);
  final double aPrime2 = color2.a * (1.0 + G);

  // C Prime 1 & 2
  final double cPrime1 = math.sqrt(aPrime1 * aPrime1 + color1B2);
  final double cPrime2 = math.sqrt(aPrime2 * aPrime2 + color2B2);

  // C Bar Prime
  final double cBarPrime = (cPrime1 + cPrime2) * 0.5;

  // Delta C Prime
  final double deltaCPrime = cPrime2 - cPrime1;

  // S sub L - optimize the fraction
  final double lBarMinus50 = lBar - 50.0;
  final double lBarMinus50Sq = lBarMinus50 * lBarMinus50;
  final double ssubL =
      1.0 + (0.015 * lBarMinus50Sq) / math.sqrt(20.0 + lBarMinus50Sq);

  // S sub C
  final double ssubC = 1.0 + 0.045 * cBarPrime;

  // Helper function for h Prime calculation
  double gethPrime(double x, double y) {
    if (x == 0.0 && y == 0.0) {
      return 0.0;
    }
    final double hueAngle = math.atan2(x, y) * _i180Pi;
    return hueAngle >= 0.0 ? hueAngle : hueAngle + 360.0;
  }

  // h Prime 1 & 2
  final double hPrime1 = gethPrime(color1.b, aPrime1);
  final double hPrime2 = gethPrime(color2.b, aPrime2);

  // Delta h Prime
  double deltahPrime;
  if (c1 == 0.0 || c2 == 0.0) {
    deltahPrime = 0.0;
  } else {
    final double diff = hPrime1 - hPrime2;
    final double absDiff = diff.abs();

    if (absDiff <= 180.0) {
      deltahPrime = -diff; // hPrime2 - hPrime1
    } else if (hPrime2 <= hPrime1) {
      deltahPrime = -diff + 360.0; // hPrime2 - hPrime1 + 360
    } else {
      deltahPrime = -diff - 360.0; // hPrime2 - hPrime1 - 360
    }
  }

  // Delta H Prime
  final double deltaHPrime =
      2.0 * math.sqrt(cPrime1 * cPrime2) * math.sin(deltahPrime * _pi180 * 0.5);

  // H Bar Prime
  double hBarPrime;
  final double hPrimeDiff = (hPrime1 - hPrime2).abs();
  if (hPrimeDiff > 180.0) {
    hBarPrime = (hPrime1 + hPrime2 + 360.0) * 0.5;
  } else {
    hBarPrime = (hPrime1 + hPrime2) * 0.5;
  }

  // T - pre-compute angle conversions
  final double hBarPrimeRad = hBarPrime * _pi180;
  final double T = 1.0 -
      0.17 * math.cos(hBarPrimeRad - 30.0 * _pi180) +
      0.24 * math.cos(2.0 * hBarPrimeRad) +
      0.32 * math.cos(3.0 * hBarPrimeRad + 6.0 * _pi180) -
      0.2 * math.cos(4.0 * hBarPrimeRad - 63.0 * _pi180);

  // S sub H
  final double ssubH = 1.0 + 0.015 * cBarPrime * T;

  // R sub T
  final double cBarPrime7 = math.pow(cBarPrime, 7.0).toDouble();
  final double hBarPrimeMinus275 = (hBarPrime - 275.0) / 25.0;
  final double rsubT = -2.0 *
      math.sqrt(cBarPrime7 / (cBarPrime7 + _pow25_7)) *
      math.sin(
          60.0 * _pi180 * math.exp(-hBarPrimeMinus275 * hBarPrimeMinus275));

  // Final calculation
  final double lightnessComponent = deltaLPrime / (ksubL * ssubL);
  final double chromaComponent = deltaCPrime / (ksubC * ssubC);
  final double hueComponent = deltaHPrime / (ksubH * ssubH);

  return math.sqrt(
        lightnessComponent * lightnessComponent +
            chromaComponent * chromaComponent +
            hueComponent * hueComponent +
            rsubT * chromaComponent * hueComponent,
      ) *
      10;
}

/// Returns the visual distance using the above deltaE2000 but **for groups**
/// This is done by aligning the two groups to each other
/// then comparing color to color that are at the same order of lightness
/// Hence, this function must be given sorted groups.
double deltaGroups(List<LabColor> sortedGroupA, List<LabColor> sortedGroupB) {
  final lenA = sortedGroupA.length;
  final lenB = sortedGroupB.length;

  // Identify shorter and longer groups
  final bool aIsShorter = lenA <= lenB;
  final shorter = aIsShorter ? sortedGroupA : sortedGroupB;
  final longer = aIsShorter ? sortedGroupB : sortedGroupA;

  final lenShort = shorter.length;
  final lenLong = longer.length;

  final midShort = (lenShort / 2).floor();
  final midLong = (lenLong / 2).floor();

  final offset = midLong - midShort;

  final diffs = <double>[];

  for (int i = 0; i < lenShort; i++) {
    final longIndex = i + offset;
    if (longIndex < 0 || longIndex >= lenLong) {
      // Skip out-of-bounds
      continue;
    }
    diffs.add(deltaE(shorter[i], longer[longIndex]));
  }

  if (diffs.isEmpty) return 0.0; // shouldn't happen

  return _average(diffs);
}

// Pre-computed constants
const double _pow25_7 = 6103515625.0; // 25^7
const double _pi180 = math.pi / 180.0;
const double _i180Pi = 180.0 / math.pi;

double _average(List<double> values) {
  if (values.isEmpty) return 0.0;
  return values.reduce((a, b) => a + b) / values.length;
}
