import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/analysis/color_extraction.dart';
import 'package:shadesmaster/utils/unit_8_img.dart';
import 'package:shadesmaster/drawings.dart';
import 'package:mocktail/mocktail.dart';

class MockRenderBox extends Mock implements RenderBox {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'MockRenderBox';
}

void main() {
  // ---------------------------------------------------------------------------
  // isPointInPolygon (ray casting)
  // ---------------------------------------------------------------------------
  group('isPointInPolygon', () {
    // Define a 10×10 axis-aligned square
    final square = [
      const Offset(0, 0),
      const Offset(10, 0),
      const Offset(10, 10),
      const Offset(0, 10),
    ];

    test('point inside square returns true', () {
      expect(isPointInPolygon(const Offset(5, 5), square), isTrue);
    });

    test('point outside square returns false', () {
      expect(isPointInPolygon(const Offset(15, 5), square), isFalse);
      expect(isPointInPolygon(const Offset(-1, 5), square), isFalse);
      expect(isPointInPolygon(const Offset(5, 11), square), isFalse);
    });

    test('point at center of triangle', () {
      final triangle = [
        const Offset(0, 0),
        const Offset(10, 0),
        const Offset(5, 10),
      ];
      expect(isPointInPolygon(const Offset(5, 3), triangle), isTrue);
      expect(isPointInPolygon(const Offset(0, 9), triangle), isFalse);
    });

    test('polygon with fewer than 3 points always returns false', () {
      expect(isPointInPolygon(const Offset(5, 5), []), isFalse);
      expect(
          isPointInPolygon(const Offset(5, 5), [const Offset(0, 0)]), isFalse);
      expect(
        isPointInPolygon(
          const Offset(5, 5),
          [const Offset(0, 0), const Offset(10, 10)],
        ),
        isFalse,
      );
    });

    test('L-shaped (concave) polygon correctly classifies inside and outside',
        () {
      // L-shape: top-left 10×10, bottom-right notch removed
      final lShape = [
        const Offset(0, 0),
        const Offset(10, 0),
        const Offset(10, 5),
        const Offset(5, 5),
        const Offset(5, 10),
        const Offset(0, 10),
      ];
      // Inside the L (left column)
      expect(isPointInPolygon(const Offset(2, 7), lShape), isTrue);
      // Inside the L (top row)
      expect(isPointInPolygon(const Offset(8, 2), lShape), isTrue);
      // In the notch (outside)
      expect(isPointInPolygon(const Offset(8, 8), lShape), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // calculateBoundingBox
  // ---------------------------------------------------------------------------
  group('calculateBoundingBox', () {
    test('empty list returns Rect.zero', () {
      expect(calculateBoundingBox([]), Rect.zero);
    });

    test('single point returns zero-size rect at that point', () {
      final rect = calculateBoundingBox([const Offset(5, 10)]);
      expect(rect.left, 5.0);
      expect(rect.top, 10.0);
      expect(rect.right, 5.0);
      expect(rect.bottom, 10.0);
    });

    test('multiple points returns correct bounding box', () {
      final points = [
        const Offset(1, 9),
        const Offset(5, 2),
        const Offset(3, 7),
        const Offset(8, 4),
      ];
      final rect = calculateBoundingBox(points);
      expect(rect.left, 1.0);
      expect(rect.top, 2.0);
      expect(rect.right, 8.0);
      expect(rect.bottom, 9.0);
    });

    test('two points (diagonal) returns correct bounding box', () {
      final rect = calculateBoundingBox([
        const Offset(0, 0),
        const Offset(10, 10),
      ]);
      expect(rect, const Rect.fromLTRB(0, 0, 10, 10));
    });
  });

  // ---------------------------------------------------------------------------
  // getAllColorsFromRegion (integration)
  // ---------------------------------------------------------------------------
  group('getAllColorsFromRegion', () {
    late MockRenderBox mockRenderBox;

    setUpAll(() {
      registerFallbackValue(const Offset(0, 0));
    });

    setUp(() {
      mockRenderBox = MockRenderBox();
      // Widget size = 100×100 px, image size = 2×2 → scale = 2/100 = 0.02
      when(() => mockRenderBox.size).thenReturn(const Size(100, 100));
      // globalToLocal is identity (global == local in tests)
      when(() => mockRenderBox.globalToLocal(any()))
          .thenAnswer((inv) => inv.positionalArguments[0] as Offset);
    });

    test('returns empty list for image with no pixels', () {
      final emptyImg = Unit8Img(Uint8List(0), 0, 0);
      final region = Region([
        GlobalOffset(const Offset(0, 0)),
        GlobalOffset(const Offset(10, 0)),
        GlobalOffset(const Offset(10, 10)),
        GlobalOffset(const Offset(0, 10)),
      ]);
      expect(getAllColorsFromRegion(emptyImg, mockRenderBox, region), isEmpty);
    });

    test('returns empty list for region with no offsets', () {
      // 2×2 red image
      final pixels = Uint8List.fromList([
        255,
        0,
        0,
        255,
        255,
        0,
        0,
        255,
        255,
        0,
        0,
        255,
        255,
        0,
        0,
        255,
      ]);
      final img = Unit8Img(pixels, 2, 2);
      final emptyRegion = Region([]);
      expect(getAllColorsFromRegion(img, mockRenderBox, emptyRegion), isEmpty);
    });

    test('extracts color from 1×1 image with full-coverage region', () {
      // 1×1 blue pixel
      final pixels = Uint8List.fromList([0, 0, 255, 255]);
      final img = Unit8Img(pixels, 1, 1);
      // Widget is 100×100, image is 1×1 → scaleX = scaleY = 0.01
      // Region covers the full widget (0-100), pixel coords from (0,0) to (1,1)
      when(() => mockRenderBox.size).thenReturn(const Size(100, 100));
      final region = Region([
        GlobalOffset(const Offset(0, 0)),
        GlobalOffset(const Offset(100, 0)),
        GlobalOffset(const Offset(100, 100)),
        GlobalOffset(const Offset(0, 100)),
      ]);
      final colors = getAllColorsFromRegion(img, mockRenderBox, region);
      expect(colors, isNotEmpty);
      // Should extract blue
      expect(colors.first.b, closeTo(1.0, 0.01));
      expect(colors.first.r, closeTo(0.0, 0.01));
    });
  });
}
