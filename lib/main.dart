import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadesmaster/version.dart';
import 'package:shadesmaster/widget_shade_master.dart';
import 'package:shadesmaster/widget_primary_button.dart';

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

  void pickImage(bool camera) async {
    final target = await ImagePicker()
        .pickImage(source: camera ? ImageSource.camera : ImageSource.gallery);
    if (target != null) {
      final loadedImg = await target.readAsBytes();
      setState(() {
        imgPicked = loadedImg;
      });
    }
  }

  void closeImage() {
    setState(() {
      imgPicked = null;
    });
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
                        const SizedBox(height: 40),
                        buildPickerButtons(),
                        const SizedBox(height: 40),
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
