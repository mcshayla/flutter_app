import 'package:flutter/material.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import './individual_card.dart';
import '../utils/app_styles.dart';
import 'wedding_profile_setup.dart';

class YesPage extends StatelessWidget {
  const YesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final diamondedCategories = appState.diamondedCards;
    final categoriesMap = appState.allCategorizedMap;
    final filteredEntries = diamondedCategories.entries.where((entry) => entry.value.isNotEmpty).toList();
    final weddingProfile = appState.weddingProfile;
    final daysLeft = appState.daysUntilWedding;

    final vendorMap = <String, dynamic>{};
    for (var entry in filteredEntries) {
      final vendorList = categoriesMap[entry.key] ?? [];
      final vendor = vendorList.firstWhere((v) => v['vendor_id'] == entry.value, orElse: () => {});
      vendorMap[entry.value] = vendor;
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              children: [
                // Partner names or default
                if (weddingProfile != null &&
                    (weddingProfile['partner_name_1'] ?? '').toString().isNotEmpty)
                  Text(
                    '${weddingProfile['partner_name_1']} & ${weddingProfile['partner_name_2']}',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: const Color(0xFF7B3F61),
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WeddingProfileSetup(existingProfile: weddingProfile),
                        ),
                      );
                    },
                    child: Text(
                      "Your Wedding",
                      style: GoogleFonts.bodoniModa(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        color: const Color(0xFF7B3F61),
                      ),
                    ),
                  ),

                // Countdown
                if (daysLeft != null && daysLeft >= 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B3F61).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$daysLeft days to go!',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7B3F61),
                      ),
                    ),
                  ),
                ] else if (weddingProfile == null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WeddingProfileSetup(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B3F61),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Set up your wedding profile',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],

                // Wedding location
                if (weddingProfile != null &&
                    (weddingProfile['wedding_location'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    weddingProfile['wedding_location'],
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: const Color(0xFF6E6E6E),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: const Color(0xFFDCC7AA),
                ),
              ],
            ),
          ),

          // Edit profile button
          if (weddingProfile != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeddingProfileSetup(existingProfile: weddingProfile),
                      ),
                    );
                  },
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFF7B3F61),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF7B3F61),
                    ),
                  ),
                ),
              ),
            ),

          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Text(
                      "Diamond Vendors to see them here!",
                      style: AppStyles.simpleElegant,
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final category = filteredEntries[index].key;
                      final vendorId = filteredEntries[index].value;
                      final vendor = vendorMap[vendorId] ?? {"vendor_name": "Unknown"};
                      final vendorName = vendor['vendor_name'];

                      final isBooked = appState.bookedVendorIds[vendorId] ?? false;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(category,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7B3F61),
                                      )),
                            ),
                            GestureDetector(
                              onTap: () => {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => IndividualCard(
                                              vendor_id: vendor['vendor_id'],
                                              category: category,
                                              title: vendor['vendor_name'] ?? "",
                                              description: vendor['vendor_description'] ?? "",
                                              style_keywords: vendor['style_keywords'] ?? "",
                                              location: vendor['vendor_location'] ?? "",
                                              address: vendor['address'] ?? "",
                                              vendor_estimated_price: vendor['vendor_estimated_price'] ?? "",
                                              vendor_price: vendor['vendor_price'] ?? "",
                                              contact_email: vendor['contact_email'] ?? "",
                                              contact_phone: vendor['contact_phone'] ?? "",
                                              website_url: vendor['website_url'] ?? "",
                                              imageUrl: (vendor['image_url'] as List<dynamic>?)
                                                          ?.whereType<String>()
                                                          .toList() ?? [],
                                                  social_media_links: (vendor['social_media_links'] as List<dynamic>?)
                                                          ?.whereType<String>()
                                                          .toList() ?? [],
                                              isHearted: appState.lovedVendorUUIDsCategorizedMap[category]?.contains(vendor['vendor_id']) ?? false,
                                              isDiamonded: appState.diamondedCards[category] == vendor['vendor_id'],
                                              onHeartToggled: (hearted) {
                                                appState.toggleHeart(vendor['vendor_id'], hearted);
                                              },
                                              onDiamondToggled: (diamonded) {
                                                appState.toggleDiamond(vendor['vendor_id'], diamonded);
                                              },
                                            )))
                              },
                              child: Container(
                                width: double.infinity,
                                height: 100,
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F5F0),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          ((vendor['image_url'] as List<dynamic>?)?.isNotEmpty ?? false)
                                              ? (vendor['image_url'] as List<dynamic>)[0].toString()
                                              : "https://picsum.photos/200/300",
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          cacheWidth: 200,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.network(
                                              "https://picsum.photos/200/300",
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              cacheWidth: 200,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Text(
                                          vendorName,
                                          style: GoogleFonts.bodoniModa(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 2.0,
                                          ),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Booked toggle
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: isBooked
                                  ? GestureDetector(
                                      onTap: () => appState.toggleBookedVendor(vendorId, false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7B3F61),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Booked',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () => appState.toggleBookedVendor(vendorId, true),
                                      icon: const Icon(Icons.check_circle_outline,
                                          color: Color(0xFF7B3F61), size: 16),
                                      label: Text(
                                        'Mark as Booked',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: const Color(0xFF7B3F61),
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF7B3F61)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
