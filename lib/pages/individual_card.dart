import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/app_styles.dart';
import '../utils/image_utils.dart';
import '../widgets/spec_card.dart';
import '../services/vendor_page_logic.dart';
import '../widgets/vendor_page_parts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'budget_item_form.dart';

class IndividualCard extends StatefulWidget {
  final String title;
  final String description;
  final List<String> imageUrl;
  final String style_keywords;
  final String location;
  final String address;
  final String vendor_estimated_price;
  final String vendor_price;
  final String contact_email;
  final String contact_phone;
  final String website_url;
  final String vendor_id;
  final String category;
  final List<String> social_media_links;
  final bool isHearted;
  final bool isDiamonded;
  final Function(bool)? onHeartToggled;
  final Function(bool)? onDiamondToggled;

  /// The vendor's `filter_values` jsonb, used to show confirmed amenities.
  /// Optional so existing call sites keep working; an empty map simply hides
  /// the amenities section.
  final Map<String, dynamic> filterValues;

  /// Numeric `starting_price`, `capacity_min` and `capacity_max` columns.
  /// Optional; when present they feed the "at a glance" numbers.
  final num? startingPrice;
  final int? capacityMin;
  final int? capacityMax;

  const IndividualCard({
    required this.category,
    required this.vendor_id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.style_keywords,
    required this.location,
    required this.address,
    required this.vendor_estimated_price,
    required this.vendor_price,
    required this.contact_email,
    required this.contact_phone,
    required this.website_url,
    required this.social_media_links,
    required this.isHearted,
    required this.isDiamonded,
    this.onHeartToggled,
    this.onDiamondToggled,
    this.filterValues = const {},
    this.startingPrice,
    this.capacityMin,
    this.capacityMax,
    super.key,
  });

  @override
  State<IndividualCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<IndividualCard> {
  int _currentImageIndex = 0;
  int _desktopImagePage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppState appState,
    bool isHearted,
    bool isDiamonded,
    List<String> images,
    List<List<String>> details,
  ) {
    return Column(
      children: [
        if (Navigator.canPop(context))
          Row(
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  "Back",
                  style: AppStyles.backButton,
                ),
              )
            ],
          ),
        _buildImageCarousel(images, false),
        _buildMobileContent(context, appState, isHearted, isDiamonded, details),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppState appState,
    bool isHearted,
    bool isDiamonded,
    List<String> images,
    List<List<String>> details,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Column(
          children: [
            if (Navigator.canPop(context))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    "Back",
                    style: AppStyles.backButton,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildDesktopImageGrid(images),
            const SizedBox(height: 40),
            _buildDesktopContent(context, appState, isHearted, isDiamonded, details),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopImageGrid(List<String> images) {
    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _photoPlaceholder(keyed: true),
      );
    }

    // On web, show carousel with arrows; on desktop, show static 3-image grid
    if (kIsWeb) {
      return _buildWebImageCarousel(images);
    } else {
      return _buildDesktopStaticImageGrid(images);
    }
  }

