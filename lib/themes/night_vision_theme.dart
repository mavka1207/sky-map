// ============================================================================
// 5️⃣ NIGHT VISION (Red Light Mode) - Preserve night vision
// ============================================================================

// ignore_for_file: deprecated_member_use, unused_local_variable, use_super_parameters

import 'package:flutter/material.dart';

/// Night Vision theme (red light mode).
///
/// Why: Red light has a longer wavelength (650+ nm) and generally disrupts
/// dark adaptation less than white or blue light.
class NightVisionTheme {
  // ========================================================================
  // COLOR PALETTE
  // ========================================================================

  /// Primary color - deep maroon.
  static const Color darkMaroon = Color(0xFF1a0000);

  /// Accent color - bright red.
  static const Color brightRed = Color(0xFFFF6666);

  /// Secondary accent - saturated red.
  static const Color accentRed = Color(0xFFCC3333);

  /// Background - even darker maroon.
  static const Color darkBackground = Color(0xFF0d0000);

  /// Text color - muted red.
  static const Color redText = Color(0xFFDD5555);

  /// Disabled color - dark red.
  static const Color disabledRed = Color(0xFF662222);

  /// Border color - subtle red.
  static const Color borderRed = Color(0xFF443333);

  // ========================================================================
  // THEME BUILDERS
  // ========================================================================

  /// Get full Night Vision ThemeData.
  static ThemeData getNightVisionTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkMaroon,

      // ====================================================================
      // CORE COLORS
      // ====================================================================
      primaryColor: brightRed,
      primaryColorDark: accentRed,
      primaryColorLight: Color(0xFFFF9999),

      // ====================================================================
      // COLOR SCHEME
      // ====================================================================
      colorScheme: ColorScheme.dark(
        primary: brightRed,
        onPrimary: darkMaroon,
        primaryContainer: accentRed,
        onPrimaryContainer: Color(0xFFFFCCCC),
        secondary: accentRed,
        onSecondary: darkBackground,
        tertiary: Color(0xFF994444),
        surface: Color(0xFF2a1a1a),
        onSurface: redText,
        error: Color(0xFFFF6666),
        onError: darkMaroon,
      ),

      // ====================================================================
      // APP BAR
      // ====================================================================
      appBarTheme: AppBarTheme(
        backgroundColor: darkMaroon,
        foregroundColor: brightRed,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: brightRed,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: brightRed),
      ),

      // ====================================================================
      // TEXT THEME
      // ====================================================================
      textTheme: TextTheme(
        // Very large text
        displayLarge: TextStyle(
          color: brightRed,
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        // Large text
        displayMedium: TextStyle(
          color: brightRed,
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        // Medium headline
        displaySmall: TextStyle(
          color: accentRed,
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        // Headline
        headlineSmall: TextStyle(
          color: brightRed,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        // Subtitle
        titleLarge: TextStyle(
          color: redText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        // Body text
        bodyLarge: TextStyle(
          color: redText,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        // Medium body text
        bodyMedium: TextStyle(
          color: Color(0xFFCC7777),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        // Small body text
        bodySmall: TextStyle(
          color: Color(0xFF994444),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        // Label
        labelLarge: TextStyle(
          color: brightRed,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),

      // ====================================================================
      // INPUT DECORATIONS (TextField)
      // ====================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2a1a1a),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderRed),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderRed, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: brightRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFFF3333), width: 2),
        ),
        hintStyle: TextStyle(color: disabledRed, fontSize: 14),
        labelStyle: TextStyle(color: redText, fontSize: 14),
        prefixIconColor: accentRed,
        suffixIconColor: accentRed,
      ),

      // ====================================================================
      // BUTTONS
      // ====================================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightRed,
          foregroundColor: darkMaroon,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brightRed,
          side: BorderSide(color: brightRed, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brightRed,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ====================================================================
      // SWITCH & TOGGLE
      // ====================================================================
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return brightRed;
          }
          return disabledRed;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentRed.withOpacity(0.5);
          }
          return borderRed.withOpacity(0.3);
        }),
      ),

      // ====================================================================
      // DIALOGS
      // ====================================================================
      dialogTheme: DialogThemeData(
        backgroundColor: Color(0xFF2a1a1a),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderRed),
        ),
        titleTextStyle: TextStyle(
          color: brightRed,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: redText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ====================================================================
      // SNACKBAR
      // ====================================================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: accentRed,
        contentTextStyle: TextStyle(
          color: Color(0xFFFFCCCC),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: Color(0xFFFFEEEE),
      ),

      // ====================================================================
      // DIVIDER
      // ====================================================================
      dividerTheme: DividerThemeData(
        color: borderRed,
        thickness: 1,
        space: 16,
      ),

      // ====================================================================
      // CARD
      // ====================================================================
      cardTheme: CardThemeData(
        color: Color(0xFF2a1a1a),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderRed.withOpacity(0.3)),
        ),
      ),

      // ====================================================================
      // PROGRESS INDICATOR
      // ====================================================================
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brightRed,
        linearMinHeight: 4,
      ),
    );
  }

  /// A reduced variant for modal dialogs.
  static ThemeData getNightVisionDialogTheme() {
    return getNightVisionTheme().copyWith(
      scaffoldBackgroundColor: Color(0xFF2a1a1a),
    );
  }

  /// A darker variant for surfaces.
  static ThemeData getNightVisionDarkVariant() {
    return getNightVisionTheme().copyWith(
      scaffoldBackgroundColor: darkBackground,
    );
  }
}

