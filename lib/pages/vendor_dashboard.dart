// vendor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_login.dart';
import 'vendor_edit_profile.dart';
import 'login.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? vendorData;
  Map<String, dynamic>? vendorProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    setState(() => isLoading = true);
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VendorLogin()),
        );
        return;
      }

      // Load vendor profile
      final profileResponse = await supabase
          .from('vendor_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (profileResponse != null) {
        vendorProfile = profileResponse;

        // Load vendor data
        final vendorResponse = await supabase
            .from('vendors')
            .select()
            .eq('vendor_id', profileResponse['vendor_id'])
            .single();

        // Load vendor clicks data
        final clicksResponse = await supabase
            .from('vendor_clicks')
            .select('clicks_on_card, clicks_on_links')
            .eq('vendor_id', profileResponse['vendor_id'])
            .maybeSingle();

        // Load hearts/loves count
        final heartsResponse = await supabase
          .from('users_loved')
          .select('loved_vendor_id')
          .eq('loved_vendor_id', profileResponse['vendor_id'])
          .eq('hearted', true);

        final int heartsCount = (heartsResponse as List).length;

        // Combine all the data
        vendorData = {
          ...vendorResponse,
          'clicks_on_card': clicksResponse?['clicks_on_card'] ?? 0,
          'clicks_on_links': clicksResponse?['clicks_on_links'] ?? 0,
          'num_times_hearted': heartsCount,
        };

      }
    } catch (e) {
      print('Error loading vendor data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
              builder: (_) => const LoginSignup(
                redirect: LoginRedirect.home,
              ),
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF7B3F61),
          ),
        ),
      );
    }

    if (vendorData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Vendor Dashboard',
            style: GoogleFonts.bodoniModa(
              color: const Color(0xFF7B3F61),
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
          ],
        ),
        body: Center(
          child: Text(
            'No vendor profile found. Please contact support.',
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vendor Dashboard',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Welcome, ${vendorData!['vendor_name']}!',
                style: GoogleFonts.bodoniModa(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              _buildStatsCard(),
              const SizedBox(height: 24),

              // Business Information
              _buildSectionHeader('Business Information'),
              const SizedBox(height: 12),
              _buildInfoCard(),
              const SizedBox(height: 24),

              // Edit Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VendorEditProfile(
                          vendorData: vendorData!,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadVendorData();
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(
                    'Edit Profile',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    // You can fetch these from your analytics tables
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCC7AA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCC7AA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Profile Views', '${vendorData!['clicks_on_card'] ?? 0}'),
          _buildStatItem('Link Clicks', '${vendorData!['clicks_on_links'] ?? 0}'),
          _buildStatItem('Hearts', '${vendorData!['num_times_hearted'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.bodoniModa(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7B3F61),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: const Color(0xFF6E6E6E),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.bodoniModa(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF7B3F61),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCC7AA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCC7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Business Name', vendorData!['vendor_name']),
          _buildInfoRow('Description', vendorData!['vendor_description']),
          _buildInfoRow('Location', vendorData!['vendor_location']),
          _buildInfoRow('Email', vendorData!['contact_email']),
          _buildInfoRow('Phone', vendorData!['contact_phone']),
          _buildInfoRow('Website', vendorData!['website_url']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7B3F61),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF6E6E6E),
            ),
          ),
        ],
      ),
    );
  }
}