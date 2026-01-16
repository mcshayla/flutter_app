import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:say_yes/utils/string_extensions.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/app_styles.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    super.key,
  });

  @override
  State<IndividualCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<IndividualCard> {
  int _currentImageIndex = 0;
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
        child: Image.network(
          "https://picsum.photos/200/300",
          width: double.infinity,
          height: 500,
          fit: BoxFit.cover,
        ),
      );
    }

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
                      url,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          "https://picsum.photos/200/300",
                          fit: BoxFit.cover,
                        );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 42,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                        color: const Color(0xFF7B3F61),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        iconSize: 40,
                        icon: Icon(
                          isHearted ? Icons.favorite : Icons.favorite_border,
                          color: const Color(0xFF7B3F61),
                        ),
                        onPressed: () {
                          if (widget.onHeartToggled != null) {
                            widget.onHeartToggled!(!isHearted);
                          }
                        },
                      ),
                      IconButton(
                        iconSize: 40,
                        icon: Icon(
                          isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                          color: const Color(0xFF7B3F61),
                        ),
                        onPressed: () {
                          if (widget.onDiamondToggled != null) {
                            widget.onDiamondToggled!(!isDiamonded);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.style_keywords.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: widget.style_keywords
                        .split(',')
                        .map((keyword) => keyword.trim())
                        .where((keyword) => keyword.isNotEmpty)
                        .map((keyword) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCC7AA).withOpacity(0.2),
                                border: Border.all(color: const Color(0xFFDCC7AA)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                keyword,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFF7B3F61),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              if (widget.description.isNotEmpty)
                Text(
                  widget.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                    height: 1.6,
                    color: const Color(0xFF6E6E6E),
                  ),
                ),
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
              _buildDesktopDetails(context, appState, details),
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

  Widget _buildDesktopDetails(
    BuildContext context,
    AppState appState,
    List<List<String>> details,
  ) {
    final filteredDetails = details
        .where((item) =>
            item[1] != null &&
            (item[1] as String).trim().isNotEmpty &&
            item[1] != "Unknown" &&
            item[0] != 'Style Keywords' &&
            item[0] != 'Description')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filteredDetails.map((item) {
        final detailTitle = item[0];
        final value = item[1] as String;

        bool isClickable = false;
        String? launchUrl;

        if (detailTitle == 'Email') {
          isClickable = true;
          launchUrl = 'mailto:$value';
        } else if (detailTitle == 'Phone') {
          isClickable = true;
          launchUrl = 'tel:$value';
        } else if (detailTitle == 'Website') {
          isClickable = true;
          launchUrl = value.startsWith('http') ? value : 'https://$value';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detailTitle,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: const Color(0xFF7B3F61).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: isClickable && launchUrl != null
                    ? () {
                        appState.trackLinksClick(widget.vendor_id);
                        _launchInBrowser(Uri.parse(launchUrl!));
                      }
                    : null,
                child: Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    height: 1.4,
                    color: isClickable
                        ? const Color(0xFF7B3F61)
                        : const Color(0xFF6E6E6E),
                    decoration: isClickable
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor:
                        isClickable ? const Color(0xFF7B3F61) : null,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
                      images[index],
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      cacheWidth: 1600,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          "https://picsum.photos/200/300",
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                        );
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
          : Image.network(
              "https://picsum.photos/200/300",
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
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
          padding: const EdgeInsets.only(
            top: 16.0,
            left: 36.0,
            right: 36.0,
            bottom: 0.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.bodoniModa(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: const Color(0xFF7B3F61),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 32,
                    icon: Icon(
                      isHearted ? Icons.favorite : Icons.favorite_border,
                      color: const Color(0xFF7B3F61),
                    ),
                    onPressed: () {
                      if (widget.onHeartToggled != null) {
                        widget.onHeartToggled!(!isHearted);
                      }
                    },
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 32,
                    icon: Icon(
                      isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                      color: const Color(0xFF7B3F61),
                    ),
                    onPressed: () {
                      if (widget.onDiamondToggled != null) {
                        widget.onDiamondToggled!(!isDiamonded);
                      }
                    },
                  )
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0),
          child: Container(
            height: 1,
            color: const Color(0xFFDCC7AA),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 14.0,
            left: 38.0,
            right: 36.0,
            bottom: 10.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.style_keywords.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: widget.style_keywords
                        .split(',')
                        .map((keyword) => keyword.trim())
                        .where((keyword) => keyword.isNotEmpty)
                        .map((keyword) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCC7AA).withOpacity(0.2),
                                border: Border.all(color: const Color(0xFFDCC7AA)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                keyword,
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFF7B3F61),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ...details
                  .where((item) =>
                      item[1] != null &&
                      (item[1] as String).trim().isNotEmpty &&
                      item[1] != "Unknown" &&
                      item[0] != 'Style Keywords')
                  .map((item) {
                final detailTitle = item[0];
                final value = item[1] as String;

                bool isClickable = false;
                String? launchUrl;

                if (detailTitle == 'Email') {
                  isClickable = true;
                  launchUrl = 'mailto:$value';
                } else if (detailTitle == 'Phone') {
                  isClickable = true;
                  launchUrl = 'tel:$value';
                } else if (detailTitle == 'Website') {
                  isClickable = true;
                  launchUrl =
                      value.startsWith('http') ? value : 'https://$value';
                }

                if (detailTitle == 'Description') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      value,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        height: 1.4,
                        color: const Color(0xFF6E6E6E),
                      ),
                      softWrap: true,
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "$detailTitle: ",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: isClickable && launchUrl != null
                              ? () {
                                  appState.trackLinksClick(widget.vendor_id);
                                  _launchInBrowser(Uri.parse(launchUrl!));
                                }
                              : null,
                          child: Text(
                            value,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              height: 1.4,
                              color: isClickable
                                  ? const Color(0xFF7B3F61)
                                  : const Color(0xFF6E6E6E),
                              decoration: isClickable
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationColor:
                                  isClickable ? const Color(0xFF7B3F61) : null,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
                Text(
                  'Reviews',
                  style: GoogleFonts.bodoniModa(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: const Color(0xFF7B3F61),
                  ),
                ),
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
                style: GoogleFonts.bodoniModa(
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
      ['Estimated Price', widget.vendor_estimated_price],
      ['Base Price', widget.vendor_price],
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
            appState.diamondedCards[widget.category.lowerCase()] ==
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