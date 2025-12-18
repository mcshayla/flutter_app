import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppStyles {
  
  static const primaryBackground = Color(0xFFF8F5F0);
  static const secondaryColor = Color(0xFF7B3F61);
  static const accentColor = Color(0xFFDCC7AA);
  static const darkWords = Color(0xFF3E3E3E);
  static const lightWrods = Color(0xFF6E6E6E);

  static final fancyTitle = GoogleFonts.bodoniModa(
            fontSize: 36,
            fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
            letterSpacing: 2.0,
  );

  static final secondaryFancy = GoogleFonts.cormorantGaramond(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                );

  static final basicDarkWords = TextStyle(fontWeight: FontWeight.bold, color: darkWords);

  static final simpleElegant = GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    );

  static final backButton =  GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    );




}