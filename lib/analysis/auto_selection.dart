import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shadesmaster/analysis/comparison.dart';
import 'package:shadesmaster/drawings.dart';
import 'package:shadesmaster/utils/rgb_to_lab.dart';
import 'package:shadesmaster/utils/unit_8_img.dart';

/// Finds a connected region of similar color starting from [startNormalized].
/// Uses BFS and Delta E color distance.
Region findSimilarRegion(
  Unit8Img img,
  NormalizedOffset startNormalized, {
  double threshold = 7,
}) {
  final int width = img.width;
  final int height = img.height;
  final List<int> pixels = img.pixels;

  final startX =
      (startNormalized.normalized.dx * width).floor().clamp(0, width - 1);
  final startY =
      (startNormalized.normalized.dy * height).floor().clamp(0, height - 1);

  final startColor = _getColorAt(pixels, startX, startY, width);
  final startLab = rgbToLab(startColor);

  final Set<int> visited = {};
  final Queue<int> queue = Queue();

  final startId = startY * width + startX;
  queue.add(startId);
  visited.add(startId);

  final List<int> regionPixels = [];
  double totalDelta = 0;

  while (queue.isNotEmpty && regionPixels.length < pixels.length / 4) {
    final currentId = queue.removeFirst();
    regionPixels.add(currentId);

    final cx = currentId % width;
    final cy = currentId ~/ width;

    // 4-connectivity
    final neighbors = [
      if (cx > 0) currentId - 1,
      if (cx < width - 1) currentId + 1,
      if (cy > 0) currentId - width,
      if (cy < height - 1) currentId + width,
    ];

    // Adaptive threshold: as we find more pixels, we become more sensitive
    // to prevent bleeding. We use a combination of region size and
    // average similarity to tighten the threshold.
    double decayFactor =
        (regionPixels.length / (width * height * 0.05)).clamp(0.0, 0.8);

    // Calculate average delta of pixels found so far to gauge regional consistency
    double avgDelta =
        regionPixels.length > 1 ? totalDelta / regionPixels.length : 0;
    // If the region is very uniform (low avgDelta), we tighten the threshold further
    double similarityFactor = regionPixels.length > 10
        ? (0.7 + 0.3 * (avgDelta / threshold).clamp(0.0, 1.0))
        : 1.0;

    double currentThreshold =
        threshold * (1.0 - (decayFactor * 0.5)) * similarityFactor;

    for (final neighborId in neighbors) {
      if (!visited.contains(neighborId)) {
        visited.add(neighborId);
        final nx = neighborId % width;
        final ny = neighborId ~/ width;
        final neighborColor = _getColorAt(pixels, nx, ny, width);
        final neighborLab = rgbToLab(neighborColor);

        final delta = deltaE(startLab, neighborLab);
        if (delta < currentThreshold) {
          queue.add(neighborId);
          totalDelta += delta;
        }
      }
    }
  }

  if (regionPixels.isEmpty) return Region([]);

  // Convert pixels to a polygon (rough boundary)
  final boundaryPoints = _traceBoundary(regionPixels, width, height);

  // Normalize points back to 0.0-1.0
  final List<NormalizedOffset> normalizedOffsets = boundaryPoints.map((p) {
    return NormalizedOffset(Offset(p.dx / width, p.dy / height));
  }).toList();

  return Region(normalizedOffsets);
}

Color _getColorAt(List<int> pixels, int x, int y, int width) {
  final index = (y * width + x) * 4;
  return Color.fromARGB(
    255,
    pixels[index],
    pixels[index + 1],
    pixels[index + 2],
  );
}

