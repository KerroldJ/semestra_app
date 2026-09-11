import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

/// Semestra's Maya-inspired design system.
///
/// Rules that keep the aesthetic coherent:
/// - The body is bright and airy: a near-white `bg` with pure white `elevated`
///   cards. Text is near-black `ink`.
/// - `brand` (Maya green) is a **fill** color — primary buttons, the active
///   tab, the compose button, progress fills, toggles. `brandDeep` is the
///   readable green used for green *text* and outlines on white.
/// - "Spotlight" surfaces (the home hero card) use the dark green→black
///   [heroGradient] with white text — the "balance card" analog.
/// - Subjects are differentiated by a tonal **spine** (see [spineFor]), retoned
///   to the green family so they never fight the brand.
/// - Type is Instrument Sans; [tnum] enables tabular figures so times, dates
///   and counts stay aligned.
class AppTheme {
  // ---- Neutrals (light) ----
  static const Color bg = Color(0xFFFFFFFF); // app background (pure white)
  static const Color elevated = Color(0xFFFFFFFF); // cards / raised surfaces
  static const Color ink = Color(0xFF0B0F0D); // primary text
  // Alpha-encoded tints of `ink`. Kept `const` (not withOpacity) so the many
  // existing `const TextStyle(color: AppTheme.inkMuted)` call sites still work.
  static const Color inkMuted = Color(0x8C0B0F0D); // ~0.55 — secondary text
  static const Color inkFaint = Color(0x5C0B0F0D); // ~0.36 — tertiary / hints
  static const Color hairline = Color(0x140B0F0D); // ~0.08 — subtle borders

  // ---- Brand green (Maya) ----
  static const Color brand = Color(0xFF00C566); // primary fill / active states
  static const Color brandDeep = Color(0xFF0A7D43); // green *text* / outlines

  // ---- Hero (dark spotlight surface) ----
  static const List<Color> heroGradient = [Color(0xFF0C271C), Color(0xFF05100B)];

  // ---- Subject spine palette (tonal, green family) ----
  static const List<Color> spinePalette = [
    Color(0xFF0A7D43),
    Color(0xFF12A45B),
    Color(0xFF4E6B3F),
    Color(0xFF5E6B64),
    Color(0xFF93A099),
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

  // ---- Semantic accents ----
  static const Color danger = Color(0xFFE5484D); // overdue / destructive
  static const Color warning = Color(0xFFF5A524); // due soon
  static const Color success = Color(0xFF0A7D43); // done / positive

  // ---- Dark palette (Midnight — the default dark theme) ----
  static const Color darkBg = Color(0xFF0A0D0B);
  static const Color darkElevated = Color(0xFF151916);
  static const Color darkInk = Color(0xFFECF1ED);

  // ---- Charcoal palette (neutral grey) ----
  static const Color charcoalBg = Color(0xFF16181A);
  static const Color charcoalElevated = Color(0xFF212427);
  static const Color charcoalInk = Color(0xFFECEEF0);

  // ---- Slate palette (cool blue-grey) ----
  static const Color slateBg = Color(0xFF0E1621);
  static const Color slateElevated = Color(0xFF1B2634);
  static const Color slateInk = Color(0xFFE7EDF4);

  // ---- Tokyo palette (black surfaces, vivid red accent) ----
  // Pure-black background with near-black cards, and a vivid red accent used
  // for buttons, icons, the compose button and active states. White text.
  static const Color tokyoBg = Color(0xFF000000); // pure-black background
  static const Color tokyoElevated = Color(0xFF151515); // near-black cards
  static const Color tokyoAccent = Color(0xFFE11D2A); // vivid Tokyo red
  static const Color tokyoInk = Color(0xFFFFFFFF); // white text & icons

  // ---- Back-compat aliases (older screens still reference these) ----
  // The redesign renamed the accent from gold to Maya green; these keep the
  // many existing `AppTheme.gold` / `AppTheme.goldDeep` call sites working.
  // New code should prefer `brand` / `brandDeep`.
  static const Color gold = brand;
  static const Color goldDeep = brandDeep;
  static const Color warmBg = bg;
  static const Color warmCard = elevated;
  static const Color primary = brand;
  static const Color darkSurface = darkElevated;
  static const Color darkCard = darkElevated;
  static const Color statPurple = brandDeep;
  static const Color statOrange = warning;
  static const Color statRed = danger;
  static const Color statGreen = success;
  static const List<Color> primaryGradient = [brand, brandDeep];

  /// Legacy subject color list (still used by the old subject dialog until the
  /// redesigned picker lands). Mapped onto the spine palette.
  static const List<Color> subjectColors = spinePalette;

  // ---- Type ----
  static const String fontFamily = 'InstrumentSans';

  /// Brand display font (Poppins, OFL) — used only for the "Semestra"
  /// wordmark / logo lockup, not for body UI.
  static const String brandFont = 'Poppins';

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

  // ---- Dynamic contrast helpers (brightness-aware) ----

  /// Primary text color based on brightness.
  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkInk : ink;

  /// Secondary / muted text color based on brightness.
  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkInk.withValues(alpha: 0.65)
          : inkMuted;

  /// Faint / tertiary text color based on brightness.
  static Color textFaint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkInk.withValues(alpha: 0.38)
          : inkFaint;

  /// Subtle hairline border color based on brightness.
  static Color hairlineBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.08)
          : hairline;

