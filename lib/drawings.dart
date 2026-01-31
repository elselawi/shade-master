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

class GlobalOffset {
  Offset globalOffset;
  GlobalOffset(this.globalOffset);
  Offset screenOffset(RenderBox renderBox) {
    return renderBox.globalToLocal(globalOffset);
  }

  Offset pixelOffset(RenderBox renderBox, Unit8Img unit8Img) {
    final localOffset = screenOffset(renderBox);
    final widgetSize = renderBox.size;

    final imageWidth = unit8Img.width.toDouble();
    final imageHeight = unit8Img.height.toDouble();

    final scaleX = imageWidth / widgetSize.width;
    final scaleY = imageHeight / widgetSize.height;

    return Offset(localOffset.dx * scaleX, localOffset.dy * scaleY);
  }
}

class Stroke {
  List<GlobalOffset> offsets;
  Stroke(this.offsets);

  int? _cacheKey;
  List<Offset>? _cachedPixelOffset;
  List<Offset>? _cachedScreenOffset;

  List<Offset> getPixelOffset(RenderBox renderBox, Unit8Img unit8Img) {
    final key = listHash(offsets);
    if (_cacheKey == key && _cachedPixelOffset != null) {
      return _cachedPixelOffset!;
    }

    final List<Offset> result = [];
    for (var globalOffset in offsets) {
      result.add(globalOffset.pixelOffset(renderBox, unit8Img));
    }

    _cacheKey = key;
    _cachedPixelOffset = result;
    return result;
  }

  List<Offset> getScreenOffset(RenderBox renderBox) {
    final key = listHash(offsets);
    if (_cacheKey == key && _cachedScreenOffset != null) {
      return _cachedScreenOffset!;
    }

    final List<Offset> result = [];
    for (var globalOffset in offsets) {
      result.add(globalOffset.screenOffset(renderBox));
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

  List<Color> getColors(Unit8Img unit8Img, RenderBox renderBox) {
    final key = listHash(offsets);
    if (_cacheKey == key && _cachedColors != null) {
      return _cachedColors!;
    }
    final result = getAllColorsFromRegion(unit8Img, renderBox, this);
    _cachedColors = result;
    return result;
  }

  List<LabColor> getLabColors(Unit8Img unit8Img, RenderBox renderBox) {
    final key = listHash(offsets);
    if (_cacheKey == key && _cachedLabs != null) {
      return _cachedLabs!;
    }
    final result = getColors(unit8Img, renderBox).map((c) => rgbToLab(c)).toList();
    _cachedLabs = result;
    return result;
  }

  List<LabColor> getSortedLabColors(Unit8Img unit8Img, RenderBox renderBox) {
    final key = listHash(offsets);
    if (_cacheKey == key && _cachedSortedLabs != null) {
      return _cachedSortedLabs!;
    }
    final result = getLabColors(unit8Img, renderBox)..sort((l1, l2) => (l1.l - l2.l).toInt());
    _cachedSortedLabs = result;
    return result;
  }

  List<LabColor> getSortedPrunedLabColors(Unit8Img unit8Img, RenderBox renderBox) {
    final key = listHash(offsets);
    if (_cacheKey == key && _cachedSortedPrunedLabs != null) {
      return _cachedSortedPrunedLabs!;
    }
    final justSorted = getSortedLabColors(unit8Img, renderBox);
    final medianColor = justSorted[(justSorted.length / 2).floor()];
    final result = justSorted.where((labColor) => deltaE(labColor, medianColor) < 1).toList();
    _cachedSortedPrunedLabs = result;
    return result;
  }

  Color getAverageColor(Unit8Img unit8Img, RenderBox renderBox) {
    final key = listHash(offsets);
    if (_cacheKey == key && _cachedAverage != null) {
      return _cachedAverage!;
    }
    final result = simpleAverageColor(getColors(unit8Img, renderBox));
    _cachedAverage = result;
    return result;
  }
}
