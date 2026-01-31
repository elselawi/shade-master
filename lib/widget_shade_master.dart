import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadesmaster/analysis/analyze.dart';
import 'package:shadesmaster/drawings.dart';
import 'package:shadesmaster/utils/int_to_letter.dart';
import 'package:shadesmaster/widget_pill.dart';
import 'package:shadesmaster/widget_selection_painter.dart';
import 'package:shadesmaster/widget_toolbar_button.dart';

enum SelectionType { none, teeth, shades }

const teethColor = Colors.tealAccent;
const shadesColor = Colors.purple;

class ShadeMaster extends StatefulWidget {
  final Uint8List img;
  final VoidCallback onClose;
  @override
  ShadeMasterState createState() => ShadeMasterState();
  const ShadeMaster({super.key, required this.img, required this.onClose});
}

class ShadeMasterState extends State<ShadeMaster> {
  final ValueNotifier<Stroke> _strokeNotifier = ValueNotifier(Stroke([]));
  final List<List<Region>> _allRegions = [[], []];
  final GlobalKey _imageKey = GlobalKey();
  final transformationController = TransformationController();
  double scale = 1;
  SelectionType _activeSelecting = SelectionType.none;
  bool _isAnalyzing = false;
  bool _showAreas = true;

  List<Region> get _regions => _allRegions[currentRegionIndex];
  int get currentRegionIndex => _activeSelecting == SelectionType.teeth ? 0 : 1;

  void _onPanStart(DragStartDetails details) {
    if (_activeSelecting == SelectionType.none) return;
    setState(
      () => _strokeNotifier.value = Stroke([GlobalOffset(details.globalPosition)]),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeSelecting == SelectionType.none) return;
    setState(() {
      _strokeNotifier.value = Stroke([..._strokeNotifier.value.offsets, GlobalOffset(details.globalPosition)]);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeSelecting == SelectionType.none) return;
    final stroke = Stroke(_strokeNotifier.value.offsets);
    setState(() {
      _regions.add(Region(stroke.offsets));
      _strokeNotifier.value = Stroke([]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            InteractiveViewer(
              maxScale: 200,
              minScale: 0.5,
              transformationController: transformationController,
              panEnabled: _activeSelecting == SelectionType.none,
              scaleEnabled: _activeSelecting == SelectionType.none,
              onInteractionEnd: (_) {
                setState(() {
                  scale = transformationController.value.getMaxScaleOnAxis();
                });
              },
              child: Stack(
                key: _imageKey,
                children: [
                  Positioned.fill(
                      child: Image.memory(
                    widget.img,
                    fit: BoxFit.contain,
                  )),
                  Positioned.fill(
                    child: _showAreas
                        ? GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: IgnorePointer(
                              ignoring: _activeSelecting == SelectionType.none,
                              child: LayoutBuilder(
                                  builder: (context, constraints) {
                                final renderObject = _imageKey.currentContext
                                    ?.findRenderObject();
                                if (renderObject is! RenderBox) {
                                  return const SizedBox
                                      .shrink(); // or some placeholder/error widget
                                }
                                final renderBox = renderObject;
                                return ValueListenableBuilder(
                                  valueListenable: _strokeNotifier,
                                  builder: (context, stroke, child) {
                                    return CustomPaint(
                                      painter: SelectionPainter(
                                        teethRegions: _allRegions[0],
                                        shadesRegions: _allRegions[1],
                                        currentStroke: stroke,
                                        activeType: _activeSelecting,
                                        renderBox: renderBox,
                                        resolution: scale,
                                      ),
                                    );
                                  }
                                );
                              }),
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            buildToolbar(constraints),
            if (_isAnalyzing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  Positioned buildToolbar(BoxConstraints constraints) {
    return Positioned(
      bottom: 20,
      width: constraints.maxWidth,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  if (_regions.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          isSelected: !_showAreas,
                          color: Colors.black87,
                          style: ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(Colors.white24)),
                          onPressed: () {
                            setState(() {
                              _showAreas = !_showAreas;
                              if (_showAreas == false) {
                                _activeSelecting = SelectionType.none;
                              }
                            });
                          },
                          selectedIcon:
                              HugeIcon(icon: HugeIcons.strokeRoundedView),
                          icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedViewOffSlash),
                        ),
                        SizedBox(width: 15),
                        Flexible(
                          child: Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            children: _regions.map((e) {
                              final int i = _regions.indexOf(e);
                              return Pill(
                                label: _activeSelecting == SelectionType.teeth
                                    ? "Tooth ${i + 1}"
                                    : "Shade ${intToLetter(i + 1)}",
                                color: _activeSelecting == SelectionType.teeth
                                    ? teethColor.shade100
                                    : shadesColor.shade100,
                                onClose: () {
                                  setState(() {
                                    _regions.removeAt(i);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  if (_regions.isNotEmpty) SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ToolbarButton(
                        icon:
                            HugeIcon(icon: HugeIcons.strokeRoundedDentalTooth),
                        label: "Draw Teeth",
                        isActive: _activeSelecting == SelectionType.teeth,
                        onPress: () {
                          setState(() {
                            _activeSelecting =
                                _activeSelecting == SelectionType.teeth
                                    ? SelectionType.none
                                    : SelectionType.teeth;
                            _showAreas = true;
                          });
                        },
                        activeColor: teethColor,
                      ),
                      ToolbarButton(
                        icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedPinLocation02),
                        label: "Draw Shades",
                        isActive: _activeSelecting == SelectionType.shades,
                        onPress: () {
                          setState(() {
                            _activeSelecting =
                                _activeSelecting == SelectionType.shades
                                    ? SelectionType.none
                                    : SelectionType.shades;
                            _showAreas = true;
                          });
                        },
                        activeColor: shadesColor,
                      ),
                      if (_allRegions[0].isNotEmpty &&
                          _allRegions[1].isNotEmpty)
                        ToolbarButton(
                          icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedMarketAnalysis),
                          label: "Start Analyze",
                          isActive: false,
                          onPress: () async {
                            final renderObject =
                                _imageKey.currentContext?.findRenderObject();
                            final renderBox = renderObject as RenderBox?;
                            setState(() => _isAnalyzing = true);
                            final results = await analyze(_allRegions[0],
                                _allRegions[1], widget.img, renderBox!);
                            showResultsDialog(results);
                            setState(() => _isAnalyzing = false);
                          },
                          activeColor: Colors.orange,
                        ),
                      ToolbarButton(
                        icon: HugeIcon(icon: HugeIcons.strokeRoundedLogout02),
                        label: "Close image",
                        isActive: false,
                        onPress: widget.onClose,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  showResultsDialog(List<ShadeResult> results) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color Matches'),
        content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      selected: results[index].winner,
                      selectedColor: Colors.green,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: results[index].averageColor,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward),
                        ],
                      ),
                      title: Text('Shade ${results[index].name}'),
                      subtitle:
                          Text('Similarity: ${results[index].similarity}%'),
                      trailing: results[index].winner
                          ? Text("Winner")
                          : SizedBox.shrink(),
                    ),
                  );
                })),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
