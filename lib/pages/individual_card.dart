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
    // final List<dynamic> imageUrls =
    // widget.imageUrl.where((url) => url.trim().isNotEmpty).toList();
    final appState = Provider.of<AppState>(context);
    final isHearted = appState.lovedVendorUUIDsCategorizedMap[widget.category]?.contains(widget.vendor_id) ?? false;
    final isDiamonded = appState.diamondedCards[widget.category.lowerCase()] == widget.vendor_id;
    return Consumer<AppState>(
      builder:(context, appState, child) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (Navigator.canPop(context))
                Row( 
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text("Back",
                    style: AppStyles.backButton
                    
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
                top: 36.0,
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
            Padding(
              padding: const EdgeInsets.only(
                top: 10.0,
                left: 38.0,
                right: 36.0,
                bottom: 10.0, // no padding at the bottom
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                details
                  .where((item) => item[1] != null && (item[1] as String).trim().isNotEmpty && item[1] != "Unknown")
                  .map((item) {
                final detailTitle = item[0];
                final value = item[1] as String;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
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
                          child: Text(
                            value,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              color: Color(0xFF6E6E6E)
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                  ));
                  }
              ).toList()
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