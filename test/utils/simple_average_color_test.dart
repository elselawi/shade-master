import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/utils/simple_average_color.dart';

void main() {
  group('simpleAverageColor', () {
    test('average of empty list is transparent', () {
      expect(simpleAverageColor([]), Colors.transparent);
    });

    test('average of a single color is the color itself', () {
      const color = Color(0xFFFF0000); // Red
      expect(simpleAverageColor([color]), color);
    });

    test('average of two colors', () {
      const color1 = Color(0xFFFF0000); // Red
      const color2 = Color(0xFF0000FF); // Blue
      final average = simpleAverageColor([color1, color2]);

      // (255+0)/2 = 127.5 -> 128
      // (0+0)/2 = 0
      // (0+255)/2 = 127.5 -> 128
      // Alpha: 255
      expect(average.r * 255, closeTo(127.5, 0.5));
      expect(average.g * 255, 0);
      expect(average.b * 255, closeTo(127.5, 0.5));
      expect(average.a * 255, 255);
    });

    test('average of multiple colors with different alphas', () {
      const color1 = Color(0x80FF0000); // half-transparent Red
      const color2 = Color(0xFFFF0000); // opaque Red
      final average = simpleAverageColor([color1, color2]);

      expect(average.r * 255, 255);
      expect(average.g * 255, 0);
      expect(average.b * 255, 0);
      // (128 + 255) / 2 = 191.5
      expect(average.a * 255, closeTo(191.5, 0.5));
    });
  });
}
