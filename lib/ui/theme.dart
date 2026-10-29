import 'package:flutter/material.dart';

/// Semantic colour tokens (DESIGN_SYSTEM.md §2.1): Obsidian Matte (dark) and
/// Warm Alabaster (light). Screens read them with `context.sb`, never with
/// hard-coded colours, so both modes stay in sync.
///
/// Beyond the spec's matrix: [survivalMagmaEnd] (the second stop of the
/// magma gradient), [accent] / [onAccent] (primary actions), [info] (neutral
/// charts and links) and [nudgeViolet] (the Nudge Bot studio).
@immutable
class SplitBurnTokens extends ThemeExtension<SplitBurnTokens> {
  const SplitBurnTokens({
    required this.canvas,
    required this.surfacePrimary,
    required this.surfaceElevated,
    required this.surfaceGlass,
    required this.hairlineBorder,
    required this.specularBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.safeMint,
    required this.survivalMagma,
    required this.survivalMagmaEnd,
    required this.owedToMe,
    required this.iOwe,
    required this.trialAmber,
    required this.thermalPaper,
    required this.accent,
    required this.onAccent,
    required this.info,
    required this.nudgeViolet,
    required this.shadow,
  });

  final Color canvas;
  final Color surfacePrimary;
  final Color surfaceElevated;
  final Color surfaceGlass;
  final Color hairlineBorder;
  final Color specularBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color safeMint;
  final Color survivalMagma;
  final Color survivalMagmaEnd;
  final Color owedToMe;
  final Color iOwe;
  final Color trialAmber;
  final Color thermalPaper;
  final Color accent;
  final Color onAccent;
  final Color info;
  final Color nudgeViolet;

  /// Soft card shadow (transparent in dark mode: depth comes from surfaces).
  final Color shadow;

  /// Ink on [thermalPaper], identical in both modes (paper is paper).
  static const thermalInk = Color(0xFF15161A);

  static const dark = SplitBurnTokens(
    canvas: Color(0xFF0E1014),
    surfacePrimary: Color(0xFF161920),
    surfaceElevated: Color(0xFF1E222B),
    surfaceGlass: Color(0xBF1E222B),
    hairlineBorder: Color(0x14FFFFFF),
    specularBorder: Color(0x2EFFFFFF),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    safeMint: Color(0xFF34D399),
    survivalMagma: Color(0xFFFB7185),
    survivalMagmaEnd: Color(0xFFF97316),
    owedToMe: Color(0xFF4ADE80),
    iOwe: Color(0xFFF87171),
    trialAmber: Color(0xFFFBBF24),
    thermalPaper: Color(0xFFF4F1EA),
    accent: Color(0xFF34D399),
    onAccent: Color(0xFF04140D),
    info: Color(0xFF60A5FA),
    nudgeViolet: Color(0xFFC084FC),
    shadow: Color(0x00000000),
  );

