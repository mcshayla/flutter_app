// vendor_claim.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_dashboard.dart';
import 'vendor_create.dart';

class VendorClaimPage extends StatefulWidget {
  final String userId;

  const VendorClaimPage({
    required this.userId,
    super.key,
  });

  @override
  State<VendorClaimPage> createState() => _VendorClaimPageState();
}

class _VendorClaimPageState extends State<VendorClaimPage> {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  bool isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchVendors() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => isSearching = true);

    try {
      final results = await supabase
          .from('vendors')
          .select()
          .ilike('vendor_name', '%${_searchController.text.trim()}%')
          .or('is_claimed.eq.false,is_claimed.is.null')
          .limit(10);

      setState(() {
        searchResults = List<Map<String, dynamic>>.from(results);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    } finally {
      setState(() => isSearching = false);
    }
  }

  Future<void> _claimVendor(Map<String, dynamic> vendor) async {
    setState(() => isLoading = true);

    try {
      // Update vendor table - ADD vendor_user_id
      await supabase.from('vendors').update({
        'vendor_user_id': widget.userId,
        'is_claimed': true,
        'claimed_at': DateTime.now().toIso8601String(),
      }).eq('vendor_id', vendor['vendor_id']);

      // Create vendor profile
      await supabase.from('vendor_profiles').insert({
        'user_id': widget.userId,
        'vendor_id': vendor['vendor_id'],
        'business_name': vendor['vendor_name'],
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VendorDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming vendor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Claim Your Business',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Search for your business',
              style: GoogleFonts.bodoniModa(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B3F61),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find and claim your existing vendor profile',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF6E6E6E),
              ),
            ),
            const SizedBox(height: 24),
            // Create New Vendor Button
            OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorCreatePage(userId: widget.userId),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const VendorDashboard()),
                  );
                }
              },
              icon: const Icon(Icons.add_business),
              label: Text(
                'Create New Vendor Profile',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7B3F61),
                side: const BorderSide(color: Color(0xFF7B3F61), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Business Name',
                      labelStyle: GoogleFonts.montserrat(
                        color: const Color(0xFF7B3F61),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                    style: GoogleFonts.montserrat(fontSize: 14),
                    onSubmitted: (_) => _searchVendors(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isSearching ? null : _searchVendors,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSearching
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (searchResults.isEmpty && !isSearching)
              Expanded(
                child: Center(
                  child: Text(
                    'Search for your business to get started',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: const Color(0xFF6E6E6E),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final vendor = searchResults[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFDCC7AA)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          vendor['vendor_name'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7B3F61),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (vendor['vendor_location'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                vendor['vendor_location'],
                                style: GoogleFonts.montserrat(fontSize: 12),
                              ),
                            ],
                            if (vendor['vendor_description'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                vendor['vendor_description'],
                                style: GoogleFonts.montserrat(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => _claimVendor(vendor),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B3F61),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Claim',
                            style: GoogleFonts.montserrat(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}