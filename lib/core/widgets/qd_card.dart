import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/design_system/design_system.dart';

class QDCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final bool elevated;

  const QDCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius = QDRadius.card,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? QDPalette.surfaceCard,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(radius),
        splashColor: QDPalette.primary50,
        highlightColor: QDPalette.primary50.withValues(alpha: 0.5),
        child: Container(
          padding: padding ?? const EdgeInsets.all(QDSpace.cardPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: QDPalette.neutral100),
            boxShadow: elevated ? QDShadow.elevated : QDShadow.card,
          ),
          child: child,
        ),
      ),
    );
  }
}
