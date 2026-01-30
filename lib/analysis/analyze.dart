import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadesmaster/analysis/comparison.dart';
import 'package:shadesmaster/drawings.dart';
import 'package:shadesmaster/utils/int_to_letter.dart';
import 'package:shadesmaster/utils/rgb_to_lab.dart';
import 'package:shadesmaster/utils/unit_8_img.dart';

/// Analysis algorithm:
///
/// Let's say the user selected multiple regions of shade, and they
/// selected multiple regions of teeth.
///
/// Goal: to find out which shade region is the most visually similar
/// to the selected teeth. i.e. we must have one winner.
///
/// 1.  Extract all colors from all regions
/// 2.  The colors of each region is converted to CIELAB
/// 3.  They are then sorted according to their lightness
/// 4.  erroneous colors that are way out of the average color are pruned
/// 5.  the regions in all teeth are merged into a single region
/// 6.  the single tooth region is compacted to be of a similar
///       size to other regions this is done by sorting the colors
///       in the teeth region and taking an even sample
/// 7.  A special function is then used to calculate DelateE2000
///     (which represent visual distance) for groups
///     visual distance for groups is done by aligning the two
///     regions to each other, and comparing colors that are on
///     the same order of lightness.
///
///

Future<List<ShadeResult>> analyze(
  List<Region> teethRegions,
  List<Region> shadesRegions,
  String imgPath,
  RenderBox renderBox,
) async {
  // load the image to get all pixel data
  final unit8Img = await loadUnit8ImgFromBytes(await XFile(imgPath).readAsBytes());

  // extract all dental colors into a single palette
  final List<LabColor> dentalColors = [];
  for (var toothRegion in teethRegions) {
    dentalColors.addAll(toothRegion.getSortedPrunedLabColors(unit8Img, renderBox));
  }

  // then sort this one palette
  dentalColors.sort((labColorA, labColorB) => (labColorA.l - labColorB.l).toInt());

  // find average number of colors in a shade region
  int totalLength = 0;
  for (var shadeRegion in shadesRegions) {
    totalLength = totalLength + shadeRegion.getColors(unit8Img, renderBox).length;
  }
  final averageShadeSize = (totalLength / shadesRegions.length).toInt();

  // get an even sample from the one large teeth palette
  final dentalColorsSample = _evenlySample(dentalColors, averageShadeSize);

  final List<double> deltas = [];
  for (var shadeRegion in shadesRegions) {
    deltas.add(deltaGroups(dentalColorsSample, shadeRegion.getSortedPrunedLabColors(unit8Img, renderBox)));
  }

  final winner = deltas.reduce((a, b) => a < b ? a : b);

  final List<ShadeResult> results = [];

  for (var i = 0; i < deltas.length; i++) {
    results.add(
      ShadeResult(
        intToLetter(i + 1),
        deltas[i],
        shadesRegions[i].getAverageColor(unit8Img, renderBox),
        deltas[i] == winner,
      ),
    );
  }

  return results;
}

class ShadeResult {
  final String name;
  final double delta;
  final Color averageColor;
  final bool winner;

  ShadeResult(this.name, this.delta, this.averageColor, this.winner);

  double get similarity {
    return (10000 - (delta * 10000)).toInt() / 100;
  }
}

List<T> _evenlySample<T>(List<T> list, int targetSize) {
  if (targetSize >= list.length) return List.from(list);

  double step = (list.length - 1) / (targetSize - 1);
  return List.generate(targetSize, (i) => list[(i * step).round()]);
}
