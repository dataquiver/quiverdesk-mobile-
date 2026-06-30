import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/design_system/design_system.dart';

class QDStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? trend;
  final bool trendUp;

  const QDStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.trend,
    this.trendUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(QDSpace.cardPad),
        decoration: BoxDecoration(
          color: QDPalette.surfaceCard,
          borderRadius: BorderRadius.circular(QDRadius.card),
          border: Border.all(color: QDPalette.neutral100),
          boxShadow: QDShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(QDRadius.iconChip),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: QDPalette.neutral900,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: QDPalette.neutral400,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trend != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    trendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: trendUp ? QDPalette.success500 : QDPalette.error500,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trendUp ? QDPalette.success700 : QDPalette.error700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
