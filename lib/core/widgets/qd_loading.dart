import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/themes.dart';

class QDLoadingShimmer extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const QDLoadingShimmer({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: QDColors.border,
      highlightColor: QDColors.divider,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: QDColors.border,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// Shimmer card for list items
class QDLoadingCard extends StatelessWidget {
  const QDLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QDColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QDColors.border),
      ),
      child: Shimmer.fromColors(
        baseColor: QDColors.border,
        highlightColor: QDColors.divider,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: QDColors.border,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 14, width: double.infinity, color: QDColors.border),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 120, color: QDColors.border),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Container(height: 12, width: double.infinity, color: QDColors.border),
          ],
        ),
      ),
    );
  }
}

// Full screen loading indicator
class QDLoading extends StatelessWidget {
  final String? message;
  const QDLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: QDColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: QDColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
