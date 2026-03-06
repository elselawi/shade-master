import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/analysis/analyze.dart';
import 'package:flutter/material.dart';

void main() {
  // ---------------------------------------------------------------------------
  // evenlySample
  // ---------------------------------------------------------------------------
  group('evenlySample', () {
    test('returns copy of original list when target size equals length', () {
      final list = [1, 2, 3];
      final result = evenlySample(list, 3);
      expect(result, [1, 2, 3]);
      // Should be a new list, not the same reference
      expect(identical(result, list), isFalse);
    });

    test('returns full list when target size is larger than length', () {
      final list = [1, 2, 3];
      expect(evenlySample(list, 5), [1, 2, 3]);
    });

    test('samples 3 from 11 correctly (endpoints included)', () {
      final list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      // step = (11-1)/(3-1) = 5 → indices 0, 5, 10
      expect(evenlySample(list, 3), [0, 5, 10]);
    });

    test('samples 2 from list returns first and last', () {
      final list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      expect(evenlySample(list, 2), [0, 10]);
    });

    test('samples 1 from list returns first element', () {
      final list = [10, 20, 30, 40, 50];
      // step = (5-1)/(1-1) would be division by zero; targetSize >= list.length
      // is handled — but targetSize=1 < 5 so it runs. step = 4/0 → Inf
      // generate(1, (i) => list[(i*step).round()]) → list[0] = 10
      expect(evenlySample(list, 1), [10]);
    });

    test('works with string lists', () {
      final list = ['a', 'b', 'c', 'd', 'e'];
      expect(evenlySample(list, 3), ['a', 'c', 'e']);
    });
  });

  // ---------------------------------------------------------------------------
  // ShadeResult
  // ---------------------------------------------------------------------------
  group('ShadeResult', () {
    test('stores name, delta, averageColor, and winner correctly', () {
      final result = ShadeResult('B', 5.0, Colors.blue, false);
      expect(result.name, 'B');
      expect(result.delta, 5.0);
      expect(result.averageColor, Colors.blue);
      expect(result.winner, isFalse);
    });

    test('winner flag is preserved', () {
      final winner = ShadeResult('A', 2.0, Colors.red, true);
      final loser = ShadeResult('B', 8.0, Colors.green, false);
      expect(winner.winner, isTrue);
      expect(loser.winner, isFalse);
    });

    test('similarity: delta=1.0 → 100% (best)', () {
      final result = ShadeResult('A', 1.0, Colors.red, true);
      expect(result.similarity, 100.0);
    });

    test('similarity: delta=40.0 → 0% (worst)', () {
      final result = ShadeResult('A', 40.0, Colors.red, false);
      expect(result.similarity, 0.0);
    });

    test('similarity: delta=20.5 → 50% (mid-point)', () {
      // (20.5 - 1) / (40 - 1) = 19.5 / 39 = 0.5 → 100 - 50 = 50
      final result = ShadeResult('A', 20.5, Colors.red, false);
      expect(result.similarity, 50.0);
    });

    test('similarity: delta below 1.0 is clamped → 100%', () {
      final result = ShadeResult('A', 0.0, Colors.red, true);
      expect(result.similarity, 100.0);
    });

    test('similarity: delta above 40.0 is clamped → 0%', () {
      final result = ShadeResult('A', 100.0, Colors.red, false);
      expect(result.similarity, 0.0);
    });

    test('similarity is always in [0, 100]', () {
      for (final delta in [
        -5.0,
        0.0,
        1.0,
        5.0,
        20.5,
        39.9,
        40.0,
        50.0,
        100.0
      ]) {
        final result = ShadeResult('X', delta, Colors.white, false);
        expect(result.similarity, inInclusiveRange(0.0, 100.0),
            reason: 'delta=$delta produced out-of-range similarity');
      }
    });
  });
}