  static const light = SplitBurnTokens(
    canvas: Color(0xFFF7F5F0),
    surfacePrimary: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF0EDE6),
    surfaceGlass: Color(0xD9FFFFFF),
    hairlineBorder: Color(0x14141619),
    specularBorder: Color(0x26141619),
    textPrimary: Color(0xFF111317),
    textSecondary: Color(0xFF525866),
    textMuted: Color(0xFF8A909E),
    safeMint: Color(0xFF059669),
    survivalMagma: Color(0xFFE11D48),
    survivalMagmaEnd: Color(0xFFEA580C),
    owedToMe: Color(0xFF16A34A),
    iOwe: Color(0xFFDC2626),
    trialAmber: Color(0xFFD97706),
    thermalPaper: Color(0xFFF4F1EA),
    accent: Color(0xFF059669),
    onAccent: Color(0xFFFFFFFF),
    info: Color(0xFF2563EB),
    nudgeViolet: Color(0xFF9333EA),
    shadow: Color(0x0F141619),
  );

  @override
  SplitBurnTokens copyWith({
    Color? canvas,
    Color? surfacePrimary,
    Color? surfaceElevated,
    Color? surfaceGlass,
    Color? hairlineBorder,
    Color? specularBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? safeMint,
    Color? survivalMagma,
    Color? survivalMagmaEnd,
    Color? owedToMe,
    Color? iOwe,
    Color? trialAmber,
    Color? thermalPaper,
    Color? accent,
    Color? onAccent,
    Color? info,
    Color? nudgeViolet,
    Color? shadow,
  }) {
    return SplitBurnTokens(
      canvas: canvas ?? this.canvas,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      hairlineBorder: hairlineBorder ?? this.hairlineBorder,
      specularBorder: specularBorder ?? this.specularBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      safeMint: safeMint ?? this.safeMint,
      survivalMagma: survivalMagma ?? this.survivalMagma,
      survivalMagmaEnd: survivalMagmaEnd ?? this.survivalMagmaEnd,
      owedToMe: owedToMe ?? this.owedToMe,
      iOwe: iOwe ?? this.iOwe,
      trialAmber: trialAmber ?? this.trialAmber,
      thermalPaper: thermalPaper ?? this.thermalPaper,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      info: info ?? this.info,
      nudgeViolet: nudgeViolet ?? this.nudgeViolet,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  SplitBurnTokens lerp(ThemeExtension<SplitBurnTokens>? other, double t) {
    if (other is! SplitBurnTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SplitBurnTokens(
      canvas: l(canvas, other.canvas),
      surfacePrimary: l(surfacePrimary, other.surfacePrimary),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      surfaceGlass: l(surfaceGlass, other.surfaceGlass),
      hairlineBorder: l(hairlineBorder, other.hairlineBorder),
      specularBorder: l(specularBorder, other.specularBorder),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      safeMint: l(safeMint, other.safeMint),
      survivalMagma: l(survivalMagma, other.survivalMagma),
      survivalMagmaEnd: l(survivalMagmaEnd, other.survivalMagmaEnd),
      owedToMe: l(owedToMe, other.owedToMe),
      iOwe: l(iOwe, other.iOwe),
      trialAmber: l(trialAmber, other.trialAmber),
      thermalPaper: l(thermalPaper, other.thermalPaper),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      info: l(info, other.info),
      nudgeViolet: l(nudgeViolet, other.nudgeViolet),
      shadow: l(shadow, other.shadow),
    );
  }

  /// Survival Magma as the spec's two-stop gradient.
  LinearGradient get magmaGradient => LinearGradient(
    colors: [survivalMagma, survivalMagmaEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

extension SbContext on BuildContext {
  SplitBurnTokens get sb => Theme.of(this).extension<SplitBurnTokens>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Type scale (DESIGN_SYSTEM.md §2.2). Colourless: callers pick a token.
abstract final class SbType {
  static const display = 'Plus Jakarta Sans';
  static const ui = 'Inter';
  static const mono = 'JetBrains Mono';

  /// JetBrains Mono has no ₹: Inter fills that glyph in.
  static const _monoFallback = [ui];

  static const _tabular = [FontFeature.tabularFigures()];

  /// Hero daily burn: 36sp w800, −1.2 tracking, tabular.
  static const hero = TextStyle(
    fontFamily: display,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.05,
    fontFeatures: _tabular,
  );

  /// Card balances: 24sp w700, −0.6 tracking, tabular.
  static const balance = TextStyle(
    fontFamily: display,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    fontFeatures: _tabular,
  );

  /// Screen titles.
  static const title = TextStyle(
    fontFamily: display,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  /// Section headers: 13sp w700, 0.8 tracking, upper-cased by the widget.
  static const section = TextStyle(
    fontFamily: ui,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  /// Body and line items: 15sp w500.
  static const body = TextStyle(
    fontFamily: ui,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  /// Friend chips and badges: 12sp w600.
  static const chip = TextStyle(
    fontFamily: ui,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  /// Thermal receipt rows and OCR prices: 13sp w500 mono, tabular.
  static const receipt = TextStyle(
    fontFamily: mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  /// Trial Graveyard countdowns: 14sp w700 mono, tabular.
  static const countdown = TextStyle(
    fontFamily: mono,
    fontFamilyFallback: _monoFallback,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// Money in rows: tabular Inter.
  static const amount = TextStyle(
    fontFamily: ui,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
}

abstract final class SbRadius {
  static const card = 20.0;
  static const row = 14.0;
  static const pill = 999.0;
}

ThemeData buildSplitBurnTheme(Brightness brightness) {
  final t = brightness == Brightness.dark
      ? SplitBurnTokens.dark
      : SplitBurnTokens.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.accent,
    onPrimary: t.onAccent,
    secondary: t.owedToMe,
    onSecondary: t.onAccent,
    error: t.survivalMagma,
    onError: Colors.white,
    surface: t.surfacePrimary,
    onSurface: t.textPrimary,
    onSurfaceVariant: t.textSecondary,
    surfaceContainerHighest: t.surfaceElevated,
    outline: t.specularBorder,
    outlineVariant: t.hairlineBorder,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: SbType.ui,
    scaffoldBackgroundColor: t.canvas,
    canvasColor: t.canvas,
    splashFactory: InkSparkle.splashFactory,
    extensions: [t],
  );
  final text = base.textTheme.apply(
    bodyColor: t.textPrimary,
    displayColor: t.textPrimary,
  );
  final label = text.labelLarge!.copyWith(fontWeight: FontWeight.w700);
  final roundedRow = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(SbRadius.row),
  );
  InputBorder field(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(SbRadius.row),
    borderSide: BorderSide(color: color, width: width),
  );

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: t.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: t.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: SbType.title.copyWith(color: t.textPrimary, fontSize: 22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surfacePrimary,
      border: field(t.hairlineBorder, 1),
      enabledBorder: field(t.specularBorder, 1),
      focusedBorder: field(t.accent, 1.6),
      labelStyle: TextStyle(color: t.textSecondary),
      hintStyle: TextStyle(color: t.textMuted),
      prefixStyle: TextStyle(color: t.textSecondary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        disabledBackgroundColor: t.surfaceElevated,
        disabledForegroundColor: t.textMuted,
        shape: roundedRow,
        textStyle: label,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.textPrimary,
        side: BorderSide(color: t.specularBorder),
        shape: roundedRow,
        textStyle: label,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: t.accent, textStyle: label),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.surfaceElevated,
      selectedColor: t.accent,
      side: BorderSide(color: t.hairlineBorder),
      shape: const StadiumBorder(),
      labelStyle: SbType.chip.copyWith(color: t.textPrimary, fontSize: 13),
      secondaryLabelStyle: SbType.chip.copyWith(
        color: t.onAccent,
        fontSize: 13,
      ),
      checkmarkColor: t.onAccent,
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: WidgetStatePropertyAll(BorderSide(color: t.specularBorder)),
        textStyle: WidgetStatePropertyAll(SbType.chip.copyWith(fontSize: 13)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.surfacePrimary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? t.onAccent : t.textSecondary,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.surfaceGlass,
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.accent.withValues(alpha: 0.16),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => SbType.chip.copyWith(
          fontSize: 11,
          color: s.contains(WidgetState.selected)
              ? t.textPrimary
              : t.textSecondary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? t.accent : t.textSecondary,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: t.accent,
      foregroundColor: t.onAccent,
      elevation: 0,
      highlightElevation: 0,
      extendedTextStyle: label,
      shape: const StadiumBorder(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.canvas,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      dragHandleColor: t.textMuted,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SbRadius.card),
        side: BorderSide(color: t.hairlineBorder),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.textPrimary,
      contentTextStyle: text.bodyMedium!.copyWith(
        color: t.canvas,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: t.safeMint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SbRadius.row),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(color: t.hairlineBorder, thickness: 1),
    listTileTheme: ListTileThemeData(iconColor: t.textSecondary),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.onAccent : t.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.accent : t.surfaceElevated,
      ),
      trackOutlineColor: WidgetStatePropertyAll(t.hairlineBorder),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent),
  );
}
