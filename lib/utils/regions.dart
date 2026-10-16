/// Fixed choices for a vendor's service area. Vendors pick from these lists
/// rather than typing, so the couple-side state/county filters only ever see
/// one spelling per place.
library;

/// `'Any'` is the "serves anywhere" wildcard understood by vendor_filter.dart.
const String kAnyRegion = 'Any';

const List<String> kUsStates = [
  'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
  'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
  'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
  'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
  'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
  'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
  'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
  'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
  'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
  'West Virginia', 'Wisconsin', 'Wyoming', kAnyRegion,
];

/// Counties are only collected for Utah, where the app is focused. Vendors
/// serving other states are matched at the state level.
const List<String> kUtahCounties = [
  'Beaver County', 'Box Elder County', 'Cache County', 'Carbon County',
  'Daggett County', 'Davis County', 'Duchesne County', 'Emery County',
  'Garfield County', 'Grand County', 'Iron County', 'Juab County',
  'Kane County', 'Millard County', 'Morgan County', 'Piute County',
  'Rich County', 'Salt Lake County', 'San Juan County', 'Sanpete County',
  'Sevier County', 'Summit County', 'Tooele County', 'Uintah County',
  'Utah County', 'Wasatch County', 'Washington County', 'Wayne County',
  'Weber County', kAnyRegion,
];

/// Whether the vendor's chosen states make Utah counties relevant.
bool servesUtah(List<String> states) =>
    states.contains('Utah') || states.contains(kAnyRegion);
