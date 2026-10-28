import '../utils/category_names.dart';
import 'package:flutter/material.dart';
import '../widgets/card.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';
import '../pages/individual_card.dart';
import '../pages/vendor_map_page.dart';
import '../pages/vendor_compare_page.dart';
import '../services/vendor_filter.dart';
import '../utils/amenity_icons.dart';
import '../utils/app_styles.dart';
import 'package:google_fonts/google_fonts.dart';


class CategoryPageTemplate extends StatefulWidget {
  final String categoryName;
  final bool showOnlyLoved;

  const CategoryPageTemplate({
    required this.categoryName,
    required this.showOnlyLoved,
    super.key
  });

  @override
  State<CategoryPageTemplate> createState() => _CategoryPageTemplateState();
}

class _CategoryPageTemplateState extends State<CategoryPageTemplate> {
  String? selectedState;
  String? selectedCounty;
  Map<String, Set<String>> _selectedFilters = {};

  // Numeric range filters. Null means "no preference" — distinct from a band
  // dragged to its full extent, which is a real constraint that excludes
  // vendors with no value.
  final Map<String, NumRange> _selectedRanges = {};

  // Compare mode (loved pages only)
  bool _compareMode = false;
  final Set<String> _selectedForCompare = {};

  /// Which vendor column a range filter constrains.
  static const _priceKey = 'starting_price';
  static const _capacityKey = 'guest_capacity_range';

  List<Map<String, dynamic>> _getFilteredItems(List<Map<String, dynamic>> items) =>
      filterByRegion(items, selectedState, selectedCounty);

  List<String> _getAvailableStates(List<Map<String, dynamic>> items) =>
      availableStates(items);

  List<String> _getAvailableCounties(List<Map<String, dynamic>> items) =>
      availableCounties(items, selectedState);

  void _clearFilters() {
    setState(() {
      selectedState = null;
      selectedCounty = null;
      _selectedFilters = {};
      _selectedRanges.clear();
    });
  }

  /// The full set of constraints currently applied to the grid.
  VendorFilterSelection get _selection => VendorFilterSelection(
        state: selectedState,
        county: selectedCounty,
        tags: _selectedFilters,
        priceBand: _selectedRanges[_priceKey],
        capacityBand: _selectedRanges[_capacityKey],
      );

