import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════
//  LiquidSync Design Tokens — Liquid Crystal Theme
// ═══════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF6C63FF); // Electric Violet
  static const Color primaryLight = Color(0xFF9C95FF);
  static const Color accent = Color(0xFF00D9FF); // Cyan glow
  static const Color accentWarm = Color(0xFFFF6B9D); // Rose

  // Dark surfaces (Glass)
  static const Color darkBg = Color(0xFF0A0A14);
  static const Color darkSurface = Color(0xFF12121F);
  static const Color darkCard = Color(0xFF1A1A2E);
  static const Color glassDark = Color(0x26FFFFFF); // 15% white
  static const Color glassBorder = Color(0x40FFFFFF); // 25% white

  // Light surfaces
  static const Color lightBg = Color(0xFFF0F2FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color glassLight = Color(0x1A6C63FF); // 10% primary

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0D0);
  static const Color textMuted = Color(0xFF6060A0);

  // Semantic
  static const Color success = Color(0xFF00E5A0);
  static const Color error = Color(0xFFFF4C6A);
  static const Color warning = Color(0xFFFFB347);

  // Gradient stops
  static const List<Color> heroGradient = [
    Color(0xFF6C63FF),
    Color(0xFF00D9FF),
  ];
  static const List<Color> vaultGradient = [
    Color(0xFFFF6B9D),
    Color(0xFF6C63FF),
  ];
  static const List<Color> shareGradient = [
    Color(0xFF00D9FF),
    Color(0xFF00E5A0),
  ];
}

// ───────────────────────────────────────────────────────────
//  Theme Builder
// ───────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData dark({ColorScheme? dynamicScheme}) {
    final base =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.darkBg,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.darkBg,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: _buildTextTheme(Brightness.dark),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassDark,
        labelStyle: GoogleFonts.outfit(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        shape: const StadiumBorder(),
      ),
      extensions: const [LiquidThemeExtension.dark()],
    );
  }

  static ThemeData light({ColorScheme? dynamicScheme}) {
    final base =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: base.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightBg,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.darkBg,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkBg),
      ),
      extensions: const [LiquidThemeExtension.light()],
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? AppColors.textPrimary
        : AppColors.darkBg;

    return GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodyLarge: GoogleFonts.outfit(fontSize: 16, color: color),
      bodyMedium: GoogleFonts.outfit(fontSize: 14, color: color),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
//  Theme Extension for Liquid Glass tokens
// ───────────────────────────────────────────────────────────

class LiquidThemeExtension extends ThemeExtension<LiquidThemeExtension> {
  const LiquidThemeExtension({
    required this.glassColor,
    required this.glassBorderColor,
    required this.blurSigma,
    required this.cardRadius,
    required this.isPerformanceMode,
  });

  const LiquidThemeExtension.dark()
    : glassColor = AppColors.glassDark,
      glassBorderColor = AppColors.glassBorder,
      blurSigma = 20.0,
      cardRadius = 20.0,
      isPerformanceMode = false;

  const LiquidThemeExtension.light()
    : glassColor = AppColors.glassLight,
      glassBorderColor = const Color(0x406C63FF),
      blurSigma = 20.0,
      cardRadius = 20.0,
      isPerformanceMode = false;

  final Color glassColor;
  final Color glassBorderColor;
  final double blurSigma;
  final double cardRadius;
  final bool isPerformanceMode;

  @override
  LiquidThemeExtension copyWith({
    Color? glassColor,
    Color? glassBorderColor,
    double? blurSigma,
    double? cardRadius,
    bool? isPerformanceMode,
  }) {
    return LiquidThemeExtension(
      glassColor: glassColor ?? this.glassColor,
      glassBorderColor: glassBorderColor ?? this.glassBorderColor,
      blurSigma: blurSigma ?? this.blurSigma,
      cardRadius: cardRadius ?? this.cardRadius,
      isPerformanceMode: isPerformanceMode ?? this.isPerformanceMode,
    );
  }

  @override
  LiquidThemeExtension lerp(LiquidThemeExtension? other, double t) {
    if (other == null) return this;
    return LiquidThemeExtension(
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassBorderColor: Color.lerp(
        glassBorderColor,
        other.glassBorderColor,
        t,
      )!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t),
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t),
      isPerformanceMode: t < 0.5 ? isPerformanceMode : other.isPerformanceMode,
    );
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
