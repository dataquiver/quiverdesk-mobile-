import 'package:flutter/material.dart';

/// Extended color palette — supplements the existing QDColors in themes.dart.
/// Provides the full token set for the redesigned design system.
class QDPalette {
  QDPalette._();

  // ── Brand / Primary (Indigo scale) ─────────────────────────────────────
  static const primary50  = Color(0xFFEEF2FF);
  static const primary100 = Color(0xFFE0E7FF);
  static const primary200 = Color(0xFFC7D2FE);
  static const primary300 = Color(0xFFA5B4FC);
  static const primary400 = Color(0xFF818CF8);
  static const primary500 = Color(0xFF6366F1); // brand colour
  static const primary600 = Color(0xFF4F46E5);
  static const primary700 = Color(0xFF4338CA);
  static const primary800 = Color(0xFF3730A3);
  static const primary900 = Color(0xFF312E81);

  // ── Neutral / Warm-grey scale ───────────────────────────────────────────
  static const neutral0   = Color(0xFFFAFAF9); // app background (off-white)
  static const neutral50  = Color(0xFFF5F5F4);
  static const neutral100 = Color(0xFFE7E5E4);
  static const neutral200 = Color(0xFFD6D3D1);
  static const neutral300 = Color(0xFFA8A29E);
  static const neutral400 = Color(0xFF78716C);
  static const neutral500 = Color(0xFF57534E);
  static const neutral600 = Color(0xFF44403C);
  static const neutral700 = Color(0xFF292524);
  static const neutral800 = Color(0xFF1C1917);
  static const neutral900 = Color(0xFF0C0A09); // off-black

  // ── Surface hierarchy ───────────────────────────────────────────────────
  static const surfaceBackground = neutral0;
  static const surfaceCard       = Color(0xFFFFFFFF);
  static const surfaceElevated   = Color(0xFFFFFFFF);
  static const surfaceOverlay    = Color(0xFFFFFFFF);

  // ── Semantic — Success (Emerald) ────────────────────────────────────────
  static const successBg   = Color(0xFFECFDF5);
  static const success200  = Color(0xFFA7F3D0);
  static const success500  = Color(0xFF10B981);
  static const success700  = Color(0xFF047857);

  // ── Semantic — Warning (Amber) ──────────────────────────────────────────
  static const warningBg   = Color(0xFFFFFBEB);
  static const warning200  = Color(0xFFFDE68A);
  static const warning500  = Color(0xFFF59E0B);
  static const warning700  = Color(0xFFB45309);

  // ── Semantic — Error (Rose) ─────────────────────────────────────────────
  static const errorBg     = Color(0xFFFFF1F2);
  static const error200    = Color(0xFFFECDD3);
  static const error500    = Color(0xFFF43F5E);
  static const error700    = Color(0xFFBE123C);

  // ── Semantic — Info (Sky) ───────────────────────────────────────────────
  static const infoBg      = Color(0xFFF0F9FF);
  static const info200     = Color(0xFFBAE6FD);
  static const info500     = Color(0xFF0EA5E9);
  static const info700     = Color(0xFF0369A1);

  // ── Industry type palette (for business type chips & avatars) ───────────
  static const typeColors = {
    'DENTAL'      : _IndustryColor(Color(0xFF0EA5E9), Color(0xFFF0F9FF)),
    'SALON'       : _IndustryColor(Color(0xFFEC4899), Color(0xFFFDF2F8)),
    'BARBERSHOP'  : _IndustryColor(Color(0xFF8B5CF6), Color(0xFFF5F3FF)),
    'WELLNESS'    : _IndustryColor(Color(0xFF10B981), Color(0xFFECFDF5)),
    'SPA'         : _IndustryColor(Color(0xFFF59E0B), Color(0xFFFFFBEB)),
    'GYM'         : _IndustryColor(Color(0xFFEF4444), Color(0xFFFEF2F2)),
    'CLINIC'      : _IndustryColor(Color(0xFF14B8A6), Color(0xFFF0FDFA)),
    'RESTAURANT'  : _IndustryColor(Color(0xFFF97316), Color(0xFFFFF7ED)),
  };

  static _IndustryColor industryColor(String? type) =>
      typeColors[type?.toUpperCase()] ??
      const _IndustryColor(Color(0xFF6366F1), Color(0xFFEEF2FF));

  // ── Avatar gradient seeds (8 pairs, deterministic per name) ─────────────
  static const _gradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // indigo → violet
    [Color(0xFFEC4899), Color(0xFFF97316)], // pink → orange
    [Color(0xFF10B981), Color(0xFF06B6D4)], // emerald → cyan
    [Color(0xFFF59E0B), Color(0xFFEF4444)], // amber → red
    [Color(0xFF3B82F6), Color(0xFF6366F1)], // blue → indigo
    [Color(0xFF8B5CF6), Color(0xFFEC4899)], // violet → pink
    [Color(0xFF14B8A6), Color(0xFF10B981)], // teal → emerald
    [Color(0xFFE11D48), Color(0xFF7C3AED)], // rose → violet
  ];

  static List<Color> gradientForName(String name) {
    if (name.isEmpty) return _gradients[0];
    int hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return _gradients[hash % _gradients.length];
  }

  // ── Feature tile accent colours (More sheet) ────────────────────────────
  static const featureColors = {
    // Platform Admin features
    'Plans'          : _FeatureColor(Color(0xFF4F46E5), Color(0xFFEEF2FF)),
    'Payments'       : _FeatureColor(Color(0xFF10B981), Color(0xFFECFDF5)),
    'Vouchers'       : _FeatureColor(Color(0xFFF59E0B), Color(0xFFFFFBEB)),
    'Features'       : _FeatureColor(Color(0xFF8B5CF6), Color(0xFFF5F3FF)),
    'Reports'        : _FeatureColor(Color(0xFF0EA5E9), Color(0xFFF0F9FF)),
    'Notifications'  : _FeatureColor(Color(0xFFF43F5E), Color(0xFFFFF1F2)),
    // Business Owner features
    'Services'       : _FeatureColor(Color(0xFFEC4899), Color(0xFFFDF2F8)),
    'Staff'          : _FeatureColor(Color(0xFF8B5CF6), Color(0xFFF5F3FF)),
    'Inventory'      : _FeatureColor(Color(0xFFF97316), Color(0xFFFFF7ED)),
    'CRM'            : _FeatureColor(Color(0xFF0EA5E9), Color(0xFFF0F9FF)),
    'Memberships'    : _FeatureColor(Color(0xFF10B981), Color(0xFFECFDF5)),
    'Feedback'       : _FeatureColor(Color(0xFFF59E0B), Color(0xFFFFFBEB)),
    'Subscription'   : _FeatureColor(Color(0xFF4F46E5), Color(0xFFEEF2FF)),
    'Change Password': _FeatureColor(Color(0xFF57534E), Color(0xFFF5F5F4)),
    'My Profile'     : _FeatureColor(Color(0xFF44403C), Color(0xFFF5F5F4)),
  };

  static _FeatureColor featureColor(String label) =>
      featureColors[label] ??
      const _FeatureColor(Color(0xFF6366F1), Color(0xFFEEF2FF));
}

class _IndustryColor {
  final Color foreground;
  final Color background;
  const _IndustryColor(this.foreground, this.background);
}

class _FeatureColor {
  final Color icon;
  final Color background;
  const _FeatureColor(this.icon, this.background);
}