// ============================================================================
// CUSTOM WIDGETS FOR NIGHT VISION MODE
// ============================================================================

/// A button styled for night vision.
class NightVisionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final Widget? icon;

  const NightVisionButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon ?? SizedBox.shrink(),
        label: Text(label),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon ?? SizedBox.shrink(),
      label: Text(label),
    );
  }
}

/// An info panel for night vision mode.
class NightVisionInfoPanel extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;

  const NightVisionInfoPanel({
    required this.title,
    required this.content,
    this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF2a1a1a),
        border: Border.all(color: NightVisionTheme.borderRed),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: NightVisionTheme.brightRed, size: 24),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: NightVisionTheme.brightRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: NightVisionTheme.redText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Night vision indicator.
class NightVisionIndicator extends StatelessWidget {
  final bool isActive;

  const NightVisionIndicator({
    required this.isActive,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isActive) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NightVisionTheme.brightRed.withOpacity(0.2),
        border: Border.all(color: NightVisionTheme.brightRed),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dark_mode,
            color: NightVisionTheme.brightRed,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            'Night Vision',
            style: TextStyle(
              color: NightVisionTheme.brightRed,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NIGHT VISION PAINTER
// ============================================================================

/// A simple painter for a red-themed night vision sky.
class NightVisionSkyPainter extends CustomPainter {
  final List<Offset> stars;
  final List<String> constellationLines;
  final bool useNightVision;

  NightVisionSkyPainter({
    required this.stars,
    required this.constellationLines,
    this.useNightVision = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..color = useNightVision
          ? NightVisionTheme.darkMaroon
          : Colors.black;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Stars
    final starPaint = Paint()
      ..color = useNightVision
          ? NightVisionTheme.brightRed
          : Colors.white
      ..strokeCap = StrokeCap.round;

    for (final star in stars) {
      canvas.drawCircle(star, 2.5, starPaint);
    }

    // Constellation lines
    final linePaint = Paint()
      ..color = useNightVision
          ? NightVisionTheme.accentRed.withOpacity(0.5)
          : Colors.white38
      ..strokeWidth = 1.5;

    // TODO: Draw constellation lines
  }

  @override
  bool shouldRepaint(NightVisionSkyPainter oldDelegate) {
    return oldDelegate.useNightVision != useNightVision ||
        oldDelegate.stars != stars;
  }
}

// ============================================================================
// NIGHT VISION MODE PROVIDER
// ============================================================================

/// Night vision settings.
class NightVisionSettings {
  final bool enabled;
  final double brightness;
  final double contrastModifier;

  NightVisionSettings({
    this.enabled = false,
    this.brightness = 0.8,
    this.contrastModifier = 1.0,
  });

  NightVisionSettings copyWith({
    bool? enabled,
    double? brightness,
    double? contrastModifier,
  }) {
    return NightVisionSettings(
      enabled: enabled ?? this.enabled,
      brightness: brightness ?? this.brightness,
      contrastModifier: contrastModifier ?? this.contrastModifier,
    );
  }
}

// ============================================================================
// TIPS FOR NIGHT VISION
// ============================================================================

/// Static tips for night vision mode.
class NightVisionTips {
  static const List<String> tips = [
    'Red light generally preserves your night vision better than white light.',
    'Give your eyes 20–30 minutes to adapt to darkness.',
    'Avoid bright white light while stargazing.',
    'Look slightly to the side of faint objects for better visibility.',
    'Use peripheral vision to spot dim stars.',
    'Keep screen brightness low to maintain dark adaptation.',
    'Take short breaks if your eyes feel strained.',
    'Let your eyes re-adapt after looking at bright lights.',
  ];

  static String getRandomTip() {
    final random = DateTime.now().millisecond % tips.length;
    return tips[random];
  }
}

// ============================================================================
// DEMO VALUES
// ============================================================================

/*
// ВИКОРИСТАННЯ В MAIN.DART:

void main() {
  runApp(const SkyMapApp());
}

class SkyMapApp extends StatefulWidget {
  const SkyMapApp({super.key});

  @override
  State<SkyMapApp> createState() => _SkyMapAppState();
}

class _SkyMapAppState extends State<SkyMapApp> {
  bool _nightVisionMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sky Map',
      theme: _nightVisionMode
          ? NightVisionTheme.getNightVisionTheme()
          : ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
            ),
      home: SkyMapPage(
        nightVisionMode: _nightVisionMode,
        onNightVisionChanged: (value) {
          setState(() => _nightVisionMode = value);
        },
      ),
    );
  }
}

// У SkyMapPage, додайте в Scaffold:
Switch.adaptive(
  value: nightVisionMode,
  onChanged: (value) {
    onNightVisionChanged(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Night Vision увімкнено' : 'Night Vision вимкнено'),
        duration: Duration(seconds: 2),
      ),
    );
  },
)
*/