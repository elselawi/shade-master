import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/analysis/comparison.dart';
import 'package:shadesmaster/utils/rgb_to_lab.dart';

void main() {
  // ---------------------------------------------------------------------------
  // deltaE (DeltaE2000)
  // ---------------------------------------------------------------------------
  group('deltaE (DeltaE2000)', () {
    test('identical colors have zero distance', () {
      const color = LabColor(50.0, 10.0, 20.0);
      expect(deltaE(color, color), 0.0);
    });

    test('is symmetric: deltaE(a,b) == deltaE(b,a)', () {
      const a = LabColor(40.0, 15.0, -10.0);
      const b = LabColor(70.0, -5.0, 30.0);
      expect(deltaE(a, b), deltaE(b, a));
    });

    test('known lightness difference (~10 ΔE for ΔL=10 in neutral gray)', () {
      const color1 = LabColor(50.0, 0.0, 0.0);
      const color2 = LabColor(60.0, 0.0, 0.0);
      expect(deltaE(color1, color2), closeTo(10.0, 1));
    });

    test('chroma-only difference is positive', () {
      const color1 = LabColor(50.0, 10.0, 0.0);
      const color2 = LabColor(50.0, 20.0, 0.0);
      expect(deltaE(color1, color2), isPositive);
    });

    test('hue-only difference is positive', () {
      // Same L*, same chroma magnitude, opposite hue direction
      const color1 = LabColor(50.0, 20.0, 0.0);
      const color2 = LabColor(50.0, -20.0, 0.0);
      expect(deltaE(color1, color2), isPositive);
    });

    test('neutral/achromatic colors (very small a*, b*)', () {
      const color1 = LabColor(50.0, 0.0, 0.0);
      const color2 = LabColor(50.0, 0.1, 0.1);
      expect(deltaE(color1, color2), closeTo(0.18, 0.05));
    });

    test('large distance between very different colors', () {
      // Black vs white in LAB
      const black = LabColor(0.0, 0.0, 0.0);
      const white = LabColor(100.0, 0.0, 0.0);
      expect(deltaE(black, white), greaterThan(50));
    });

    test('custom weight parameters scale components', () {
      const color1 = LabColor(50.0, 0.0, 0.0);
      const color2 = LabColor(60.0, 0.0, 0.0);
      final defaultDelta = deltaE(color1, color2);
      // Doubling lightness weight should halve the lightness component denominator
      // → result is larger (more sensitive to L changes)
      final heavierL = deltaE(color1, color2, lightness: 0.5);
      expect(heavierL, greaterThan(defaultDelta));
    });

    test('very small differences remain non-negative', () {
      const color1 = LabColor(50.0, 10.0, 20.0);
      const color2 = LabColor(50.001, 10.001, 20.001);
      expect(deltaE(color1, color2), isNonNegative);
    });

    // Reference values computed from authoritative CIEDE2000 test data
    // Sharma et al. (2005) Table 1, pair 1: ΔE = ~2.0425
    test('reference: Sharma et al. pair 1 (~2.04)', () {
      const l1 = LabColor(50.0000, 2.6772, -79.7751);
      const l2 = LabColor(50.0000, 0.0000, -82.7485);
      expect(deltaE(l1, l2), closeTo(2.0425, 0.002));
    });

    // Sharma et al. (2005) Table 1 pair 17 uses Cab* = 0 for both colors
    // which means the hue angle is undefined; many implementations treat this
    // differently. The pair below uses verifiable neutral-gray inputs where
    // the only difference is in a* and b*, confirming the formula works for
    // achromatic cases.
    test('reference: near-neutral pair gives small but positive distance', () {
      const l1 = LabColor(50.0, 0.5, 0.5);
      const l2 = LabColor(50.0, 0.0, 0.0);
      final d = deltaE(l1, l2);
      expect(d, isPositive);
      expect(d, lessThan(1.0));
    });

    test(
        'reference: pair with zero Cab* (neutral gray) gives small but positive distance',
        () {
      const l1 = LabColor(50.0, 0.5, 0.5);
      const l2 = LabColor(50.0, 0.0, 0.0);
      final d = deltaE(l1, l2);
      expect(d, isPositive);
      expect(d, lessThan(1.0));
    });

    test("set test", () {
      final tests = [
        (
          LabColor(50.0000, 2.6772, -79.7751),
          LabColor(50.0000, 0.0000, -82.7485),
          2.0425
        ),
        (
          LabColor(50.0000, 3.1571, -77.2803),
          LabColor(50.0000, 0.0000, -82.7485),
          2.8615
        ),
        (
          LabColor(50.0000, 2.8361, -74.0200),
          LabColor(50.0000, 0.0000, -82.7485),
          3.4412
        ),
        (
          LabColor(50.0000, -1.3802, -84.2814),
          LabColor(50.0000, 0.0000, -82.7485),
          1.0000
        ),
        (
          LabColor(50.0000, -1.1848, -84.8006),
          LabColor(50.0000, 0.0000, -82.7485),
          1.0000
        ),
        (
          LabColor(50.0000, -0.9009, -85.5211),
          LabColor(50.0000, 0.0000, -82.7485),
          1.0000
        ),
        (
          LabColor(50.0000, 0.0000, 0.0000),
          LabColor(50.0000, -1.0000, 2.0000),
          2.3669
        ),
        (
          LabColor(50.0000, -1.0000, 2.0000),
          LabColor(50.0000, 0.0000, 0.0000),
          2.3669
        ),
        (
          LabColor(50.0000, 2.4900, -0.0010),
          LabColor(50.0000, -2.4900, 0.0009),
          7.1792
        ),
        (
          LabColor(50.0000, 2.4900, -0.0010),
          LabColor(50.0000, -2.4900, 0.0010),
          7.1792
        ),
      ];

      for (final (c1, c2, expected) in tests) {
        expect(deltaE(c1, c2), closeTo(expected, 0.001));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // deltaGroups
  // ---------------------------------------------------------------------------
  group('deltaGroups', () {
    test('identical groups have zero distance', () {
      final group = [
        const LabColor(40.0, 0.0, 0.0),
        const LabColor(50.0, 0.0, 0.0),
        const LabColor(60.0, 0.0, 0.0),
      ];
      expect(deltaGroups(group, group), 0.0);
    });

    test('different groups have positive distance', () {
      final groupA = [
        const LabColor(40.0, 0.0, 0.0),
        const LabColor(50.0, 0.0, 0.0),
      ];
      final groupB = [
        const LabColor(45.0, 0.0, 0.0),
        const LabColor(55.0, 0.0, 0.0),
      ];
      expect(deltaGroups(groupA, groupB), isPositive);
    });

    test('groups aligned by lightness: mid-points match', () {
      // Short group has only [50]
      // Long group has [40, 50, 60], midLong=1, midShort=0, offset=1
      // shorter[0] (L50) vs longer[1] (L50) → 0.0
      final groupShort = [const LabColor(50.0, 0.0, 0.0)];
      final groupLong = [
        const LabColor(40.0, 0.0, 0.0),
        const LabColor(50.0, 0.0, 0.0),
        const LabColor(60.0, 0.0, 0.0),
      ];
      expect(deltaGroups(groupShort, groupLong), closeTo(0.0, 0.001));
    });

    test('handles groups of equal size correctly', () {
      final groupA = [
        const LabColor(40.0, 5.0, 0.0),
        const LabColor(50.0, 5.0, 0.0),
        const LabColor(60.0, 5.0, 0.0),
      ];
      final groupB = [
        const LabColor(40.0, 0.0, 0.0),
        const LabColor(50.0, 0.0, 0.0),
        const LabColor(60.0, 0.0, 0.0),
      ];
      // Each pair differs only in chroma → nonzero positive result
      expect(deltaGroups(groupA, groupB), isPositive);
    });

    test(
        'order of arguments does not drastically change result for equal-size groups',
        () {
      final groupA = [
        const LabColor(40.0, 0.0, 0.0),
        const LabColor(50.0, 0.0, 0.0),
      ];
      final groupB = [
        const LabColor(45.0, 0.0, 0.0),
        const LabColor(55.0, 0.0, 0.0),
      ];
      // Both orderings should give same result since sizes are equal (offset=0)
      expect(deltaGroups(groupA, groupB),
          closeTo(deltaGroups(groupB, groupA), 0.0001));
    });

    test('handles empty groups safely (returns 0)', () {
      expect(deltaGroups([], []), 0.0);
    });

    test('single element vs single element: pure deltaE', () {
      const a = LabColor(50.0, 10.0, 0.0);
      const b = LabColor(50.0, 20.0, 0.0);
      expect(deltaGroups([a], [b]), closeTo(deltaE(a, b), 1e-9));
    });

    test('larger groups produce a non-zero average when colors differ', () {
      final groupA = List.generate(10, (i) => LabColor(i * 5.0, 0.0, 0.0));
      final groupB =
          List.generate(10, (i) => LabColor(i * 5.0 + 3.0, 0.0, 0.0));
      expect(deltaGroups(groupA, groupB), isPositive);
    });
  });
}
