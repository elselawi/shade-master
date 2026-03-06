import 'dart:ui';
import 'package:flutter/material.dart';

class CustomInputDialog extends StatelessWidget {
  final String title;
  final String? initialValue;
  final String hintText;
  final String confirmLabel;
  final String cancelLabel;
  final Function(String) onConfirm;

  const CustomInputDialog({
    super.key,
    required this.title,
    this.initialValue,
    required this.hintText,
    this.confirmLabel = "Save",
    this.cancelLabel = "Cancel",
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialValue);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.black45),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        onConfirm(value.trim());
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          cancelLabel,
                          style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            onConfirm(controller.text.trim());
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> showCustomInputDialog({
  required BuildContext context,
  required String title,
  String? initialValue,
  required String hintText,
  String confirmLabel = "Save",
  String cancelLabel = "Cancel",
}) {
  String? result;
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black26,
    builder: (context) => CustomInputDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: (val) => result = val,
    ),
  ).then((_) => result);
}
