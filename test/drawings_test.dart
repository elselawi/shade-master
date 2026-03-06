import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/drawings.dart';
import 'package:shadesmaster/utils/unit_8_img.dart';
import 'package:mocktail/mocktail.dart';

class MockRenderBox extends Mock implements RenderBox {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'MockRenderBox';
}

/// Creates a [Unit8Img] whose every pixel is the specified RGB color.
Unit8Img solidColorImg(int width, int height, int r, int g, int b) {
  final pixels = Uint8List(width * height * 4);
  for (int i = 0; i < width * height; i++) {
    pixels[i * 4] = r;
    pixels[i * 4 + 1] = g;
    pixels[i * 4 + 2] = b;
    pixels[i * 4 + 3] = 255;
  }
  return Unit8Img(pixels, width, height);
}

/// Creates a full-coverage [Region] for a widget of the given size (global coords).
Region fullRegion(double width, double height) => Region([
      GlobalOffset(Offset(0, 0)),
      GlobalOffset(Offset(width, 0)),
      GlobalOffset(Offset(width, height)),
      GlobalOffset(Offset(0, height)),
    ]);

void main() {
  setUpAll(() {
    registerFallbackValue(const Offset(0, 0));
  });

  // ---------------------------------------------------------------------------
  // GlobalOffset
  // ---------------------------------------------------------------------------
  group('GlobalOffset', () {
    late MockRenderBox mockRenderBox;

    setUp(() {
      mockRenderBox = MockRenderBox();
      when(() => mockRenderBox.size).thenReturn(const Size(100, 100));
      // Identity transform: global == local
      when(() => mockRenderBox.globalToLocal(any()))
          .thenAnswer((inv) => inv.positionalArguments[0] as Offset);
    });

    test('pixelOffset scales screen coords to image pixel coords', () {
      // Widget 100×100, image 200×200 → scale = 2.0
      final global = GlobalOffset(const Offset(50, 25));
      final img = Unit8Img(Uint8List(0), 200, 200);
      final pixel = global.pixelOffset(mockRenderBox, img);
      expect(pixel.dx, closeTo(100.0, 0.001));
      expect(pixel.dy, closeTo(50.0, 0.001));
    });

    test('pixelOffset handles 1:1 scale correctly', () {
      final global = GlobalOffset(const Offset(30, 70));
      final img = Unit8Img(Uint8List(0), 100, 100);
      final pixel = global.pixelOffset(mockRenderBox, img);
      expect(pixel.dx, closeTo(30.0, 0.001));
      expect(pixel.dy, closeTo(70.0, 0.001));
    });

    test('screenOffset applies globalToLocal transform', () {
      when(() => mockRenderBox.globalToLocal(any()))
          .thenAnswer((_) => const Offset(10, 20));
      final global = GlobalOffset(const Offset(999, 999));
      expect(global.screenOffset(mockRenderBox), const Offset(10, 20));
    });
  });

  // ---------------------------------------------------------------------------
  // Stroke – caching
  // ---------------------------------------------------------------------------
  group('Stroke caching', () {
    late MockRenderBox mockRenderBox;

    setUp(() {
      mockRenderBox = MockRenderBox();
      when(() => mockRenderBox.size).thenReturn(const Size(100, 100));
      when(() => mockRenderBox.globalToLocal(any()))
          .thenAnswer((inv) => inv.positionalArguments[0] as Offset);
    });

    test('getPixelOffset returns same list instance on second call (cache hit)',
        () {
      final img = Unit8Img(Uint8List(0), 100, 100);
      final stroke = Stroke([GlobalOffset(const Offset(10, 10))]);

      final first = stroke.getPixelOffset(mockRenderBox, img);
      final second = stroke.getPixelOffset(mockRenderBox, img);

      expect(identical(first, second), isTrue,
          reason: 'Expected the cached list to be returned on the second call');
    });

    test('cache is invalidated when offsets list changes', () {
      final img = Unit8Img(Uint8List(0), 100, 100);
      final stroke = Stroke([GlobalOffset(const Offset(10, 10))]);

      final first = stroke.getPixelOffset(mockRenderBox, img);

      // Mutate the offsets list to force cache invalidation
      stroke.offsets.add(GlobalOffset(const Offset(20, 20)));

      final second = stroke.getPixelOffset(mockRenderBox, img);

      expect(identical(first, second), isFalse,
          reason: 'Expected cache to be invalidated after offsets changed');
      expect(second.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Region – getSortedPrunedLabColors
  // ---------------------------------------------------------------------------
  group('Region.getSortedPrunedLabColors', () {
    late MockRenderBox mockRenderBox;

    setUp(() {
      mockRenderBox = MockRenderBox();
      // Widget 100×100, image will be 100×100 (1:1 scale)
      when(() => mockRenderBox.size).thenReturn(const Size(100, 100));
      when(() => mockRenderBox.globalToLocal(any()))
          .thenAnswer((inv) => inv.positionalArguments[0] as Offset);
    });

    test('returns sorted colors by lightness (L* ascending)', () {
      // 2×1 image: left pixel is darker gray, right is lighter gray
      final pixels = Uint8List.fromList([
        50, 50, 50, 255, // dark gray
        200, 200, 200, 255, // light gray
      ]);
      final img = Unit8Img(pixels, 2, 1);

      // Widget 100×2 so that the whole image is covered
      when(() => mockRenderBox.size).thenReturn(const Size(100, 1));
      final region = fullRegion(100, 1);
      final labs = region.getSortedLabColors(img, mockRenderBox);

      // Should be sorted ascending by L
      for (int i = 1; i < labs.length; i++) {
        expect(labs[i].l, greaterThanOrEqualTo(labs[i - 1].l));
      }
    });

    test('prunes outlier colors far from median', () {
      // Create a 10×1 image: 9 near-identical mid-gray pixels + 1 pure-red outlier
      //   Gray (128,128,128) → LAB ~(53, 0, 0) — cluster
      //   Red  (255, 0,  0)  → LAB ~(53, 80, 67) — far outlier
      final pixels = Uint8List(10 * 1 * 4);
      // 9 gray pixels
      for (int i = 0; i < 9; i++) {
        pixels[i * 4] = 128;
        pixels[i * 4 + 1] = 128;
        pixels[i * 4 + 2] = 128;
        pixels[i * 4 + 3] = 255;
      }
      // 1 red outlier at index 9
      pixels[9 * 4] = 255;
      pixels[9 * 4 + 1] = 0;
      pixels[9 * 4 + 2] = 0;
      pixels[9 * 4 + 3] = 255;

      final img = Unit8Img(pixels, 10, 1);
      when(() => mockRenderBox.size).thenReturn(const Size(100, 1));
      final region = fullRegion(100, 1);

      final pruned = region.getSortedPrunedLabColors(img, mockRenderBox);

      // All remaining colors should be close to the gray (low chroma a/b)
      for (final lab in pruned) {
        expect(lab.a.abs(), lessThan(5.0),
            reason:
                'Outlier red pixel should have been pruned; found high a*=${lab.a}');
      }
    });

    test('getAverageColor returns a non-transparent color for a solid image',
        () {
      final img = solidColorImg(4, 4, 100, 150, 200);
      when(() => mockRenderBox.size).thenReturn(const Size(100, 100));
      final region = fullRegion(100, 100);
      final avg = region.getAverageColor(img, mockRenderBox);
      expect(avg.a, greaterThan(0.0));
      expect(avg.r, greaterThan(0.0));
    });
  });
}
