import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadesmaster/version.dart';
import 'package:shadesmaster/widget_shade_master.dart';
import 'package:shadesmaster/widget_primary_button.dart';
import 'package:shadesmaster/models/history_item.dart';
import 'package:shadesmaster/services/history_service.dart';
import 'package:shadesmaster/widget_custom_input_dialog.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shade Master',
      theme: ThemeData(
        colorScheme: ColorScheme.light(),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'Shade Master'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});
  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Uint8List? imgPicked;
  List<HistoryItem> _historyItems = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final items = await HistoryService.getHistoryItems();
    setState(() {
      _historyItems = items;
      _isLoadingHistory = false;
    });
  }

  void pickImage(bool camera) async {
    final target = await ImagePicker()
        .pickImage(source: camera ? ImageSource.camera : ImageSource.gallery);
    if (target != null) {
      final loadedImg = await target.readAsBytes();
      setState(() {
        _currentHistoryItem =
            null; // Clear active session when picking a new image
        imgPicked = loadedImg;
      });
    }
  }

  void closeImage() {
    setState(() {
      imgPicked = null;
      _currentHistoryItem = null;
    });
    _loadHistory(); // Refresh history when coming back
  }

  HistoryItem? _currentHistoryItem;

  void _openHistoryItem(HistoryItem item) {
    setState(() {
      _currentHistoryItem = item;
      imgPicked = item.imageBytes;
    });
  }

  Future<void> _deleteHistoryItem(HistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Session?"),
        content: Text(
            "Are you sure you want to delete session \"${item.name}\"? This cannot be undone."),
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
      await HistoryService.deleteHistoryItem(item.id);
      _loadHistory();
    }
  }

  Future<void> _renameHistoryItem(HistoryItem item) async {
    final newName = await showCustomInputDialog(
      context: context,
      title: "Rename Session",
      initialValue: item.name,
      hintText: "Enter a new name",
    );

    if (newName != null && newName.trim().isNotEmpty && newName != item.name) {
      final updatedItem = HistoryItem(
        id: item.id,
        name: newName.trim(),
        imageBytes: item.imageBytes,
        regions: item.regions,
        timestamp: DateTime.now(),
      );
      await HistoryService.saveHistoryItem(updatedItem);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: imgPicked != null
              ? ShadeMaster(
                  img: imgPicked!,
                  onClose: closeImage,
                  initialRegions: _currentHistoryItem?.regions,
                  historyItemId: _currentHistoryItem?.id,
                  historyItemName: _currentHistoryItem?.name,
                )
              : TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 1),
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Welcome to",
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          "Shade Master",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        buildPickerButtons(),
                        const SizedBox(height: 30),
                        if (_isLoadingHistory)
                          const CircularProgressIndicator()
                        else if (_historyItems.isNotEmpty) ...[
                          Text(
                            "Recent Sessions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _historyItems.length,
                              itemBuilder: (context, index) {
                                final item = _historyItems[index];
                                return GestureDetector(
                                  onTap: () => _openHistoryItem(item),
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius
                                                    .vertical(
                                                    top: Radius.circular(16)),
                                                child: Image.memory(
                                                  item.imageBytes,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    DateFormat(
                                                            'MMM d yyyy, HH:mm')
                                                        .format(item.timestamp),
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: colorScheme
                                                            .onSurfaceVariant),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Row(
                                            children: [
                                              _CircleIconButton(
                                                icon: HugeIcons
                                                    .strokeRoundedEdit02,
                                                onPressed: () =>
                                                    _renameHistoryItem(item),
                                                size: 24,
                                                iconSize: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              _CircleIconButton(
                                                icon: HugeIcons
                                                    .strokeRoundedDelete02,
                                                onPressed: () =>
                                                    _deleteHistoryItem(item),
                                                color: Colors.red
                                                    .withValues(alpha: 0.8),
                                                size: 24,
                                                iconSize: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        Text(
                          "Version $version • Developed by Dr. Ali A. Saleem",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
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

  Column buildPickerButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              "Start with a photo that shows both the teeth and the closest shades"),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PrimaryButton(
              onPressed: () => pickImage(true),
              title: "Use Camera",
              icon: Icons.camera_alt,
            ),
            SizedBox(width: 10),
            PrimaryButton(
              onPressed: () => pickImage(false),
              title: "Pick Image",
              icon: Icons.folder,
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final double iconSize;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 32,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.black.withValues(alpha: 0.3),
          ),
          child: Center(
            child: HugeIcon(
              icon: icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
