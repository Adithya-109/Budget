import 'package:flutter/material.dart';

/// SplitBurn's dark-first, high-contrast Neobrutalist palette. Mirrors the
/// widget's `Palette` in `ios/BalanceWidgetExtension/BalanceWidget.swift`.
abstract final class SbColors {
  static const ink = Color(0xFF0B0B0F);
  static const surface = Color(0xFF17171F);
  static const raised = Color(0xFF22222C);
  static const paper = Color(0xFFF7F5EC);
  static const lime = Color(0xFFD4FF3A);
  static const magma = Color(0xFFFF5A1F);
  static const survival = Color(0xFFFF2D55);
  static const owed = Color(0xFF3DDC84);
  static const sky = Color(0xFF7CC4FF);
  static const muted = Color(0x99FFFFFF);
  static const outline = Color(0xFFF7F5EC);
}

abstract final class SbType {
  static const mono = 'monospace';

  static const label = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );

  static const hero = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const figure = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

ThemeData buildSplitBurnTheme() {
  const scheme = ColorScheme.dark(
    primary: SbColors.lime,
    onPrimary: SbColors.ink,
    secondary: SbColors.magma,
    onSecondary: SbColors.ink,
    error: SbColors.survival,
    onError: SbColors.ink,
    surface: SbColors.surface,
    onSurface: SbColors.paper,
    outline: SbColors.outline,
  );
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: SbColors.outline, width: 2),
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: SbColors.ink,
    canvasColor: SbColors.ink,
  );
  // Component styles build on the theme's label style so they keep the
  // platform font (a bare TextStyle drops the family).
  final label = base.textTheme.labelLarge!;
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: SbColors.paper,
      displayColor: SbColors.paper,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SbColors.ink,
      foregroundColor: SbColors.paper,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: SbType.mono,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: SbColors.paper,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: SbColors.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: SbColors.lime, width: 2.5),
      ),
      labelStyle: TextStyle(color: SbColors.muted),
      hintStyle: TextStyle(color: SbColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SbColors.lime,
        foregroundColor: SbColors.ink,
        disabledBackgroundColor: SbColors.raised,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: SbColors.outline, width: 2),
        ),
        textStyle: label.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SbColors.paper,
        side: const BorderSide(color: SbColors.outline, width: 2),
        shape: const RoundedRectangleBorder(),
        textStyle: label.copyWith(fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SbColors.lime,
        textStyle: label.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: SbColors.surface,
      selectedColor: SbColors.lime,
      side: const BorderSide(color: SbColors.outline, width: 1.5),
      shape: const RoundedRectangleBorder(),
      labelStyle: label.copyWith(fontWeight: FontWeight.w700),
      secondaryLabelStyle: label.copyWith(
        color: SbColors.ink,
        fontWeight: FontWeight.w800,
      ),
      checkmarkColor: SbColors.ink,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        side: const WidgetStatePropertyAll(
          BorderSide(color: SbColors.outline, width: 2),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? SbColors.lime
              : SbColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? SbColors.ink : SbColors.paper,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SbColors.ink,
      indicatorColor: SbColors.lime,
      indicatorShape: const RoundedRectangleBorder(),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: SbType.mono,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? SbColors.ink
              : SbColors.paper,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SbColors.lime,
      foregroundColor: SbColors.ink,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: SbColors.outline, width: 2.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: SbColors.ink,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: SbColors.outline, width: 2),
      ),
      showDragHandle: true,
      dragHandleColor: SbColors.paper,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: SbColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: SbColors.outline, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SbColors.paper,
      contentTextStyle: base.textTheme.bodyMedium!.copyWith(
        color: SbColors.ink,
        fontWeight: FontWeight.w700,
      ),
      actionTextColor: SbColors.magma,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: SbColors.ink, width: 2),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: SbColors.raised,
      thickness: 1.5,
    ),
    listTileTheme: const ListTileThemeData(iconColor: SbColors.paper),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? SbColors.ink : SbColors.paper,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? SbColors.lime : SbColors.raised,
      ),
    ),
  );
}