  /// True when the Tokyo theme is active (detected via its vivid-red primary).
  /// Tokyo swaps the Maya-green accent for red on black surfaces.
  static bool isTokyo(BuildContext context) =>
      Theme.of(context).colorScheme.primary == tokyoAccent;

  /// Solid brand fill for the compose button, the active nav item and progress
  /// bars. Maya green in the default themes; vivid red in Tokyo.
  static Color brandFill(BuildContext context) =>
      isTokyo(context) ? tokyoAccent : brand;

  /// Vibrant accent color on background: Maya green in dark mode, deep readable
  /// green in light mode — but vivid red in Tokyo.
  static Color accent(BuildContext context) {
    if (isTokyo(context)) return tokyoAccent;
    return Theme.of(context).brightness == Brightness.dark ? brand : brandDeep;
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
      displayLarge: t(30, FontWeight.w700),
      headlineMedium: t(24, FontWeight.w700),
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
    final muted = ink.withOpacity(0.55);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: elevated,
      colorScheme: ColorScheme.light(
        primary: brand,
        onPrimary: ink,
        secondary: brandDeep,
        onSecondary: Colors.white,
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
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),
      textTheme: _textTheme(ink, muted),
      cardTheme: CardThemeData(
        color: elevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: ink.withOpacity(0.06)),
        ),
      ),
      dividerTheme: DividerThemeData(color: ink.withOpacity(0.08), thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandDeep,
          side: const BorderSide(color: brand, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        hintStyle: TextStyle(color: ink.withOpacity(0.36)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ink.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ink.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brand, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: muted),
      ),
    );
  }

  /// The default dark theme (Midnight).
  static ThemeData get darkTheme => _darkFamily(
        bg: darkBg,
        elevated: darkElevated,
        ink: darkInk,
      );

  /// Neutral-grey dark theme.
  static ThemeData get charcoalTheme => _darkFamily(
        bg: charcoalBg,
        elevated: charcoalElevated,
        ink: charcoalInk,
      );

  /// Cool blue-grey dark theme.
  static ThemeData get slateTheme => _darkFamily(
        bg: slateBg,
        elevated: slateElevated,
        ink: slateInk,
      );

  /// Tokyo theme — black background, dark-red cards & buttons, white text.
  static ThemeData get tokyoTheme => _darkFamily(
        bg: tokyoBg,
        elevated: tokyoElevated,
        ink: tokyoInk,
        accent: tokyoAccent,
      );

  /// Shared builder for every dark-family theme. Only the neutral surfaces and
  /// on-surface ink change between variants; component shapes stay identical so
  /// the app feels consistent. [accent] sets the primary fill (buttons, active
  /// states, outlines) and defaults to the Maya-green [brand]; Tokyo overrides
  /// it to dark red.
  static ThemeData _darkFamily({
    required Color bg,
    required Color elevated,
    required Color ink,
    Color accent = brand,
  }) {
    final muted = ink.withOpacity(0.60);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: elevated,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent,
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
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: ink),
      ),
      iconTheme: IconThemeData(color: ink),
      textTheme: _textTheme(ink, muted),
      cardTheme: CardThemeData(
        color: elevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      dividerTheme:
          DividerThemeData(color: Colors.white.withOpacity(0.08), thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        hintStyle: TextStyle(color: ink.withOpacity(0.40)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: muted),
      ),
    );
  }

  // ---- Theme registry (drives the Settings theme picker) ----

  /// All selectable app themes, in display order. The stored key lives in
  /// `AppSettings.themeMode`; [themeFor] resolves it to a [ThemeData].
  static const List<AppThemeOption> themeOptions = [
    AppThemeOption(
      key: 'light',
      label: 'Light',
      description: 'Clean warm paper',
      isDark: false,
      previewBg: Color(0xFFEDEDF0),
      previewCard: Colors.white,
      previewInk: ink,
    ),
    AppThemeOption(
      key: 'dark',
      label: 'Midnight',
      description: 'Deep green-black',
      isDark: true,
      previewBg: darkBg,
      previewCard: darkElevated,
      previewInk: darkInk,
    ),
    AppThemeOption(
      key: 'charcoal',
      label: 'Charcoal',
      description: 'Neutral grey',
      isDark: true,
      previewBg: charcoalBg,
      previewCard: charcoalElevated,
      previewInk: charcoalInk,
    ),
    AppThemeOption(
      key: 'slate',
      label: 'Slate',
      description: 'Cool blue-grey',
      isDark: true,
      previewBg: slateBg,
      previewCard: slateElevated,
      previewInk: slateInk,
    ),
    AppThemeOption(
      key: 'tokyo',
      label: 'Tokyo',
      description: 'Black with red accent',
      isDark: true,
      previewBg: tokyoBg,
      previewCard: tokyoElevated,
      previewInk: tokyoInk,
      previewAccent: tokyoAccent,
    ),
  ];

  /// Resolves a stored theme key to its [ThemeData]. Unknown keys (and the
  /// legacy `'midnight'` alias) fall back sensibly.
  static ThemeData themeFor(String key) {
    switch (key) {
      case 'dark':
      case 'midnight':
        return darkTheme;
      case 'charcoal':
        return charcoalTheme;
      case 'slate':
        return slateTheme;
      case 'tokyo':
        return tokyoTheme;
      default:
        return lightTheme;
    }
  }

  /// Metadata for a selectable theme, including swatch-preview colors.
  static AppThemeOption optionFor(String key) => themeOptions.firstWhere(
        (o) => o.key == key,
        orElse: () => themeOptions.first,
      );
}

/// Describes one selectable theme for the Settings picker: its persisted [key],
/// human [label], short [description], whether it renders dark, and the three
/// colors used to draw its swatch preview.
class AppThemeOption {
  final String key;
  final String label;
  final String description;
  final bool isDark;
  final Color previewBg;
  final Color previewCard;
  final Color previewInk;

  /// Accent used for the swatch's hero card. Defaults to the Maya-green brand;
  /// Tokyo overrides it to dark red to match its applied theme.
  final Color previewAccent;

  const AppThemeOption({
    required this.key,
    required this.label,
    required this.description,
    required this.isDark,
    required this.previewBg,
    required this.previewCard,
    required this.previewInk,
    this.previewAccent = AppTheme.brand,
  });
}
