import 'package:flutter/material.dart';

/// Spacing, radius, and shadow tokens.
class QDSpace {
  QDSpace._();
  static const double x1  = 4;
  static const double x2  = 8;
  static const double x3  = 12;
  static const double x4  = 16;
  static const double x5  = 20;
  static const double x6  = 24;
  static const double x8  = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;

  // Semantic aliases
  static const double screenPad   = x4; // 16 — screen edge padding
  static const double cardPad     = x4; // 16 — card internal padding
  static const double cardGap     = x3; // 12 — gap between cards
  static const double sectionGap  = x6; // 24 — gap between sections
  static const double inlineGap   = x2; // 8  — gap between inline elements
}

class QDRadius {
  QDRadius._();
  static const double xs   = 8;
  static const double sm   = 12;
  static const double md   = 16;
  static const double lg   = 20;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double full = 9999;

  // Semantic aliases
  static const double badge     = xs;    // 8
  static const double card      = sm;    // 12
  static const double button    = sm;    // 12
  static const double input     = sm;    // 12
  static const double searchBar = full;  // pill
  static const double avatar    = sm;    // 12 squircle-ish
  static const double sheet     = xl;    // 24 top corners
  static const double chip      = full;  // pill badge
  static const double iconChip  = xs;    // 8
}

class QDShadow {
  QDShadow._();

  /// Level 0: flat — no shadow, just a 1px border
  static const List<BoxShadow> none = [];

  /// Level 1: subtle card lift
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 2: elevated card / hover state
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Level 3: floating modal / bottom sheet
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 8,
      offset: Offset(0, -2),
    ),
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];
}
