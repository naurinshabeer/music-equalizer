import 'package:flutter/material.dart';

/// "Analog Modernist Audio" palette from the Stitch design.
class C {
  static const copper = Color(0xFFD97745); // primary
  static const rust = Color(0xFFB96848); // secondary
  static const cream = Color(0xFFF3EBDD); // tertiary
  static const bg = Color(0xFF161615);
  static const card = Color(0xFF1F201E); // neutral
  static const card2 = Color(0xFF282927);
  static const muted = Color(0xFF9A948A);
  static const track = Color(0xFF3A3A37);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.copper,
      secondary: C.rust,
      tertiary: C.cream,
      surface: C.card,
      onSurface: C.cream,
    ),
    textTheme: base.textTheme.apply(bodyColor: C.cream, displayColor: C.cream),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: C.cream,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: C.cream,
      ),
    ),
    dividerTheme: const DividerThemeData(color: C.card2, thickness: 1),
    sliderTheme: SliderThemeData(
      activeTrackColor: C.copper,
      inactiveTrackColor: C.track,
      thumbColor: C.copper,
      overlayColor: C.copper.withOpacity(0.18),
      disabledActiveTrackColor: C.muted.withOpacity(0.5),
      disabledInactiveTrackColor: C.track,
      disabledThumbColor: C.muted,
      trackHeight: 4,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? C.cream : C.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? C.copper : C.track,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.copper,
        side: const BorderSide(color: C.copper),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 13),
      ),
    ),
  );
}

/// Small uppercase caption used across the app.
class Caption extends StatelessWidget {
  final String text;
  final Color color;
  const Caption(this.text, {super.key, this.color = C.muted});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: color,
      ),
    );
  }
}