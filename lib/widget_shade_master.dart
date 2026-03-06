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
import 'package:shadesmaster/models/history_item.dart';
import 'package:shadesmaster/services/history_service.dart';
import 'package:shadesmaster/widget_custom_input_dialog.dart';
import 'package:uuid/uuid.dart';

enum SelectionType { none, teeth, shades }

const teethColor = Colors.tealAccent;
const shadesColor = Colors.purple;

class ShadeMaster extends StatefulWidget {
  final Uint8List img;
  final VoidCallback onClose;
  final List<List<Region>>? initialRegions;
  final String? historyItemId;
  final String? historyItemName;
  @override
  ShadeMasterState createState() => ShadeMasterState();
  const ShadeMaster({
    super.key,
    required this.img,
    required this.onClose,
    this.initialRegions,
    this.historyItemId,
    this.historyItemName,
  });
}

class ShadeMasterState extends State<ShadeMaster> {
  final ValueNotifier<Stroke> _strokeNotifier = ValueNotifier(Stroke([]));
  late final List<List<Region>> _allRegions;
  String? _currentHistoryId;
  String? _currentHistoryName;
  final GlobalKey _imageKey = GlobalKey();
  final transformationController = TransformationController();
  double scale = 1;
  SelectionType _activeSelecting = SelectionType.none;
  bool _isAnalyzing = false;
  bool _showAreas = true;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _currentHistoryId = widget.historyItemId;
    _currentHistoryName = widget.historyItemName;
    if (widget.initialRegions != null) {
      _allRegions = widget.initialRegions!;
    } else {
      _allRegions = [[], []];
    }
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final unit8 = await decodeImageFromList(widget.img);
    if (mounted) {
      setState(() {
        _imageSize = Size(unit8.width.toDouble(), unit8.height.toDouble());
      });
    }
  }

  NormalizedOffset? _normalizePointerPosition(Offset localOffset) {
    if (_imageSize == null) return null;
    final renderObject = _imageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return null;

    final widgetSize = renderObject.size;
    final fittedSizes = applyBoxFit(BoxFit.contain, _imageSize!, widgetSize);
    final destinationSize = fittedSizes.destination;

    final left = (widgetSize.width - destinationSize.width) / 2.0;
    final top = (widgetSize.height - destinationSize.height) / 2.0;

    final normalizedDx = (localOffset.dx - left) / destinationSize.width;
    final normalizedDy = (localOffset.dy - top) / destinationSize.height;

    return NormalizedOffset(Offset(normalizedDx, normalizedDy));
  }

  Future<void> _autoSaveIfPossible() async {
    if (_currentHistoryId != null && _currentHistoryName != null) {
      final item = HistoryItem(
        id: _currentHistoryId!,
        name: _currentHistoryName!,
        timestamp: DateTime.now(),
        imageBytes: widget.img,
        regions: _allRegions,
      );
      await HistoryService.saveHistoryItem(item);
    }
  }

  List<Region> get _regions => _allRegions[currentRegionIndex];
  int get currentRegionIndex => _activeSelecting == SelectionType.teeth ? 0 : 1;

  int _pointers = 0;
  bool _isDrawing = false;

  void _onPointerDown(PointerDownEvent event) {
    if (_activeSelecting == SelectionType.none || _imageSize == null) return;
    _pointers++;

    if (_pointers == 1) {
      final normalized = _normalizePointerPosition(event.localPosition);
      if (normalized == null) return;

      _isDrawing = true;
      setState(
        () => _strokeNotifier.value = Stroke([normalized]),
      );
    } else {
      _isDrawing = false;
      setState(
        () => _strokeNotifier.value = Stroke([]),
      );
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activeSelecting == SelectionType.none ||
        !_isDrawing ||
        _imageSize == null) return;

    final normalized = _normalizePointerPosition(event.localPosition);
    if (normalized == null) return;

    final newOffsets =
        List<NormalizedOffset>.from(_strokeNotifier.value.offsets)
          ..add(normalized);

    _strokeNotifier.value = Stroke(newOffsets);
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointers--;
    if (_pointers < 0) _pointers = 0;
    if (_activeSelecting == SelectionType.none || _imageSize == null) return;

    if (_isDrawing && _pointers == 0) {
      _isDrawing = false;
      if (_strokeNotifier.value.offsets.length > 2) {
        final stroke = Stroke(_strokeNotifier.value.offsets);
        setState(() {
          _regions.add(Region(stroke.offsets));
          _strokeNotifier.value = Stroke([]);
        });
        _autoSaveIfPossible();
      } else {
        setState(() {
          _strokeNotifier.value = Stroke([]);
        });
      }
    }
  }

  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Session?"),
        content: const Text(
            "This will permanently remove this session from your history. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_currentHistoryId != null) {
        await HistoryService.deleteHistoryItem(_currentHistoryId!);
      }
      widget.onClose();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointers--;
    if (_pointers < 0) _pointers = 0;
    _isDrawing = false;
    setState(() {
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
              scaleEnabled: true,
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
                        ? Listener(
                            onPointerDown: _onPointerDown,
                            onPointerMove: _onPointerMove,
                            onPointerUp: _onPointerUp,
                            onPointerCancel: _onPointerCancel,
                            behavior: HitTestBehavior.translucent,
                            child: IgnorePointer(
                              ignoring: _activeSelecting == SelectionType.none,
                              child: LayoutBuilder(
                                  builder: (context, constraints) {
                                if (_imageSize == null) {
                                  return const SizedBox.shrink();
                                }
                                return ValueListenableBuilder(
                                    valueListenable: _strokeNotifier,
                                    builder: (context, stroke, child) {
                                      return CustomPaint(
                                        painter: SelectionPainter(
                                          teethRegions: _allRegions[0],
                                          shadesRegions: _allRegions[1],
                                          currentStroke: stroke,
                                          activeType: _activeSelecting,
                                          imageSize: _imageSize!,
                                          resolution: scale,
                                        ),
                                      );
                                    });
                              }),
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isAnalyzing
                    ? Container(
                        key: const ValueKey('analyzing'),
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Analyzing Image...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            buildHeader(constraints),
            buildToolbar(constraints),
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
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                                  _autoSaveIfPossible();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  if (_regions.isNotEmpty) SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ToolbarButton(
                          icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedDentalTooth),
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
                              setState(() => _isAnalyzing = true);
                              final results = await analyze(
                                  _allRegions[0], _allRegions[1], widget.img);
                              showResultsDialog(results);
                              setState(() => _isAnalyzing = false);
                            },
                            activeColor: Colors.orange,
                          ),
                        if (_allRegions[0].isNotEmpty ||
                            _allRegions[1].isNotEmpty)
                          ToolbarButton(
                            icon: HugeIcon(icon: HugeIcons.strokeRoundedEraser),
                            label: "Clear All",
                            isActive: false,
                            onPress: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Clear All?"),
                                  content: const Text(
                                      "This will remove all your selections."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _allRegions[0].clear();
                                          _allRegions[1].clear();
                                        });
                                        _autoSaveIfPossible();
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Clear"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            activeColor: Colors.red,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader(BoxConstraints constraints) {
    return Positioned(
      top: 20,
      width: constraints.maxWidth,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                      0.5), // Increased opacity for better readability with dark text
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: Colors.black87,
                      ),
                      onPressed: widget.onClose,
                      tooltip: "Exit",
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: GestureDetector(
                        onTap: () async {
                          final newName = await showCustomInputDialog(
                            context: context,
                            title: _currentHistoryId != null
                                ? "Edit Session Name"
                                : "Save Session",
                            initialValue: _currentHistoryName,
                            hintText: "Enter a name",
                          );

                          if (newName != null && newName.trim().isNotEmpty) {
                            setState(() {
                              if (_currentHistoryId == null) {
                                _currentHistoryId = const Uuid().v4();
                              }
                              _currentHistoryName = newName.trim();
                            });
                            await _autoSaveIfPossible();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentHistoryName ?? "Unsaved Session",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 8),
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedEdit02,
                                color: Colors.black54,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_currentHistoryId == null)
                      IconButton(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedFloppyDisk,
                          color: Colors.black87,
                        ),
                        onPressed: () async {
                          final name = await showCustomInputDialog(
                            context: context,
                            title: "Save Session",
                            hintText: "Enter a name",
                          );

                          if (name != null && name.trim().isNotEmpty) {
                            setState(() {
                              _currentHistoryId = const Uuid().v4();
                              _currentHistoryName = name.trim();
                            });
                            await _autoSaveIfPossible();
                          }
                        },
                        tooltip: "Save",
                      )
                    else
                      IconButton(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          color: Colors.redAccent,
                        ),
                        onPressed: _deleteSession,
                        tooltip: "Delete Session",
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showResultsDialog(List<ShadeResult> results) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Color Match Analysis',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final result = results[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: result.winner
                          ? Colors.green.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: result.winner
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: result.averageColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: result.averageColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: result.winner
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        'Shade ${result.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Match Confidence: ${result.similarity}%',
                        style: TextStyle(
                          color: result.winner
                              ? Colors.green[700]
                              : Colors.grey[600],
                          fontWeight: result.winner
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: result.winner
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "WINNER",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
