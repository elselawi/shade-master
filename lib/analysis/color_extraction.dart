import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shadesmaster/drawings.dart';
import 'package:shadesmaster/utils/unit_8_img.dart';

/// Extracts all unique colors from pixels within a polygonal region.
///
/// This function finds the bounding box of the region, then tests each pixel
/// within that box to see if it's inside the polygon. For pixels inside,
/// it extracts the RGB color value.
///
/// Time complexity: O(w * h * n) where w,h are bounding box dimensions and n is polygon vertices
/// Space complexity: O(k) where k is the number of unique colors found
///
/// [pixels] RGBA pixel data in row-major order (4 bytes per pixel: R,G,B,A)
/// [region] List of vertices defining the polygonal region
/// [width] Width of the image in pixels
/// [height] Height of the image in pixels
///
/// Returns a list of unique Color objects found within the region
List<Color> getAllColorsFromRegion(Unit8Img unit8Img, Region region) {
  final pixels = unit8Img.pixels;
  final width = unit8Img.width;
  final height = unit8Img.height;

  // Early returns for invalid input
  if (region.offsets.isEmpty || pixels.isEmpty) return [];
  if (width <= 0 || height <= 0) return [];

  // Ensure we have enough pixel data (4 bytes per pixel for RGBA)
  final expectedPixelCount = width * height * 4;
  if (pixels.length < expectedPixelCount) return [];

  final List<Color> extractedColors = <Color>[];

  final pixelOffsets =
      region.getPixelOffset(Size(width.toDouble(), height.toDouble()));

  // Calculate bounding box of the region
  final boundingBox = calculateBoundingBox(pixelOffsets);

  // Clamp bounding box to image dimensions for safety
  final startX = math.max(0, boundingBox.left.floor());
  final endX = math.min(width - 1, boundingBox.right.ceil());
  final startY = math.max(0, boundingBox.top.floor());
  final endY = math.min(height - 1, boundingBox.bottom.ceil());

  // Pre-allocate Offset object to avoid repeated allocation in inner loop
  Offset currentPoint = Offset(0, 0);

  // Scan all pixels within the bounding box
  for (int x = startX; x <= endX; x++) {
    for (int y = startY; y <= endY; y++) {
      // Reuse the same Offset object for better performance
      currentPoint = Offset(x.toDouble(), y.toDouble());

      if (isPointInPolygon(currentPoint, pixelOffsets)) {
        final color = _extractColorAtPixel(pixels, x, y, width);
        if (color != null) {
          extractedColors.add(color);
        }
      }
    }
  }

  return extractedColors.toList();
}

/// Determines if a point is inside a polygon using the ray casting algorithm.
///
/// Uses the "even-odd rule" where a point is inside if a ray cast from the point
/// to infinity crosses an odd number of polygon edges.
///
/// Time complexity: O(n) where n is the number of polygon vertices
/// Space complexity: O(1)
///
/// [point] The point to test
/// [polygon] List of vertices defining the polygon (must have at least 3 points)
///
/// Returns true if the point is inside the polygon, false otherwise
bool isPointInPolygon(Offset point, List<Offset> polygon) {
  // Early return for invalid input
  if (polygon.length < 3) return false;

  bool isInside = false;
  final int vertexCount = polygon.length;

  // Cache point coordinates to avoid repeated property access
  final double px = point.dx;
  final double py = point.dy;

  // Start with the last vertex as the previous vertex
  int prevIndex = vertexCount - 1;

  for (int currentIndex = 0; currentIndex < vertexCount; currentIndex++) {
    final Offset currentVertex = polygon[currentIndex];
    final Offset prevVertex = polygon[prevIndex];

    // Cache vertex coordinates
    final double currentY = currentVertex.dy;
    final double prevY = prevVertex.dy;
    final double currentX = currentVertex.dx;
    final double prevX = prevVertex.dx;

    // Check if the horizontal ray from the point crosses this edge
    // Edge must straddle the horizontal line through the point
    // Using > instead of >= for one vertex avoids double-counting shared vertices
    final bool edgeStraddles = (currentY > py) != (prevY > py);

    if (edgeStraddles) {
      // Calculate x-coordinate where the edge intersects the horizontal ray
      // Using the line equation: x = x1 + (x2-x1) * (y-y1) / (y2-y1)
      final double intersectionX =
          prevX + (currentX - prevX) * (py - prevY) / (currentY - prevY);

      // If intersection is to the right of the point, we crossed an edge
      if (px < intersectionX) {
        isInside = !isInside;
      }
    }

    prevIndex = currentIndex;
  }
  return isInside;
}

/// Calculates the axis-aligned bounding box of a list of points.
///
/// [points] List of points to calculate bounding box for
///
/// Returns a Rect representing the bounding box
Rect calculateBoundingBox(List<Offset> points) {
  if (points.isEmpty) return Rect.zero;

  double minX = points.first.dx;
  double maxX = points.first.dx;
  double minY = points.first.dy;
  double maxY = points.first.dy;

  // Skip the first point since we already used it for initialization
  for (int i = 1; i < points.length; i++) {
    final point = points[i];
    final x = point.dx;
    final y = point.dy;

    if (x < minX) {
      minX = x;
    } else if (x > maxX) {
      maxX = x;
    }

    if (y < minY) {
      minY = y;
    } else if (y > maxY) {
      maxY = y;
    }
  }

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// Extracts the RGB color at a specific pixel coordinate.
///
/// [pixels] RGBA pixel data array
/// [x] X coordinate of the pixel
/// [y] Y coordinate of the pixel
/// [width] Width of the image
///
/// Returns a Color object or null if the pixel is out of bounds
Color? _extractColorAtPixel(Uint8List pixels, int x, int y, int width) {
  final pixelIndex = (y * width + x) * 4;

  // Bounds check - ensure we can read R, G, B components
  if (pixelIndex + 2 >= pixels.length) return null;

  return Color.fromARGB(
    255, // Full opacity - we're only extracting RGB values
    pixels[pixelIndex], // Red
    pixels[pixelIndex + 1], // Green
    pixels[pixelIndex + 2], // Blue
  );
}
