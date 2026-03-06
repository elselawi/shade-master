import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/utils/rgb_to_lab.dart';

void main() {
  group('LabColor', () {
    test('equality and hash code', () {
      const color1 = LabColor(50.0, 10.0, -20.0);
      const color2 = LabColor(50.0001, 10.0001, -20.0001);
      const color3 = LabColor(60.0, 10.0, -20.0);

      expect(color1, color2);
      expect(color1.hashCode, color2.hashCode);
      expect(color1, isNot(color3));
    });

    test('toString formatting', () {
      const color = LabColor(50.1234, 10.5678, -20.9101);
      expect(color.toString(), 'Lab(L: 50.12, a: 10.57, b: -20.91)');
    });
  });

  group('rgbToLab', () {
    test('converts Black correctly', () {
      final lab = rgbToLab(Colors.black);
      expect(lab.l, closeTo(0.0, 0.01));
      expect(lab.a, closeTo(0.0, 0.01));
      expect(lab.b, closeTo(0.0, 0.01));
    });

    test('converts White correctly', () {
      final lab = rgbToLab(Colors.white);
      expect(lab.l, closeTo(100.0, 0.01));
      expect(lab.a, closeTo(0.0, 0.01));
      expect(lab.b, closeTo(0.0, 0.01));
    });

    test('converts Red correctly', () {
      // Standard sRGB Red: (255, 0, 0)
      final lab = rgbToLab(const Color(0xFFFF0000));
      // Expected LAB for sRGB Red: L=53.24, a=80.09, b=67.20
      expect(lab.l, closeTo(53.24, 0.1));
      expect(lab.a, closeTo(80.09, 0.1));
      expect(lab.b, closeTo(67.20, 0.1));
    });

    test('converts Green correctly', () {
      // Standard sRGB Green: (0, 255, 0)
      final lab = rgbToLab(const Color(0xFF00FF00));
      // Expected LAB for sRGB Green: L=87.73, a=-86.18, b=83.18
      expect(lab.l, closeTo(87.73, 0.1));
      expect(lab.a, closeTo(-86.18, 0.1));
      expect(lab.b, closeTo(83.18, 0.1));
    });

    test('converts Blue correctly', () {
      // Standard sRGB Blue: (0, 0, 255)
      final lab = rgbToLab(const Color(0xFF0000FF));
      // Expected LAB for sRGB Blue: L=32.30, a=79.19, b=-107.86
      expect(lab.l, closeTo(32.30, 0.1));
      expect(lab.a, closeTo(79.19, 0.1));
      expect(lab.b, closeTo(-107.86, 0.1));
    });
  });
}
