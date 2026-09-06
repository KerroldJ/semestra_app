import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

/// Semestra's warm / gold design system.
///
/// Rules that keep the aesthetic coherent:
/// - Backgrounds are warm greys (`bg` / `elevated`), text is near-black `ink`.
/// - Gold (`gold`) is **stroke-only** — borders, the active tab, priority
///   labels, the compose ring, focus states. It is never a large fill.
///   `goldDeep` is used for gold *text*.
/// - Subjects are differentiated by a 2px tonal **spine** (see [spineFor]),
///   not by competing hues.
/// - Type is Instrument Sans; [tnum] enables tabular figures so times, dates
///   and counts stay aligned.
class AppTheme {
  // ---- Warm neutrals (light) ----
  static const Color bg = Color(0xFFF3F2F2); // app background
  static const Color elevated = Color(0xFFEAE9E9); // cards / raised surfaces
  static const Color ink = Color(0xFF201F1D); // primary text
  // Alpha-encoded tints of `ink`. Kept `const` (not withOpacity) so the many
  // existing `const TextStyle(color: AppTheme.inkMuted)` call sites still work.
  static const Color inkMuted = Color(0x9E201F1D); // ~0.62 — secondary text
  static const Color inkFaint = Color(0x66201F1D); // ~0.40 — tertiary / hints
  static const Color hairline = Color(0x1A201F1D); // ~0.10 — subtle borders

  // ---- Gold (stroke-only) ----
  static const Color gold = Color(0xFFB68235); // strokes, active states
  static const Color goldDeep = Color(0xFF7D5411); // gold *text*

  // ---- Subject spine palette (tonal, not competing hues) ----
  static const List<Color> spinePalette = [
    Color(0xFF7D5411),
    Color(0xFFC28D41),
    Color(0xFF605D5D),
    Color(0xFF9B9797),
    Color(0xFFBAB6B6),
  ];

  /// Maps a subject to a spine tone. Accepts either a stored ARGB color value
  /// (legacy subjects persisted a Material color) or a plain palette index.
  static Color spineFor(int indexOrColor) {
    // Small non-negative numbers are treated as palette indices.
    if (indexOrColor >= 0 && indexOrColor < spinePalette.length) {
      return spinePalette[indexOrColor];
    }
    // Otherwise fold the stored color value onto the palette deterministically.
    return spinePalette[indexOrColor.abs() % spinePalette.length];
  }

  // ---- Semantic accents (used sparingly, mostly as stroke / text) ----
  static const Color danger = Color(0xFFB4432E); // overdue / destructive
  static const Color success = Color(0xFF4E6B3F); // done / positive

  // ---- Dark palette (retuned to warm neutrals) ----
  static const Color darkBg = Color(0xFF1A1917);
  static const Color darkElevated = Color(0xFF242220);
  static const Color darkInk = Color(0xFFF1EFEC);

  // ---- Back-compat aliases (older screens still reference these) ----
  // Kept so the redesign can land incrementally without breaking every file
  // at once. New code should use the names above.
  static const Color warmBg = bg;
  static const Color warmCard = elevated;
  static const Color primary = gold;
  static const Color darkSurface = darkElevated;
  static const Color darkCard = darkElevated;
  static const Color statPurple = goldDeep;
  static const Color statOrange = gold;
  static const Color statRed = danger;
  static const Color statGreen = success;
  static const List<Color> heroGradient = [Color(0xFF2C2A26), Color(0xFF413B31)];
  static const List<Color> primaryGradient = [gold, goldDeep];

  /// Legacy subject color list (still used by the old subject dialog until the
  /// redesigned picker lands). Mapped onto the spine palette.
  static const List<Color> subjectColors = spinePalette;

  // ---- Type ----
  static const String fontFamily = 'InstrumentSans';

  /// Tabular-figures style — apply to any run of times / dates / counts so
  /// digits share a fixed advance width and columns stay aligned.
  static const TextStyle tnum = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ---- Helpers ----

  /// Soft tinted background for a color (used behind avatars, chips, tints).
  static Color soft(Color c, [double opacity = 0.12]) => c.withOpacity(opacity);

  /// 1–2 letter initials derived from a name. "Data Structures" -> "DS".
  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static TextTheme _textTheme(Color onBg, Color muted) {
    TextStyle t(double size, FontWeight w, {Color? c, double? spacing}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: w,
          color: c ?? onBg,
          letterSpacing: spacing,
          height: 1.25,
        );
    return TextTheme(
      displayLarge: t(30, FontWeight.w600),
      headlineMedium: t(24, FontWeight.w600),
      titleLarge: t(20, FontWeight.w600),
      titleMedium: t(15.5, FontWeight.w600),
      bodyLarge: t(15.5, FontWeight.w400),
      bodyMedium: t(13.5, FontWeight.w400, c: muted),
      bodySmall: t(12, FontWeight.w400, c: muted),
      labelLarge: t(14, FontWeight.w600),
      labelSmall: t(11, FontWeight.w600, c: muted, spacing: 0.8),
    );
  }

  static ThemeData get lightTheme {
    final muted = ink.withOpacity(0.62);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: elevated,
      colorScheme: ColorScheme.light(
        primary: gold,
        onPrimary: Colors.white,
        secondary: goldDeep,
        surface: elevated,
        onSurface: ink,
        error: danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),
      textTheme: _textTheme(ink, muted),
      cardTheme: CardThemeData(
        color: elevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: ink.withOpacity(0.08)),
        ),
      ),
      dividerTheme: DividerThemeData(color: ink.withOpacity(0.10), thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldDeep,
          side: const BorderSide(color: gold, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        hintStyle: TextStyle(color: ink.withOpacity(0.40)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ink.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ink.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: muted),
      ),
    );
  }

  static ThemeData get darkTheme {
    final muted = darkInk.withOpacity(0.60);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: darkBg,
      canvasColor: darkBg,
      cardColor: darkElevated,
      colorScheme: ColorScheme.dark(
        primary: gold,
        onPrimary: darkBg,
        secondary: gold,
        surface: darkElevated,
        onSurface: darkInk,
        error: danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: darkInk,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: darkInk),
      ),
      textTheme: _textTheme(darkInk, muted),
      cardTheme: CardThemeData(
        color: darkElevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      dividerTheme:
          DividerThemeData(color: Colors.white.withOpacity(0.08), thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkInk,
          foregroundColor: darkBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkElevated,
        hintStyle: TextStyle(color: darkInk.withOpacity(0.40)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: muted),
      ),
    );
  }
}
