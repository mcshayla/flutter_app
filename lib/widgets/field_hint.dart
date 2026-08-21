import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_styles.dart';

/// A one-line explanation under a form field.
///
/// Deliberately quiet — no box, no icon. The vendor forms use this several
/// times in a row to say which fields drive filtering and which are shown
/// verbatim; rendering each as a tinted callout would turn the pricing section
/// into a wall of notices and none of them would get read.
///
/// Shared by the create and edit forms so their wording cannot drift.
class FieldHint extends StatelessWidget {
  final String text;

  const FieldHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 8),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color: AppStyles.lightWrods,
        ),
      ),
    );
  }
}