/// Traces the boundary of a set of pixels and returns an ordered list of points.
/// This is a simplified boundary tracing.
List<Offset> _traceBoundary(List<int> pixelIds, int width, int height) {
  if (pixelIds.isEmpty) return [];

  final pixelSet = Set<int>.from(pixelIds);

  // Find an initial boundary pixel (leftmost of the topmost pixels)
  int startId = pixelIds.first;
  int minY = startId ~/ width;
  for (final id in pixelIds) {
    int y = id ~/ width;
    if (y < minY) {
      minY = y;
      startId = id;
    } else if (y == minY) {
      if (id % width < startId % width) {
        startId = id;
      }
    }
  }

  // Moore-Neighbor Tracing (simplified)
  // Directions: 0:N, 1:NE, 2:E, 3:SE, 4:S, 5:SW, 6:W, 7:NW
  final dx = [0, 1, 1, 1, 0, -1, -1, -1];
  final dy = [-1, -1, 0, 1, 1, 1, 0, -1];

  List<Offset> contour = [];
  int currentId = startId;
  int enterDir = 6; // Came from West (if we start at topmost-leftmost)

  int iterations = 0;
  final maxIterations = pixelIds.length * 2;

  do {
    int cx = currentId % width;
    int cy = currentId ~/ width;
    contour.add(Offset(cx.toDouble(), cy.toDouble()));

    int nextId = -1;
    int nextDir = -1;

    // Clockwise scan starting from where we entered
    for (int i = 0; i < 8; i++) {
      int dir = (enterDir + i) % 8;
      int nx = cx + dx[dir];
      int ny = cy + dy[dir];

      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        int nid = ny * width + nx;
        if (pixelSet.contains(nid)) {
          nextId = nid;
          nextDir = dir;
          break;
        }
      }
    }

    if (nextId == -1 || nextId == currentId) break;

    currentId = nextId;
    // Enter direction for next pixel: (current scan direction + 4 + 1) % 8?
    // Actually, simple is: start scan from (nextDir + 4 + 2) % 8 or similar.
    // The standard Moore tracer says: scan begins at the pixel which was checked
    // immediately before the current pixel was found.
    enterDir = (nextDir + 5) % 8;

    iterations++;
  } while (currentId != startId && iterations < maxIterations);

  // Simplify contour if too many points
  if (contour.length > 20) {
    // First, use Douglas-Peucker for intelligent simplification
    List<Offset> simplified = _douglasPeucker(contour, 1.5);

    // Subdivide to ensure handle rounded shapes better
    List<Offset> subdivided = _subdivideContour(simplified);
    if (subdivided.length < 20) {
      subdivided = _subdivideContour(subdivided);
    }

    // Then, apply Laplacian smoothing to make it "ovoid" and smooth
    List<Offset> smoothed = _smoothContour(subdivided, iterations: 15);

    // Finally, if it's still too many points for the UI, sample it
    if (smoothed.length > 50) {
      return _simplifyBySampling(smoothed, 50);
    }
    return smoothed;
  }

  return contour;
}

/// Douglas-Peucker algorithm for contour simplification.
List<Offset> _douglasPeucker(List<Offset> points, double epsilon) {
  if (points.length < 3) return points;

  int index = -1;
  double dmax = 0;

  for (int i = 1; i < points.length - 1; i++) {
    double d = _perpendicularDistance(points[i], points.first, points.last);
    if (d > dmax) {
      index = i;
      dmax = d;
    }
  }

  if (dmax > epsilon) {
    List<Offset> recResults1 =
        _douglasPeucker(points.sublist(0, index + 1), epsilon);
    List<Offset> recResults2 = _douglasPeucker(points.sublist(index), epsilon);

    return [...recResults1.sublist(0, recResults1.length - 1), ...recResults2];
  } else {
    return [points.first, points.last];
  }
}

double _perpendicularDistance(Offset p, Offset a, Offset b) {
  double area =
      ((b.dy - a.dy) * p.dx - (b.dx - a.dx) * p.dy + b.dx * a.dy - b.dy * a.dx)
          .abs();
  double bottom =
      math.sqrt(math.pow(b.dy - a.dy, 2) + math.pow(b.dx - a.dx, 2));
  return area / bottom;
}

/// Laplacian smoothing for contours (averages each point with its neighbors).
List<Offset> _smoothContour(List<Offset> contour, {int iterations = 1}) {
  if (contour.length < 3) return contour;

  List<Offset> current = List.from(contour);

  for (int iter = 0; iter < iterations; iter++) {
    List<Offset> next = [];
    for (int i = 0; i < current.length; i++) {
      final prev = current[(i - 1 + current.length) % current.length];
      final curr = current[i];
      final nxt = current[(i + 1) % current.length];

      // Weight neighbors to pull towards a smoother line
      next.add(Offset(
        (prev.dx + curr.dx * 2 + nxt.dx) / 4.0,
        (prev.dy + curr.dy * 2 + nxt.dy) / 4.0,
      ));
    }
    current = next;
  }

  return current;
}

List<Offset> _subdivideContour(List<Offset> contour) {
  if (contour.length < 2) return contour;
  List<Offset> result = [];
  for (int i = 0; i < contour.length; i++) {
    final a = contour[i];
    final b = contour[(i + 1) % contour.length];
    result.add(a);
    result.add(Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2));
  }
  return result;
}

List<Offset> _simplifyBySampling(List<Offset> contour, int targetPoints) {
  if (contour.length <= targetPoints) return contour;

  double step = contour.length / targetPoints;
  return List.generate(targetPoints, (i) => contour[(i * step).floor()]);
}
