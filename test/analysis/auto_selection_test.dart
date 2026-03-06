import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/analysis/auto_selection.dart';
import 'package:shadesmaster/drawings.dart';
import 'package:shadesmaster/utils/unit_8_img.dart';

void main() {
  test('findSimilarRegion identifies a simple square', () {
    // Create a 10x10 image with a 4x4 red square in the middle
    final width = 10;
    final height = 10;
    final pixels = Uint8List(width * height * 4);

    // Fill with white background
    for (int i = 0; i < pixels.length; i += 4) {
      pixels[i] = 255;
      pixels[i + 1] = 255;
      pixels[i + 2] = 255;
      pixels[i + 3] = 255;
    }

    // Draw a 4x4 red square from (3,3) to (6,6)
    for (int y = 3; y <= 6; y++) {
      for (int x = 3; x <= 6; x++) {
        final index = (y * width + x) * 4;
        pixels[index] = 255; // R
        pixels[index + 1] = 0; // G
        pixels[index + 2] = 0; // B
        pixels[index + 3] = 255; // A
      }
    }

    final img = Unit8Img(pixels, height, width);
    final startOffset =
        NormalizedOffset(Offset(0.45, 0.45)); // inside the square (4.5, 4.5)

    final region = findSimilarRegion(img, startOffset, threshold: 5.0);

    // The region should have some points
    expect(region.offsets.isNotEmpty, true);

    // Check if points are roughly around the red square
    for (final offset in region.offsets) {
      final p = offset.normalized;
      expect(p.dx >= 0.25 && p.dx <= 0.75, true);
    }
  });

  test('findSimilarRegion handles a gentle gradient', () {
    final width = 20;
    final height = 20;
    final pixels = Uint8List(width * height * 4);

    // Fill with white
    for (int i = 0; i < pixels.length; i += 4) {
      pixels[i] = 255;
      pixels[i + 1] = 255;
      pixels[i + 2] = 255;
      pixels[i + 3] = 255;
    }

    // Draw a gradient box from (5,5) to (15,15)
    // R goes from 200 to 255
    for (int y = 5; y <= 15; y++) {
      for (int x = 5; x <= 15; x++) {
        final index = (y * width + x) * 4;
        pixels[index] = 200 + (x - 5) * 5; // R: 200 to 250
        pixels[index + 1] = 0;
        pixels[index + 2] = 0;
        pixels[index + 3] = 255;
      }
    }

    final img = Unit8Img(pixels, height, width);
    final startOffset = NormalizedOffset(Offset(0.25, 0.25)); // (5,5), R=200

    // Threshold 10 should be enough to cover the gradient if it adapts correctly
    final region = findSimilarRegion(img, startOffset, threshold: 15.0);

    expect(region.offsets.isNotEmpty, true);
    // It should capture at least some of the gradient
    expect(region.offsets.length > 10, true);
  });
}
