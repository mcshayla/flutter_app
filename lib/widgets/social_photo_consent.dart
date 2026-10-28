import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The box under a listing's photos: may easiYESt share them on its social
/// media, with credit? Saved as `vendors.allow_social_photos`. Checked by
/// default; the website's listing form asks the same thing.
class SocialPhotoConsent extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SocialPhotoConsent({required this.value, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: const Color(0xFF7B3F61),
      title: Text(
        "These photos can appear on easiYESt's social media, with credit to your business.",
        style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF4A4A4A)),
      ),
    );
  }
}

/// Listings saved before the question existed (null) start checked, like a
/// new listing. A vendor who said no keeps their no.
bool initialSocialPhotoConsent(dynamic saved) => saved != false;
