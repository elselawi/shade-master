import 'package:flutter/material.dart';

class ToolbarButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final void Function()? onPress;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    this.activeColor = Colors.amber,
    this.isActive = false,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: GestureDetector(
        onTap: onPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isActive
                    ? activeColor.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1.5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
