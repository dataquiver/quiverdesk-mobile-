import 'package:flutter/material.dart';
import '../qd_palette.dart';
import '../qd_tokens.dart';

/// Premium gradient avatar.
/// Derives a consistent, pleasant gradient from the [name] string so every
/// person/business always gets the same colour — without it ever being flat
/// single-colour or generic blue.
class QDAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double? fontSize;
  final double radius;

  const QDAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.fontSize,
    this.radius = QDRadius.avatar,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = QDPalette.gradientForName(name);
    final fs = fontSize ?? size * 0.38;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fs,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1,
        ),
      ),
    );
  }
}
