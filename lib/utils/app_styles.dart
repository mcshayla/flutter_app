import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens shared with the website (web/site.css). Keep the two in step.
class AppStyles {
  // ---- Palette (contrast-checked) ----
  static const plum = Color(0xFF7B3F61); // hero color
  static const plumDeep = Color(0xFF5E2F4A); // hover / pressed
  static const plumInk = Color(0xFF4A2239); // text on champagne & light buttons
  static const champagne = Color(0xFFDCC7AA); // accent, only on plum or dark
  static const champagneLight = Color(0xFFF1E6D4);
  static const goldLine = Color(0xFFB8996E); // fine lines on light backgrounds
  static const blush = Color(0xFFF2E4E1); // soft section background
  static const rose = Color(0xFFC99A93); // lines & ornaments only, never text
  static const cream = Color(0xFFF8F5F0);
  static const ink = Color(0xFF3D3438); // body text
  static const inkSoft = Color(0xFF6B6266); // secondary text
  static const night = Color(0xFF2B2427);
  static const error = Color(0xFF8A2B2B);

  // ---- Legacy names, kept so older screens pick up the new palette ----
  static const primaryBackground = cream;
  static const secondaryColor = plum;
  static const accentColor = champagne;
  static const darkWords = ink;
  static const lightWrods = inkSoft;

  // ---- Type ----
  static TextStyle display(double size,
          {Color color = ink, FontWeight weight = FontWeight.w500, bool italic = false}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color,
        height: 1.15,
      );

  static TextStyle body(double size,
          {Color color = ink, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.montserrat(fontSize: size, fontWeight: weight, color: color, height: 1.55);

  /// Small capitals label used above headings and on stationery buttons.
  static TextStyle eyebrow({double size = 10, Color color = plum}) =>
      GoogleFonts.montserrat(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.4,
        color: color,
      );

  static final fancyTitle = display(34);

  static final secondaryFancy = display(22, italic: true);

  static final basicDarkWords = TextStyle(fontWeight: FontWeight.bold, color: darkWords);

  static final simpleElegant = body(16, weight: FontWeight.w500);

  static final backButton = eyebrow(size: 11);

  // ---- Layout ----
  /// Desktop browsers and large tablets get side-by-side layouts.
  static bool isWide(double width) => width >= 900;

  /// Content never stretches wider than this on big screens.
  static const double maxContentWidth = 1140;
}
