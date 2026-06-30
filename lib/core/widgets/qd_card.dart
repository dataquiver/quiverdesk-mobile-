import 'package:flutter/material.dart';
import '../../app/themes.dart';

class QDCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const QDCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? QDColors.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: QDColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}