  Widget _buildDesktopStaticImageGrid(List<String> images) {
    // Show up to 3 images in a grid
    final displayImages = images.take(3).toList();
    
    return SizedBox(
      height: 500,
      child: Row(
        children: displayImages.asMap().entries.map((entry) {
          final index = entry.key;
          final url = entry.value;
          
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < displayImages.length - 1 ? 12 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      supabaseThumb(url, width: 800, quality: 75),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _photoPlaceholder();
                      },
                    ),
                    if (index == 2 && images.length > 3)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Text(
                            '+${images.length - 3}',
                            style: GoogleFonts.montserrat(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWebImageCarousel(List<String> images) {
    const itemsToShow = 3;
    final maxStartIndex = (images.length - itemsToShow).clamp(0, images.length);
    final startIndex = _desktopImagePage.clamp(0, maxStartIndex);
    final endIndex = (startIndex + itemsToShow).clamp(0, images.length);
    final displayImages = images.sublist(startIndex, endIndex);

    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          Row(
            children: displayImages.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < displayImages.length - 1 ? 12 : 0,
                  ),
                 child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      supabaseThumb(url, width: 800, quality: 75),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _photoPlaceholder();
                      },
                    ),
                  ),
                ),

                ),
              );
            }).toList(),
          ),
          // Left arrow
          if (_desktopImagePage > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _desktopImagePage--;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: Transform.translate(
                      offset: const Offset(2, 0),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Right arrow
          if (_desktopImagePage < maxStartIndex)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _desktopImagePage++;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    AppState appState,
    bool isHearted,
    bool isDiamonded,
    List<List<String>> details,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Title and description
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVendorHeader(appState, isHearted, isDiamonded, wide: true),
              const SizedBox(height: 24),
              _buildAboutPanel(isWide: true),
              _buildVendorFacts(appState, details, images: widget.imageUrl, wide: true),
            ],
          ),
        ),
        const SizedBox(width: 80),
        // Right column - Details in two columns
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpecCard(
                entries: _coreSpecEntries(appState, details),
                heading: 'Details',
              ),
              if (widget.social_media_links.isNotEmpty) ...[
                const SizedBox(height: 32),
                Container(
                  height: 1,
                  color: const Color(0xFFDCC7AA),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connect',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  children: widget.social_media_links
                      .where((url) => url.trim().isNotEmpty)
                      .map((url) {
                    IconData icon = Icons.link;
                    if (url.toLowerCase().contains('facebook')) {
                      icon = FontAwesomeIcons.facebook;
                    } else if (url.toLowerCase().contains('instagram')) {
                      icon = FontAwesomeIcons.instagram;
                    } else if (url.toLowerCase().contains('twitter')) {
                      icon = FontAwesomeIcons.twitter;
                    } else if (url.toLowerCase().contains('linkedin')) {
                      icon = FontAwesomeIcons.linkedin;
                    } else if (url.toLowerCase().contains('pinterest')) {
                      icon = FontAwesomeIcons.pinterest;
                    } else if (url.toLowerCase().contains('youtube')) {
                      icon = FontAwesomeIcons.youtube;
                    } else if (url.toLowerCase().contains('tiktok')) {
                      icon = FontAwesomeIcons.tiktok;
                    }

                    return GestureDetector(
                      onTap: () {
                        appState.trackLinksClick(widget.vendor_id);
                        _launchInBrowser(Uri.parse(url));
                      },
                      child: FaIcon(
                        icon,
                        size: 28,
                        color: const Color(0xFF7B3F61),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  VendorSlots _slots(AppState appState) => buildVendorSlots(
        filterGroups: appState.categoryFilters[widget.category] ?? const [],
        optionsByKey: appState.filterOptions,
        filterValues: widget.filterValues,
        startingPrice: widget.startingPrice,
        priceText: widget.vendor_price.isNotEmpty ? widget.vendor_price : widget.vendor_estimated_price,
        capacityMin: widget.capacityMin,
        capacityMax: widget.capacityMax,
      );

  void _addToBudget() {
    final price = widget.startingPrice?.toDouble() ??
        double.tryParse(widget.vendor_price.replaceAll(RegExp(r'[^\d.]'), '')) ??
        double.tryParse(widget.vendor_estimated_price.replaceAll(RegExp(r'[^\d.]'), ''));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetItemForm(
          prefillData: {
            'item_name': widget.title,
            'category': widget.category,
            'estimated_cost': price,
          },
        ),
      ),
    );
  }

  /// Name, Love/YES/Website, the YES note, the numbers and the highlights.
  /// Shared by both layouts so they can't drift apart.
  Widget _buildVendorHeader(AppState appState, bool isHearted, bool isDiamonded, {required bool wide}) {
    final slots = _slots(appState);
    final eyebrow = [widget.category, if (widget.location.trim().isNotEmpty && widget.location != 'Unknown') widget.location.trim()].join(' · ');
    final hasPrice = widget.startingPrice != null || widget.vendor_price.isNotEmpty || widget.vendor_estimated_price.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(eyebrow.toUpperCase(), style: AppStyles.eyebrow()),
        const SizedBox(height: 8),
        Text(widget.title, style: AppStyles.display(wide ? 40 : 28)),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: VendorActionRow(
            isLoved: isHearted,
            isYes: isDiamonded,
            websiteUrl: widget.website_url,
            onLove: (v) => widget.onHeartToggled?.call(v),
            onYes: (v) => widget.onDiamondToggled?.call(v),
            onWebsite: () {
              appState.trackLinksClick(widget.vendor_id);
              final url = widget.website_url.startsWith('http') ? widget.website_url : 'https://${widget.website_url}';
              _launchInBrowser(Uri.parse(url));
            },
          ),
        ),
        if (isDiamonded) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: YesNote(category: widget.category, onAddToBudget: hasPrice ? _addToBudget : null),
          ),
        ],
        if (slots.glance.isNotEmpty) ...[
          const SizedBox(height: 18),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: AtAGlance(items: slots.glance)),
        ],
        if (slots.highlights.isNotEmpty) ...[
          const SizedBox(height: 22),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: HighlightMedallions(items: slots.highlights)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// The type-specific details, contact facts, What's included and photos.
  Widget _buildVendorFacts(AppState appState, List<List<String>> details, {required List<String> images, required bool wide}) {
    final slots = _slots(appState);
    final mosaic = mosaicImages(images.where((u) => u.trim().isNotEmpty).toList());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (slots.details.isNotEmpty) ...[
          const SectionHeading('Details'),
          const SizedBox(height: 6),
          DetailsList(items: slots.details),
          const SizedBox(height: 24),
        ],
        if (!wide) ...[
          SpecCard(entries: _coreSpecEntries(appState, details)),
          const SizedBox(height: 24),
        ],
        if (slots.included.isNotEmpty) ...[
          IncludedCard(groups: slots.included),
          const SizedBox(height: 28),
        ],
        if (mosaic.isNotEmpty) ...[
          PhotoMosaic(
            images: mosaic,
            imageBuilder: (url) => Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: AppStyles.blush)),
          ),
          const SizedBox(height: 28),
        ],
      ],
    );
  }

  /// Shown when a vendor has no photos, or one fails to load. A soft brand
  /// panel rather than a stock photo, which would misrepresent the vendor.
  Widget _photoPlaceholder({bool keyed = false}) => Container(
        key: keyed ? const ValueKey('photo-placeholder') : null,
        width: double.infinity,
        height: 260,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppStyles.blush, AppStyles.champagneLight],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.photo_camera_outlined, size: 36, color: AppStyles.rose),
      );

  /// The description and the style keywords on one elevated panel.
  ///
  /// Written once and used by both layouts. The keyword pills used to be
  /// duplicated in `_buildDesktopContent` and `_buildMobileContent`, which is
  /// the same duplication that let the amenities row exist on desktop and go
  /// missing on mobile — so this is deliberately not copy-pasted.
  Widget _buildAboutPanel({required bool isWide}) {
    final keywords = widget.style_keywords
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    if (widget.description.isEmpty && keywords.isEmpty) {
      return const SizedBox.shrink();
    }

    // Deliberately not an ElevatedPanel. That surface fills with the same cream
    // as the page, so on a single prose paragraph its border fences the text in
    // without buying any contrast. The panels are kept for the blocks that group
    // discrete items (the specs, the amenities), which gives the page a
    // hierarchy instead of a stack of identical rectangles.
    //
    // The horizontal inset matches ElevatedPanel's own padding so the paragraph
    // stays in the same text column as the boxed blocks around it.
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading('About'),
          SizedBox(height: isWide ? 14 : 12),
          if (widget.description.isNotEmpty)
            Text(
              widget.description,
              style: AppStyles.body(isWide ? 16 : 14.5, color: AppStyles.inkSoft).copyWith(height: 1.7),
              softWrap: true,
            ),
          if (keywords.isNotEmpty) ...[
            SizedBox(height: widget.description.isEmpty ? 0 : 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              // The same tan wash as the amenity pills in amenity_row.dart, not
              // white: now that About is unboxed these sit directly on the page
              // cream, where white read as a bright cut-out. The wash keeps them
              // legible as tags while staying in the warm palette.
              children: keywords
                  .map((keyword) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppStyles.accentColor.withValues(alpha: 0.2),
                          border: Border.all(color: AppStyles.accentColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          keyword,
                          style: GoogleFonts.montserrat(
                            fontSize: isWide ? 12 : 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                            color: AppStyles.secondaryColor,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// The vendor's core facts as [SpecEntry]s, so they render on the same
  /// elevated surface as the filter-derived specs instead of as loose text.
  ///
  /// Style Keywords and Description are excluded: both have their own
  /// presentation elsewhere on the page.
  List<SpecEntry> _coreSpecEntries(
    AppState appState,
    List<List<String>> details,
  ) {
    return details
        .where((item) =>
            item[1].trim().isNotEmpty &&
            item[1] != 'Unknown' &&
            item[0] != 'Style Keywords' &&
            item[0] != 'Description' &&
            item[0] != 'Starting Price')
        .map((item) {
      final label = item[0];
      final value = item[1];

      final launchTarget = switch (label) {
        'Email' => 'mailto:$value',
        'Phone' => 'tel:$value',
        'Website' => value.startsWith('http') ? value : 'https://$value',
        _ => null,
      };

      return SpecEntry(
        label,
        value,
        onTap: launchTarget == null
            ? null
            : () {
                appState.trackLinksClick(widget.vendor_id);
                _launchInBrowser(Uri.parse(launchTarget));
              },
      );
    }).toList();
  }

  Widget _buildImageCarousel(List<String> images, bool isDesktop) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 300,
      ),
      child: images.isNotEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      supabaseThumb(images[index], width: 1200, quality: 80),
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (context, error, stackTrace) {
                        return _photoPlaceholder();
                      },
                    );
                  },
                ),
                if (images.length > 1 && _currentImageIndex > 0)
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.4),
                          ),
                          child: Transform.translate(
                            offset: const Offset(2, 0),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (images.length > 1 && _currentImageIndex < images.length - 1)
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.4),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : _photoPlaceholder(keyed: true),
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    AppState appState,
    bool isHearted,
    bool isDiamonded,
    List<List<String>> details,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: _buildVendorHeader(appState, isHearted, isDiamonded, wide: false),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAboutPanel(isWide: false),
              // Core facts and filter-derived specs share one card, so mobile
              // shows a single block of facts rather than a loose label/value
              // list followed by a second styled block.
              _buildVendorFacts(appState, details, images: widget.imageUrl, wide: false),
            ],
          ),
        ),
        if (widget.social_media_links.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 36.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: widget.social_media_links
                      .where((url) => url.trim().isNotEmpty)
                      .map((url) {
                    IconData icon = Icons.link;
                    if (url.toLowerCase().contains('facebook')) {
                      icon = FontAwesomeIcons.facebook;
                    } else if (url.toLowerCase().contains('instagram')) {
                      icon = FontAwesomeIcons.instagram;
                    } else if (url.toLowerCase().contains('twitter')) {
                      icon = FontAwesomeIcons.twitter;
                    } else if (url.toLowerCase().contains('linkedin')) {
                      icon = FontAwesomeIcons.linkedin;
                    } else if (url.toLowerCase().contains('pinterest')) {
                      icon = FontAwesomeIcons.pinterest;
                    } else if (url.toLowerCase().contains('youtube')) {
                      icon = FontAwesomeIcons.youtube;
                    } else if (url.toLowerCase().contains('tiktok')) {
                      icon = FontAwesomeIcons.tiktok;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          appState.trackLinksClick(widget.vendor_id);
                          _launchInBrowser(Uri.parse(url));
                        },
                        child: FaIcon(
                          icon,
                          size: 24,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        
        // Reviews Section
        _buildReviewsSection(context, appState),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, AppState appState) {
  return FutureBuilder<List<Map<String, dynamic>>?>(
    future: appState.getReviewsForVendor(widget.vendor_id),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
          child: Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF7B3F61),
            ),
          ),
        );
      }

      final reviews = snapshot.data ?? [];
      final averageRating = _calculateAverageRating(reviews);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFDCC7AA),
            ),
            const SizedBox(height: 24),

            // Reviews Header with Average Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reviews', style: AppStyles.display(24)),
                if (reviews.isNotEmpty)
                  Row(
                    children: [
                      _buildStarRating(averageRating, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${averageRating.toStringAsFixed(1)} (${reviews.length})',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (featuredReview(reviews) case final quote?) ...[
              ReviewPullQuote(review: quote),
              const SizedBox(height: 20),
            ],

            // Leave a Review Button - only show if user is logged in
            if (appState.supabase.auth.currentUser != null && appState.supabase.auth.currentUser?.isAnonymous == false) ...[
              OutlinedButton(
                onPressed: () => _showReviewDialog(context, appState),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7B3F61)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: Text(
                  'Leave a Review',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: const Color(0xFF7B3F61),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Reviews List
            if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E6E6E),
                    ),
                  ),
                ),
              )
            else
              ...reviews.map((review) => _buildReviewCard(review)).toList(),
          ],
        ),
      );
    },
  );
}

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFDCC7AA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCC7AA).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review['userName'] ?? 'Anonymous',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: const Color(0xFF7B3F61),
                  ),
                ),
              ),
              _buildStarRating(review['rating']?.toDouble() ?? 0, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          if (review['comment'] != null && review['comment'].toString().trim().isNotEmpty)
            Text(
              review['comment'],
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
                height: 1.4,
                color: const Color(0xFF6E6E6E),
              ),
            ),
          if (review['date'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _formatDate(review['date']),
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E6E6E).withOpacity(0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : (index < rating ? Icons.star_half : Icons.star_border),
          size: size,
          color: const Color(0xFF7B3F61),
        );
      }),
    );
  }

  double _calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold<double>(
        0.0, (sum, review) => sum + (review['rating']?.toDouble() ?? 0));
    return sum / reviews.length;
  }

  String _formatDate(dynamic date) {
    // Adjust based on your date format
    if (date is DateTime) {
      return '${date.month}/${date.day}/${date.year}';
    }
    return date.toString();
  }

  void _showReviewDialog(BuildContext context, AppState appState) {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Leave a Review',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                          child: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            size: 36,
                            color: const Color(0xFF7B3F61),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Comment (Optional)',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: const Color(0xFF6E6E6E).withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                        ),
                      ),
                      style: GoogleFonts.montserrat(fontSize: 11),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFF6E6E6E),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedRating > 0
                      ? () {
                          appState.submitReview(
                            widget.vendor_id,
                            selectedRating,
                            commentController.text.trim(),
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Review submitted successfully!',
                                style: GoogleFonts.montserrat(fontSize: 11),
                              ),
                              backgroundColor: const Color(0xFF7B3F61),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    disabledBackgroundColor: const Color(0xFF7B3F61).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Submit',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = [
      ['Style Keywords', widget.style_keywords],
      ['Description', widget.description],
      // 'Estimated Price' (vendor_estimated_price) is no longer shown: it was a
      // third price field that duplicated Base Price and is no longer editable
      // on either vendor form, so displaying it would strand vendors with a
      // value on their profile they cannot change. The column is untouched.
      ['Starting Price', widget.vendor_price],
      ['Location', widget.location],
      ['Address', widget.address],
      ['Email', widget.contact_email],
      ['Phone', widget.contact_phone],
      ['Website', widget.website_url]
    ];
    
    final images = widget.imageUrl.where((url) => url.trim().isNotEmpty).toList();

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isHearted = appState.lovedVendorUUIDsCategorizedMap[widget.category]
                ?.contains(widget.vendor_id) ??
            false;
        final isDiamonded =
            appState.diamondedCards[widget.category] ==
                widget.vendor_id;

        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;

              return SingleChildScrollView(
                child: isDesktop
                    ? _buildDesktopLayout(
                        context, appState, isHearted, isDiamonded, images, details)
                    : _buildMobileLayout(
                        context, appState, isHearted, isDiamonded, images, details),
              );
            },
          ),
        );
      },
    );
  }
}