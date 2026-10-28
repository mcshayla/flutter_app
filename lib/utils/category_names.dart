/// How vendor categories read on screen. The database keeps its singular
/// names ("Venue"); menus read better in the plural ("Venues").
const Map<String, String> _plural = {
  'Venue': 'Venues',
  'Photographer': 'Photographers',
  'Videographer': 'Videographers',
  'Florist': 'Florists',
  'DJ': 'DJs',
  'Cake': 'Cakes',
  'Jeweler': 'Jewelers',
};

/// The noun for one vendor, used in counts like "3 venues".
const Map<String, (String, String)> _nouns = {
  'Venue': ('venue', 'venues'),
  'Photographer': ('photographer', 'photographers'),
  'Videographer': ('videographer', 'videographers'),
  'Photo & Video': ('photo & video team', 'photo & video teams'),
  'Florist': ('florist', 'florists'),
  'DJ': ('DJ', 'DJs'),
  'Cake': ('baker', 'bakers'),
  'Jeweler': ('jeweler', 'jewelers'),
  'Catering': ('caterer', 'caterers'),
  'Wedding Planning': ('planner', 'planners'),
};

String categoryDisplayName(String category) => _plural[category] ?? category;

String vendorCountLabel(String category, int count) {
  final (one, many) = _nouns[category] ?? ('vendor', 'vendors');
  return '$count ${count == 1 ? one : many}';
}
