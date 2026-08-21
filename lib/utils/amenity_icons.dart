import 'package:flutter/material.dart';

/// Maps the `icon_name` stored on a `filter_options` row to a real icon.
///
/// Why a closed map instead of a lookup by string: Flutter tree-shakes unused
/// icons out of the built font, so constructing an `IconData` from an
/// arbitrary runtime string yields a blank glyph in release builds. The DB
/// decides *which* icon an amenity gets; this file decides which icons exist.
/// Adding a brand-new icon needs a deploy — reassigning an existing one does
/// not.
///
/// Keep in sync with the AMENITIES table in
/// python_scripts/seed_venue_filters.py.
const Map<String, IconData> _amenityIcons = {
  // Included Services
  'cleaning_services': Icons.cleaning_services,
  'manage_accounts': Icons.manage_accounts,
  'groups': Icons.groups,
  'headphones': Icons.headphones,
  'table_restaurant': Icons.table_restaurant,

  // Equipment & A/V
  'speaker': Icons.speaker,
  'lightbulb': Icons.lightbulb,
  'videocam': Icons.videocam,
  'wifi': Icons.wifi,

  // Facilities
  'nightlife': Icons.nightlife,
  'checkroom': Icons.checkroom,
  'kitchen': Icons.kitchen,
  'wc': Icons.wc,
  'thermostat': Icons.thermostat,

  // Accessibility & Policies
  'accessible': Icons.accessible,
  'policy': Icons.policy,
};

/// The icon for [iconName], or null if the name is unknown.
///
/// Returns null rather than throwing so an amenity seeded with a typo degrades
/// to a label without an icon instead of crashing the vendor page.
IconData? amenityIcon(String? iconName) {
  if (iconName == null || iconName.isEmpty) return null;
  return _amenityIcons[iconName];
}

/// Fallback for an amenity that has no icon assigned.
const IconData amenityFallbackIcon = Icons.check_circle_outline;