  /// One chip row per option sub-group, with the group heading above it when
  /// the filter defines sections (e.g. Amenities).
  List<Widget> _buildChipGroups(
    Map<String, dynamic> filterDef,
    List<Map<String, dynamic>> optionRows,
    Map<String, Set<String>> sheetSelections,
    void Function(VoidCallback) setSheetState,
  ) {
    final key = filterDef['filter_key'] as String;
    final groups = groupOptionsFor(filterDef, optionRows);
    final selectedForKey = sheetSelections[key] ?? <String>{};

    return [
      for (final group in groups) ...[
        if (group.title != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              group.title!,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: const Color(0xFF9A8FA0),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.options.map((option) {
              final selected = selectedForKey.contains(option.value);
              final icon = amenityIcon(option.iconName);
              return FilterChip(
                avatar: icon == null
                    ? null
                    : Icon(
                        icon,
                        size: 16,
                        color: selected
                            ? const Color(0xFF7B3F61)
                            : const Color(0xFF6E6E6E),
                      ),
                label: Text(
                  option.label,
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
                selected: selected,
                onSelected: (val) {
                  setSheetState(() {
                    final set = sheetSelections.putIfAbsent(key, () => {});
                    if (val) {
                      set.add(option.value);
                    } else {
                      set.remove(option.value);
                      if (set.isEmpty) sheetSelections.remove(key);
                    }
                  });
                },
                selectedColor: const Color(0xFF7B3F61).withOpacity(0.15),
                checkmarkColor: const Color(0xFF7B3F61),
                labelStyle: TextStyle(
                  color: selected
                      ? const Color(0xFF7B3F61)
                      : const Color(0xFF3E3E3E),
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF7B3F61)
                      : const Color(0xFFDCC7AA),
                ),
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ),
      ],
    ];
  }

  /// A two-thumb slider for a numeric filter. Untouched means "no preference";
  /// once dragged it becomes a real constraint.
  Widget _buildRangeFilter(
    Map<String, dynamic> filterDef,
    Map<String, NumRange> sheetRanges,
    void Function(VoidCallback) setSheetState,
  ) {
    final key = filterDef['filter_key'] as String;
    final min = (filterDef['range_min'] as num?)?.toDouble() ?? 0;
    final max = (filterDef['range_max'] as num?)?.toDouble() ?? 100;
    final step = (filterDef['range_step'] as num?)?.toInt() ?? 1;
    final unit = (filterDef['range_unit'] as String?) ?? '';
    final divisions = step > 0 ? ((max - min) / step).round() : null;

    final active = sheetRanges[key];
    final values = active == null
        ? RangeValues(min, max)
        : RangeValues(active.min.toDouble(), active.max.toDouble());

    String format(double v) => unit == '\$'
        ? '\$${v.round()}'
        : '${v.round()}${unit.isEmpty ? '' : ' $unit'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              active == null
                  ? 'Any'
                  : '${format(values.start)} – ${format(values.end)}',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B3F61),
              ),
            ),
            if (active != null)
              TextButton(
                onPressed: () =>
                    setSheetState(() => sheetRanges.remove(key)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Reset',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF9A8FA0),
                  ),
                ),
              ),
          ],
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFF7B3F61),
          inactiveColor: const Color(0xFFDCC7AA),
          labels: RangeLabels(format(values.start), format(values.end)),
          onChanged: (v) => setSheetState(() {
            sheetRanges[key] = NumRange(v.start.round(), v.end.round());
          }),
        ),
      ],
    );
  }

  void _showFilterSheet(
    BuildContext context,
    List<Map<String, dynamic>> filters,
    Map<String, List<Map<String, dynamic>>> optionsByKey,
  ) {
    // Work on a local copy so changes don't affect the grid until user confirms
    Map<String, Set<String>> sheetSelections = {
      for (final entry in _selectedFilters.entries)
        entry.key: Set<String>.from(entry.value)
    };
    final Map<String, NumRange> sheetRanges = Map.of(_selectedRanges);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) {
          final int totalSelected =
              sheetSelections.values.fold(0, (sum, s) => sum + s.length) +
                  sheetRanges.length;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7B3F61),
                      ),
                    ),
                    if (totalSelected > 0)
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            sheetSelections = {};
                            sheetRanges.clear();
                          });
                        },
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: const Color(0xFF7B3F61),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: filters.map((filterDef) {
                        final key = filterDef['filter_key'] as String;
                        final label = filterDef['filter_label'] as String;
                        final isRange =
                            (filterDef['filter_type'] as String?) == 'range';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3E3E3E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (isRange)
                                _buildRangeFilter(
                                  filterDef,
                                  sheetRanges,
                                  setSheetState,
                                )
                              else
                                ..._buildChipGroups(
                                  filterDef,
                                  optionsByKey[key] ?? const [],
                                  sheetSelections,
                                  setSheetState,
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilters = sheetSelections;
                        _selectedRanges
                          ..clear()
                          ..addAll(sheetRanges);
                      });
                      Navigator.pop(sheetCtx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B3F61),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      totalSelected == 0
                          ? 'Show All'
                          : 'Show Results ($totalSelected selected)',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String capCategoryName = widget.categoryName;
    return Consumer<AppState>(
      builder:(context, appState, child) {
          final List<Map<String, dynamic>> categoryList = widget.showOnlyLoved
            ? (appState.lovedCategorizedMap[widget.categoryName] ?? [])
            : (appState.allCategorizedMap[widget.categoryName]  ?? []);

          final filteredList = filterVendors(categoryList, _selection);
          final stateOptions = _getAvailableStates(categoryList);
          final countyOptions = _getAvailableCounties(categoryList);
          final filters = appState.categoryFilters[widget.categoryName] ?? [];
          final optionsByKey = appState.filterOptions;
          final int activeFilterCount =
              _selectedFilters.values.fold(0, (sum, s) => sum + s.length) +
                  _selectedRanges.length;

        return Scaffold(
          body: Column( 
            children: [
              Container(
                width: double.infinity,
                color: AppStyles.cream,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppStyles.maxContentWidth),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (Navigator.canPop(context))
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                            icon: const Icon(Icons.chevron_left, size: 18),
                            label: Text(widget.showOnlyLoved ? 'MY LOVED' : 'ALL VENDORS', style: AppStyles.eyebrow(size: 10)),
                          ),
                        Text(
                          widget.showOnlyLoved
                              ? 'Loved ${categoryDisplayName(capCategoryName)}'
                              : categoryDisplayName(capCategoryName),
                          style: AppStyles.display(30),
                        ),
                        const SizedBox(height: 2),
                        Text(vendorCountLabel(capCategoryName, filteredList.length),
                            style: AppStyles.body(13, color: AppStyles.inkSoft)),
                      ],
                    ),
                    ),
                  ),
                ),
              ),

              // Filter Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC7AA).withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFDCC7AA).withOpacity(0.3),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedState,
                        decoration: InputDecoration(
                          labelText: 'State',
                          labelStyle: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF7B3F61),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'All States',
                              style: GoogleFonts.montserrat(fontSize: 11),
                            ),
                          ),
                          ...stateOptions.map((state) => DropdownMenuItem(
                                value: state,
                                child: Text(
                                  state,
                                  style: GoogleFonts.montserrat(fontSize: 11),
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedState = value;
                            // Reset county when state changes
                            if (selectedCounty != null && 
                                !_getAvailableCounties(categoryList).contains(selectedCounty)) {
                              selectedCounty = null;
                            }
                          });
                        },
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedCounty,
                        decoration: InputDecoration(
                          labelText: 'County',
                          labelStyle: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF7B3F61),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'All Counties',
                              style: GoogleFonts.montserrat(fontSize: 11),
                            ),
                          ),
                          ...countyOptions.map((county) => DropdownMenuItem(
                                value: county,
                                child: Text(
                                  county,
                                  style: GoogleFonts.montserrat(fontSize: 11),
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCounty = value;
                          });
                        },
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.showOnlyLoved)
                        OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _compareMode = true;
                            _selectedForCompare.clear();
                          }),
                          icon: const Icon(Icons.compare_arrows,
                              size: 16, color: Color(0xFF7B3F61)),
                          label: Text(
                            'Compare',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7B3F61),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7B3F61)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                        ),
                      if (filters.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showFilterSheet(context, filters, optionsByKey),
                          icon: Icon(
                            Icons.tune,
                            size: 16,
                            color: activeFilterCount > 0
                                ? Colors.white
                                : const Color(0xFF7B3F61),
                          ),
                          label: Text(
                            activeFilterCount == 0
                                ? 'Filter'
                                : 'Filter ($activeFilterCount)',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: activeFilterCount > 0
                                  ? Colors.white
                                  : const Color(0xFF7B3F61),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: activeFilterCount > 0
                                ? const Color(0xFF7B3F61)
                                : Colors.transparent,
                            side: const BorderSide(color: Color(0xFF7B3F61)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VendorMapPage(
                              vendors: filteredList,
                              categoryName: widget.categoryName,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.map_outlined,
                            size: 16, color: Color(0xFF7B3F61)),
                        label: Text(
                          'Search by Map',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7B3F61),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7B3F61)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
              
              // Compare toolbar
              if (_compareMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFF7B3F61).withOpacity(0.08),
                  child: Row(
                    children: [
                      Text(
                        '${_selectedForCompare.length} selected (max 3)',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          _compareMode = false;
                          _selectedForCompare.clear();
                        }),
                        child: Text('Cancel',
                            style: GoogleFonts.montserrat(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _selectedForCompare.length >= 2
                            ? () {
                                final vendors = _selectedForCompare
                                    .map((id) => filteredList.firstWhere(
                                          (v) => v['vendor_id'] == id,
                                          orElse: () => {},
                                        ))
                                    .where((v) => v.isNotEmpty)
                                    .toList();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VendorComparePage(vendors: vendors),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B3F61),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        child: Text('Compare',
                            style: GoogleFonts.montserrat(fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              (filteredList.isEmpty) ? Expanded(
                child: Center(
                  child: Text(
                    selectedState != null || selectedCounty != null || _selectedFilters.isNotEmpty
                        ? "No vendors found matching your filters"
                        : "No vendors for this category to display",
                    style: AppStyles.backButton,
                  ),
                ),
              ): 
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppStyles.maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: LayoutBuilder(builder: (context, box) {
                      final cols = box.maxWidth < 600 ? 1 : box.maxWidth < 950 ? 2 : 3;
                      const gap = 24.0;
                      final tileW = (box.maxWidth - gap * (cols - 1)) / cols;
                      // Photo at 16:10, plus room for city, name and two lines.
                      final tileH = tileW * 0.625 + 112;
                      return GridView.builder(
                itemCount: filteredList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: gap,
                mainAxisSpacing: 28,
                childAspectRatio: tileW / tileH,
                ),
                itemBuilder:(context, index) {
                  final item = filteredList[index];
                  final vendorId = item['vendor_id'] as String? ?? '';
                  final isSelectedForCompare = _selectedForCompare.contains(vendorId);
                  return Selector<AppState, bool>(
                              selector: (_, appState) =>
                                  appState.lovedVendorUUIDsCategorizedMap[widget.categoryName]
                                      ?.contains(item['vendor_id']) ??
                                  false,
                              builder: (_, isHearted, __) {
                  final card = CustomCard(
                    title: item['vendor_name'] ?? "",
                    description: item['vendor_description'] ?? "",
                    imageUrl: ((item['image_url'] as List<dynamic>?)?.isNotEmpty ?? false)
                        ? (item['image_url'] as List<dynamic>)[0].toString()
                        : '',
                    subtitle: item['vendor_location'] as String? ?? '',
                    isHearted: appState.lovedVendorUUIDsCategorizedMap[widget.categoryName]?.contains(item['vendor_id']) ?? false,
                    onHeartToggled: (hearted) {
                      appState.toggleHeart(item['vendor_id'], hearted);
                    },
                    isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]] == item['vendor_id'],
                    onDiamondToggled: (diamonded) {
                      appState.toggleDiamond(item['vendor_id'], diamonded);
                    },
                    onTap: _compareMode
                        ? () {
                            setState(() {
                              if (isSelectedForCompare) {
                                _selectedForCompare.remove(vendorId);
                              } else if (_selectedForCompare.length < 3) {
                                _selectedForCompare.add(vendorId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Maximum 3 vendors')),
                                );
                              }
                            });
                          }
                        : () {
                      appState.trackCardClick(item['vendor_id']);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:(_) => IndividualCard(
                            category: widget.categoryName,
                            filterValues: (item['filter_values'] as Map<String, dynamic>?) ?? const {},
                            startingPrice: item['starting_price'] as num?,
                            capacityMin: (item['capacity_min'] as num?)?.toInt(),
                            capacityMax: (item['capacity_max'] as num?)?.toInt(),
                            vendor_id:item['vendor_id'],
                            title: item['vendor_name'] ?? "",
                            description: item['vendor_description'] ?? "",
                            style_keywords: item['style_keywords'] ?? "",
                            location: item['vendor_location'] ?? "",
                            address: item['address'] ?? "",
                            vendor_estimated_price: item['vendor_estimated_price'] ?? "",
                            vendor_price: item['vendor_price'] ?? "",
                            contact_email: item['contact_email'] ?? "",
                            contact_phone: item['contact_phone'] ?? "",
                            website_url: item['website_url'] ?? "",
                            imageUrl: (item['image_url'] as List<dynamic>?)
                                          ?.whereType<String>()
                                          .toList() ?? [],
                                      social_media_links: (item['social_media_links'] as List<dynamic>?)
                                          ?.whereType<String>()
                                          .toList() ?? [],
                            isHearted: appState.lovedVendorUUIDsCategorizedMap[widget.categoryName]?.contains(item['vendor_id']) ?? false,
                            isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]] == item['vendor_id'],
                            onHeartToggled: (hearted) {
                              appState.toggleHeart(item['vendor_id'], hearted);
                            },
                            onDiamondToggled: (diamonded) {
                              appState.toggleDiamond(item['vendor_id'], diamonded);
                            },
                          )
                        )
                      );
                    },
                  );
                  if (!_compareMode) return card;
                  return Stack(
                    children: [
                      card,
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelectedForCompare) {
                                _selectedForCompare.remove(vendorId);
                              } else if (_selectedForCompare.length < 3) {
                                _selectedForCompare.add(vendorId);
                              }
                            });
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isSelectedForCompare
                                  ? const Color(0xFF7B3F61)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF7B3F61), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: isSelectedForCompare
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                });
                },
              );
                    })))
            )
            )
            ]
          )
        );
      }
    );
  }
}