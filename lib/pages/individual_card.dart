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
  // final VoidCallback? onTap;
  final bool isHearted;
  final bool isDiamonded;
  final Function(bool)? onHeartToggled;
  final Function(bool)? onDiamondToggled;

  const IndividualCard({
    required this.category, required this.vendor_id, required this.title, required this.description, required this.imageUrl, required this.style_keywords, required this.location, required this.address, required this.vendor_estimated_price,required this.vendor_price, required this.contact_email, required this.contact_phone, required this.website_url, required this.social_media_links, required this.isHearted, required this.isDiamonded, this.onHeartToggled, this.onDiamondToggled, super.key //the super key being the id from the database for the venue or whatever
  });

  @override
  State<IndividualCard>createState() => _CustomCardState();

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
    final images = widget.imageUrl
    .where((url) => url.trim().isNotEmpty)
    .toList();
    
    return Consumer<AppState>(
      builder:(context, appState, child) {
      final isHearted = appState.lovedVendorUUIDsCategorizedMap[widget.category]?.contains(widget.vendor_id) ?? false;
      final isDiamonded = appState.diamondedCards[widget.category.lowerCase()] == widget.vendor_id;
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
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
                  ]
                ),
              ConstrainedBox(
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
                          // Left arrow
                          if (images.length > 1)
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
                          // Right arrow
                          if (images.length > 1)
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
                          // Image indicators
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
              ),
            Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                left: 36.0,
                right: 36.0,
                bottom: 0.0, // no padding at the bottom
              ),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                child:Text(widget.title, softWrap: true,               // allow wrapping
                  overflow: TextOverflow.visible, 
                  style: GoogleFonts.bodoniModa(
                  fontSize: 26, 
                  fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
                  letterSpacing: 2.0, // A little spacing for elegance
                  color: const Color(0xFF7B3F61)
                )),),
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 32,
                      icon: Icon(
                    
                        isHearted ? Icons.favorite : Icons.favorite_border,
                        color: Color(0xFF7B3F61),
                      ),
                      onPressed: () {
                        if (widget.onHeartToggled != null) widget.onHeartToggled!(!isHearted);
                      },
                    ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 32,
                      icon: Icon(
                        isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                        color: Color(0xFF7B3F61)
                      ),
                      onPressed: () {
                          if (widget.onDiamondToggled != null) widget.onDiamondToggled!(!isDiamonded);
                      },
                    )
                  ],
                )
              ],)
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
                bottom: 10.0, // no padding at the bottom
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Style Keywords as pills
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                // Other details (excluding Style Keywords and Description heading)
                ...details
                    .where((item) => item[1] != null && (item[1] as String).trim().isNotEmpty && item[1] != "Unknown" && item[0] != 'Style Keywords')
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
                    launchUrl = value.startsWith('http') ? value : 'https://$value';
                  }
                  
                  // For Description, just show the text without the label
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
                              letterSpacing: 1.0
                            )
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
                                  color: isClickable ? const Color(0xFF7B3F61) : const Color(0xFF6E6E6E),
                                  decoration: isClickable ? TextDecoration.underline : TextDecoration.none,
                                  decorationColor: isClickable ? const Color(0xFF7B3F61) : null,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ),
                        ],
                    ));
                    }
                ).toList(),
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
            ],
          )
        ),

      );
        }
    );
  }
}