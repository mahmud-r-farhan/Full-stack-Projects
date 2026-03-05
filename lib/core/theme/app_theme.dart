import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════
//  Lumina Gallery Design Tokens — Liquid Crystal Theme
// ═══════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF6C63FF); // Electric Violet
  static const Color primaryLight = Color(0xFF9C95FF);
  static const Color primaryDark = Color(0xFF4A42CC);
  static const Color accent = Color(0xFF00D9FF); // Cyan glow
  static const Color accentWarm = Color(0xFFFF6B9D); // Rose
  static const Color accentGreen = Color(0xFF00E5A0); // Emerald

  // Dark surfaces (Glass)
  static const Color darkBg = Color(0xFF0A0A14);
  static const Color darkBg2 = Color(0xFF0F0F1E);
  static const Color darkSurface = Color(0xFF12121F);
  static const Color darkCard = Color(0xFF1A1A2E);
  static const Color darkCardHover = Color(0xFF252540);
  static const Color glassDark = Color(0x26FFFFFF); // 15% white
  static const Color glassDarkHeavy = Color(0x33FFFFFF); // 20% white
  static const Color glassBorder = Color(0x40FFFFFF); // 25% white
  static const Color glassBorderHeavy = Color(0x59FFFFFF); // 35% white

  // Light surfaces
  static const Color lightBg = Color(0xFFF8F9FE); // Cleaner off-white
  static const Color lightBg2 = Color(0xFFFBFCFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F2F8);
  static const Color lightCardHover = Color(0xFFE8ECFA);
  static const Color glassLight = Color(
    0x33FFFFFF,
  ); // Pure glass for light mode
  static const Color glassLightHeavy = Color(0x4DFFFFFF); // 30% white
  static const Color glassLightBorder = Color(0x66B0B0D0); // Subtler border
  static const Color glassLightBorderHeavy = Color(
    0x99909FB0,
  ); // Stronger border

  // Text (Dark Mode default)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0D0);
  static const Color textMuted = Color(0xFF6060A0);
  static const Color textDisabled = Color(0xFF404080);

  // Text (Light Mode)
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6060A0);
  static const Color textMutedLight = Color(0xFF9090C0);
  static const Color textDisabledLight = Color(0xFFB8B8D8);

  // Semantic
  static const Color success = Color(0xFF00E5A0);
  static const Color successLight = Color(0xFFD4FFED);
  static const Color error = Color(0xFFFF4C6A);
  static const Color errorLight = Color(0xFFFFD6DC);
  static const Color warning = Color(0xFFFFB347);
  static const Color warningLight = Color(0xFFFFEBD4);
  static const Color info = Color(0xFF00D9FF);
  static const Color infoLight = Color(0xFFD4F8FF);

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
  static const List<Color> neonGradient = [
    Color(0xFF00D9FF),
    Color(0xFF6C63FF),
    Color(0xFFFF6B9D),
  ];
}

// ───────────────────────────────────────────────────────────
//  Spacing & Typography Scale
// ───────────────────────────────────────────────────────────

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}

class AppElevation {
  static const double none = 0.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
}

// ───────────────────────────────────────────────────────────
//  Theme Builder
// ───────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData dark({
    bool isLiquidDesign = true,
    ColorScheme? dynamicScheme,
  }) {
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
        tertiary: AppColors.accentWarm,
        surface: AppColors.darkBg,
        onSurface: AppColors.textPrimary,
        outline: AppColors.glassBorder,
        outlineVariant: AppColors.textMuted,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: _buildTextTheme(Brightness.dark),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 26),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassDark,
        labelStyle: GoogleFonts.outfit(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: AppColors.glassBorder, width: 1),
        shape: isLiquidDesign
            ? const StadiumBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.outfit(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      extensions: [LiquidThemeExtension.dark(isLiquidDesign: isLiquidDesign)],
    );
  }

  static ThemeData light({
    bool isLiquidDesign = true,
    ColorScheme? dynamicScheme,
  }) {
    final base =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.lightBg,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: base.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        tertiary: AppColors.accentWarm,
        surface: AppColors.lightBg,
        onSurface: AppColors.textPrimaryLight,
        outline: AppColors.glassLightBorder,
        outlineVariant: AppColors.textMutedLight,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: _buildTextTheme(Brightness.light),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimaryLight,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryLight,
          size: 26,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMutedLight,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassLight,
        labelStyle: GoogleFonts.outfit(
          color: AppColors.textSecondaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: AppColors.glassLightBorder, width: 1),
        shape: isLiquidDesign
            ? const StadiumBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(
            color: AppColors.glassLightBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.glassLightBorder.withValues(alpha: 0.6),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: AppColors.glassLightBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(
            color: AppColors.glassLightBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(
          color: AppColors.textMutedLight,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: AppColors.textSecondaryLight,
          fontSize: 14,
        ),
      ),
      extensions: [LiquidThemeExtension.light(isLiquidDesign: isLiquidDesign)],
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;
    final secondaryColor = brightness == Brightness.dark
        ? AppColors.textSecondary
        : AppColors.textSecondaryLight;

    return GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.3,
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
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: secondaryColor,
        letterSpacing: 0.5,
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
    required this.isLiquidDesign,
  });

  const LiquidThemeExtension.dark({this.isLiquidDesign = true})
    : glassColor = AppColors.glassDark,
      glassBorderColor = AppColors.glassBorder,
      blurSigma = 20.0,
      cardRadius = AppRadius.xl,
      isPerformanceMode = false;

  const LiquidThemeExtension.light({this.isLiquidDesign = true})
    : glassColor = AppColors.glassLight,
      glassBorderColor = AppColors.glassLightBorder,
      blurSigma = 15.0,
      cardRadius = AppRadius.xl,
      isPerformanceMode = false;

  final Color glassColor;
  final Color glassBorderColor;
  final double blurSigma;
  final double cardRadius;
  final bool isPerformanceMode;
  final bool isLiquidDesign;

  @override
  LiquidThemeExtension copyWith({
    Color? glassColor,
    Color? glassBorderColor,
    double? blurSigma,
    double? cardRadius,
    bool? isPerformanceMode,
    bool? isLiquidDesign,
  }) {
    return LiquidThemeExtension(
      glassColor: glassColor ?? this.glassColor,
      glassBorderColor: glassBorderColor ?? this.glassBorderColor,
      blurSigma: blurSigma ?? this.blurSigma,
      cardRadius: cardRadius ?? this.cardRadius,
      isPerformanceMode: isPerformanceMode ?? this.isPerformanceMode,
      isLiquidDesign: isLiquidDesign ?? this.isLiquidDesign,
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
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      isPerformanceMode: t < 0.5 ? isPerformanceMode : other.isPerformanceMode,
      isLiquidDesign: t < 0.5 ? isLiquidDesign : other.isLiquidDesign,
    );
  }

  double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
