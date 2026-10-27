import 'package:flutter/material.dart';

abstract final class SonoraColors {
  static const background = Color(0xFF0B0C14);
  static const surface = Color(0xFF141522);
  static const raised = Color(0xFF1D1E30);
  static const subtle = Color(0xFF11131F);
  static const text = Color(0xFFF6F5FC);
  static const muted = Color(0xFFA8A9BC);
  static const border = Color(0xFF2B2C41);
  static const primary = Color(0xFFAE8CFF);
  static const accent = Color(0xFF65DDE3);
  static const focus = Color(0xFFD9F7F5);
  static const success = Color(0xFF7CE1AC);
  static const warning = Color(0xFFF0C980);
  static const danger = Color(0xFFFF9DAD);
}

ThemeData sonoraTheme({bool cyanAccent = false, bool reduceMotion = false}) {
  final primary = cyanAccent ? SonoraColors.accent : SonoraColors.primary;
  final secondary = cyanAccent ? SonoraColors.primary : SonoraColors.accent;
  const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      height: 40 / 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      color: SonoraColors.text,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: SonoraColors.text,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: SonoraColors.text,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w700,
      color: SonoraColors.text,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      color: SonoraColors.text,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 21 / 14,
      color: SonoraColors.text,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 18 / 12,
      fontWeight: FontWeight.w500,
      color: SonoraColors.muted,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w700,
      color: SonoraColors.text,
    ),
  );
  final scheme =
      ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primary,
        surface: SonoraColors.surface,
      ).copyWith(
        primary: primary,
        onPrimary: const Color(0xFF171024),
        secondary: secondary,
        onSecondary: const Color(0xFF082226),
        surface: SonoraColors.surface,
        onSurface: SonoraColors.text,
        error: SonoraColors.danger,
        onError: const Color(0xFF2A0B12),
        outline: SonoraColors.border,
        surfaceContainerLowest: SonoraColors.background,
        surfaceContainerLow: SonoraColors.subtle,
        surfaceContainer: SonoraColors.surface,
        surfaceContainerHigh: SonoraColors.raised,
        onSurfaceVariant: SonoraColors.muted,
      );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: SonoraColors.background,
    fontFamily: 'Manrope',
    textTheme: textTheme.apply(fontFamily: 'Manrope'),
    splashFactory: InkSparkle.splashFactory,
    focusColor: SonoraColors.focus.withValues(alpha: .12),
    hoverColor: primary.withValues(alpha: .06),
    appBarTheme: const AppBarTheme(
      backgroundColor: SonoraColors.background,
      foregroundColor: SonoraColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w700,
        color: SonoraColors.text,
      ),
    ),
    cardTheme: const CardThemeData(
      color: SonoraColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SonoraColors.surface,
      hintStyle: textTheme.bodyMedium?.copyWith(color: SonoraColors.muted),
      labelStyle: textTheme.bodyMedium,
      errorStyle: textTheme.bodySmall?.copyWith(color: SonoraColors.danger),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SonoraColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SonoraColors.focus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SonoraColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SonoraColors.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: const Color(0xFF171024),
        disabledBackgroundColor: SonoraColors.raised,
        disabledForegroundColor: SonoraColors.muted,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SonoraColors.text,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: const BorderSide(color: SonoraColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: SonoraColors.text,
        minimumSize: const Size(48, 48),
        maximumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SonoraColors.surface,
      height: 72,
      elevation: 0,
      indicatorColor: primary.withValues(alpha: .14),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? primary
              : SonoraColors.muted,
          size: 24,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          height: 16 / 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? SonoraColors.text
              : SonoraColors.muted,
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: SonoraColors.border,
      thumbColor: SonoraColors.text,
      overlayColor: primary.withValues(alpha: .12),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF171024)
            : SonoraColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primary
            : SonoraColors.raised,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SonoraColors.raised,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: SonoraColors.surface,
      modalBackgroundColor: SonoraColors.surface,
      showDragHandle: true,
      dragHandleColor: SonoraColors.border,
      constraints: BoxConstraints(maxWidth: 680),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: SonoraColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: SonoraColors.muted,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: SonoraColors.border,
      thickness: 1,
      space: 1,
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: reduceMotion
            ? const _InstantPageTransitionsBuilder()
            : const FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

/// Transisi tanpa animasi untuk mode Reduce Motion (DESIGN bagian 6).
class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
