import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_system/design_system.dart';

class QDColors {
  // Legacy aliases — screens that haven't migrated yet still compile
  static const primary        = QDPalette.primary500;
  static const primaryDark    = QDPalette.primary700;
  static const primaryLight   = QDPalette.primary50;
  static const secondary      = QDPalette.primary400;
  static const secondaryLight = QDPalette.primary50;
  static const accent         = QDPalette.info500;
  static const success        = QDPalette.success500;
  static const successLight   = QDPalette.successBg;
  static const warning        = QDPalette.warning500;
  static const warningLight   = QDPalette.warningBg;
  static const error          = QDPalette.error500;
  static const errorLight     = QDPalette.errorBg;
  static const background     = QDPalette.surfaceBackground;
  static const surface        = QDPalette.surfaceCard;
  static const textPrimary    = QDPalette.neutral800;
  static const textSecondary  = QDPalette.neutral500;
  static const textHint       = QDPalette.neutral400;
  static const border         = QDPalette.neutral100;
  static const divider        = QDPalette.neutral50;

  // Status colors
  static const scheduled  = QDPalette.info500;
  static const confirmed  = QDPalette.success500;
  static const inProgress = QDPalette.warning500;
  static const completed  = QDPalette.success700;
  static const cancelled  = QDPalette.neutral400;
  static const noShow     = QDPalette.error700;
}

class QDTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: QDPalette.primary500,
        brightness: Brightness.light,
        primary: QDPalette.primary500,
        secondary: QDPalette.primary400,
        surface: QDPalette.surfaceCard,
        error: QDPalette.error500,
      ),
      scaffoldBackgroundColor: QDPalette.surfaceBackground,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: QDPalette.neutral900,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: QDPalette.neutral900,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: QDPalette.neutral900,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: QDPalette.neutral800,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: QDPalette.neutral800,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: QDPalette.neutral700,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: QDPalette.neutral600,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: QDPalette.neutral400,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: QDPalette.neutral800,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: QDPalette.surfaceCard,
        foregroundColor: QDPalette.neutral800,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: const Color(0x18000000),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: QDPalette.neutral900,
        ),
        iconTheme: const IconThemeData(color: QDPalette.neutral600, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QDPalette.primary500,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QDRadius.button),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QDPalette.primary500,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QDRadius.button),
          ),
          side: const BorderSide(color: QDPalette.primary500, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QDPalette.primary600,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: QDPalette.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.primary500, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.error500),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.error500, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: QDPalette.neutral400, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: QDPalette.neutral400, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: QDPalette.primary500, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: QDPalette.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QDRadius.card),
          side: const BorderSide(color: QDPalette.neutral100),
        ),
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x0D000000),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: QDPalette.surfaceCard,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return QDPalette.neutral300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return QDPalette.primary500;
          return QDPalette.neutral100;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: QDPalette.neutral50,
        selectedColor: QDPalette.primary100,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: QDPalette.neutral700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QDRadius.chip)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: const BorderSide(color: QDPalette.neutral100),
      ),
      dividerTheme: const DividerThemeData(
        color: QDPalette.neutral100,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: QDPalette.primary500,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: QDPalette.neutral800,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QDRadius.xs)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: QDPalette.primary500,
        unselectedLabelColor: QDPalette.neutral400,
        indicatorColor: QDPalette.primary500,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
        dividerColor: QDPalette.neutral100,
      ),
    );
  }
}
