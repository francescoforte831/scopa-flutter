import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colour palette ──────────────────────────────────────────────────────────

/// Deep green felt – primary table background.
const Color kTableGreen = Color(0xFF1B5E20);

/// Lighter green felt – used for card-slot highlights.
const Color kTableGreenLight = Color(0xFF2E7D32);

/// Primary gold – borders, accents, scopa flash.
const Color kGold = Color(0xFFFFD700);

/// Darker gold – depth shadows, pressed states.
const Color kGoldDark = Color(0xFFF9A825);

/// Card face background.
const Color kCardCream = Color(0xFFFFFDE7);

/// Red suit color – coppe & denari.
const Color kSuitRed = Color(0xFFC62828);

/// Dark suit color – spade & bastoni.
const Color kSuitDark = Color(0xFF1A237E);

/// Dark navy – menu / overlay background.
const Color kBackgroundDark = Color(0xFF0D1B2A);

/// Scopa gold overlay for the flash animation.
const Color kScopaGold = Color(0xFFFFD700);

// ── Text styles ──────────────────────────────────────────────────────────────

TextStyle kTitleStyle = GoogleFonts.cinzel(
  fontSize: 52,
  fontWeight: FontWeight.w700,
  color: kGold,
  letterSpacing: 8,
);

TextStyle kSubtitleStyle = GoogleFonts.cinzel(
  fontSize: 16,
  color: kGold.withAlpha(200),
  letterSpacing: 3,
);

TextStyle kHeadingStyle = GoogleFonts.cinzel(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: kGold,
);

TextStyle kScopaTextStyle = GoogleFonts.cinzel(
  fontSize: 40,
  fontWeight: FontWeight.w700,
  color: kGold,
  shadows: [
    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 2)),
  ],
);

TextStyle kScoreRowStyle = GoogleFonts.cinzel(
  fontSize: 14,
  color: Colors.white,
);

// ── Theme ────────────────────────────────────────────────────────────────────

class ScopaTheme {
  ScopaTheme._();

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBackgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: kGold,
      secondary: kGoldDark,
      surface: kBackgroundDark,
    ),
    // Disable ink splash for a cleaner game UI.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kGold,
        foregroundColor: kBackgroundDark,
        textStyle: GoogleFonts.cinzel(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 6,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kGold,
        side: const BorderSide(color: kGold, width: 1.5),
        textStyle: GoogleFonts.cinzel(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: GoogleFonts.cinzelTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: Colors.white70, displayColor: kGold),
  );
}
