import 'package:flutter/material.dart';
import '../qd_palette.dart';
import '../qd_tokens.dart';

/// Semantic status chip — light-tint background + matching dark text.
/// Looks like: [ ● Active ] with a subtle pill background, never a
/// harsh solid-colour block.
class QDStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final bool showDot;

  const QDStatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
    this.showDot = true,
  });

  static Color colorFor(String status) {
    final upper = status.toUpperCase();
    return switch (upper) {
      'ACTIVE'     => QDPalette.success700,
      'TRIAL'      => QDPalette.warning700,
      'EXPIRED'    => QDPalette.error700,
      'SUSPENDED'  => QDPalette.error700,
      'PENDING'    => QDPalette.warning700,
      'PAID'       => QDPalette.success700,
      'FAILED'     => QDPalette.error700,
      'REFUNDED'   => QDPalette.info700,
      'BOOKED'     => QDPalette.info500,
      'SCHEDULED'  => QDPalette.info500,
      'CONFIRMED'  => QDPalette.success500,
      'COMPLETED'  => QDPalette.success700,
      'CANCELLED'  => QDPalette.neutral400,
      'NO_SHOW'    => QDPalette.error500,
      _            => QDPalette.neutral500,
    };
  }

  factory QDStatusChip.fromStatus(String status) {
    final upper = status.toUpperCase();
    final (Color fg, Color bg) = switch (upper) {
      'ACTIVE'     => (QDPalette.success700, QDPalette.successBg),
      'TRIAL'      => (QDPalette.warning700, QDPalette.warningBg),
      'EXPIRED'    => (QDPalette.error700,   QDPalette.errorBg),
      'SUSPENDED'  => (QDPalette.error700,   QDPalette.errorBg),
      'PENDING'    => (QDPalette.warning700, QDPalette.warningBg),
      'PAID'       => (QDPalette.success700, QDPalette.successBg),
      'FAILED'     => (QDPalette.error700,   QDPalette.errorBg),
      'REFUNDED'   => (QDPalette.info700,    QDPalette.infoBg),
      'BOOKED'     => (QDPalette.info500,    QDPalette.infoBg),
      'SCHEDULED'  => (QDPalette.info500,    QDPalette.infoBg),
      'CONFIRMED'  => (QDPalette.success500, QDPalette.successBg),
      'COMPLETED'  => (QDPalette.success700, QDPalette.successBg),
      'CANCELLED'  => (QDPalette.neutral500, QDPalette.neutral50),
      'NO_SHOW'    => (QDPalette.error700,   QDPalette.errorBg),
      _            => (QDPalette.neutral500, QDPalette.neutral50),
    };
    return QDStatusChip(label: status, color: fg, bgColor: bg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(QDRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Industry type chip with semantic colour coding per business category.
class QDIndustryChip extends StatelessWidget {
  final String type;

  const QDIndustryChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final c = QDPalette.industryColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(QDRadius.chip),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: c.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
