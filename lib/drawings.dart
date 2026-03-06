import 'package:flutter/material.dart';
import 'package:shadesmaster/analysis/color_extraction.dart';
import 'package:shadesmaster/analysis/comparison.dart';
import 'package:shadesmaster/utils/list_hashing.dart';
import 'package:shadesmaster/utils/rgb_to_lab.dart';
import 'package:shadesmaster/utils/simple_average_color.dart';
import 'package:shadesmaster/utils/unit_8_img.dart';

/// The following are the drawings that the user does
/// Each class also contains the manipulation on the
/// drawn pixels and on the colors of those pixels

class NormalizedOffset {
  /// Coordinates from 0.0 to 1.0 relative to image dimensions
  final Offset normalized;
  NormalizedOffset(this.normalized);

  Offset screenOffset(Size parentSize, Size imageSize) {
    final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, parentSize);
    final destinationSize = fittedSizes.destination;

    final left = (parentSize.width - destinationSize.width) / 2.0;
    final top = (parentSize.height - destinationSize.height) / 2.0;

    return Offset(
      left + normalized.dx * destinationSize.width,
      top + normalized.dy * destinationSize.height,
    );
  }

  Offset pixelOffset(Size imageSize) {
    return Offset(
      normalized.dx * imageSize.width,
      normalized.dy * imageSize.height,
    );
  }
}

class Stroke {
  List<NormalizedOffset> offsets;
  Stroke(this.offsets);

  int? _cacheKey;
  List<Offset>? _cachedPixelOffset;
  List<Offset>? _cachedScreenOffset;

  List<Offset> getPixelOffset(Size imageSize) {
    final key =
        Object.hash(listHash(offsets), imageSize.width, imageSize.height);
    if (_cacheKey == key && _cachedPixelOffset != null) {
      return _cachedPixelOffset!;
    }

    final List<Offset> result = [];
    for (var offset in offsets) {
      result.add(offset.pixelOffset(imageSize));
    }

    _cacheKey = key;
    _cachedPixelOffset = result;
    return result;
  }

  List<Offset> getScreenOffset(Size parentSize, Size imageSize) {
    final key = Object.hash(listHash(offsets), parentSize, imageSize);
    if (_cacheKey == key && _cachedScreenOffset != null) {
      return _cachedScreenOffset!;
    }

    final List<Offset> result = [];
    for (var offset in offsets) {
      result.add(offset.screenOffset(parentSize, imageSize));
    }

    _cacheKey = key;
    _cachedScreenOffset = result;
    return result;
  }
}

class Region extends Stroke {
  Region(super.offsets);

  List<Color>? _cachedColors;
  List<LabColor>? _cachedLabs;
  List<LabColor>? _cachedSortedLabs;
  List<LabColor>? _cachedSortedPrunedLabs;
  Color? _cachedAverage;

  List<Color> getColors(Unit8Img unit8Img) {
    final key = Object.hash(listHash(offsets), unit8Img.width, unit8Img.height);
    if (_cacheKey == key && _cachedColors != null) {
      return _cachedColors!;
    }
    final result = getAllColorsFromRegion(unit8Img, this);
    _cachedColors = result;
    return result;
  }

  List<LabColor> getLabColors(Unit8Img unit8Img) {
    final key = Object.hash(listHash(offsets), unit8Img.width, unit8Img.height);
    if (_cacheKey == key && _cachedLabs != null) {
      return _cachedLabs!;
    }
    final result = getColors(unit8Img).map((c) => rgbToLab(c)).toList();
    _cachedLabs = result;
    return result;
  }

  List<LabColor> getSortedLabColors(Unit8Img unit8Img) {
    final key = Object.hash(listHash(offsets), unit8Img.width, unit8Img.height);
    if (_cacheKey == key && _cachedSortedLabs != null) {
      return _cachedSortedLabs!;
    }
    final result = getLabColors(unit8Img)
      ..sort((l1, l2) => (l1.l - l2.l).toInt());
    _cachedSortedLabs = result;
    return result;
  }

  List<LabColor> getSortedPrunedLabColors(Unit8Img unit8Img) {
    final key = Object.hash(listHash(offsets), unit8Img.width, unit8Img.height);
    if (_cacheKey == key && _cachedSortedPrunedLabs != null) {
      return _cachedSortedPrunedLabs!;
    }
    final justSorted = getSortedLabColors(unit8Img);
    if (justSorted.isEmpty) return [];

    final medianColor = justSorted[(justSorted.length / 2).floor()];
    final result = justSorted.where((labColor) {
      final delta = deltaE(labColor, medianColor);
      return delta < 3.5; // this number has been fine-tuned, try not to touch
    }).toList();
    _cachedSortedPrunedLabs = result;
    return result;
  }

  Color getAverageColor(Unit8Img unit8Img) {
    final key = Object.hash(listHash(offsets), unit8Img.width, unit8Img.height);
    if (_cacheKey == key && _cachedAverage != null) {
      return _cachedAverage!;
    }
    final colors = getColors(unit8Img);
    if (colors.isEmpty) return Colors.transparent;
    final result = simpleAverageColor(colors);
    _cachedAverage = result;
    return result;
  }
}
