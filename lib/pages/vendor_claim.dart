// vendor_claim.dart
//
// The vendor start page: create a new listing here, or claim an existing one
// on the website. Claiming isn't in the app: the website checks the emailed
// code on the server (start_vendor_claim / finish_vendor_claim).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_subscription_page.dart';
import 'vendor_dashboard.dart';
import 'vendor_create.dart';
import '../utils/vendor_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where vendors claim a listing that's already on easiYESt.
const kClaimListingUrl = 'https://www.easiyest.com/vendor.html';

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

  @override
  void initState() {
    super.initState();
    _checkAlreadyVendor();
  }

  /// If this user already has a vendor profile, route them to the right place
  /// instead of making them log in again from scratch.
  Future<void> _checkAlreadyVendor() async {
    try {
      final existing = await supabase
          .from('vendor_profiles')
          .select('vendor_id')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (existing == null || !mounted) return;

      // They have a vendor profile — check if they have an active subscription.
      bool isActive = !kVendorPaymentRequired;
      if (!isActive) {
        final vendorRecord = await supabase
            .from('vendors')
            .select('subscription_status')
            .eq('vendor_user_id', widget.userId)
            .maybeSingle();
        if (vendorRecord?['subscription_status'] == 'active') isActive = true;
      }

      if (!isActive) {
        final sub = await supabase
            .from('vendor_subscriptions')
            .select('status')
            .eq('user_id', widget.userId)
            .inFilter('status', ['active', 'trialing'])
            .maybeSingle();
        isActive = sub != null;
      }

      if (!mounted) return;

      if (isActive) {
        // Already paid — go straight to the dashboard.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VendorDashboard()),
        );
      } else {
        // Claimed but never paid — resume at the subscription page.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VendorSubscriptionPage(userId: widget.userId),
          ),
        );
      }
    } catch (_) {
      // If the check fails just let them proceed normally.
    }
  }

  Future<void> _openWebsite() async {
    final ok = await launchUrl(Uri.parse(kClaimListingUrl),
        mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit easiyest.com/vendor.html to claim your listing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const plum = Color(0xFF7B3F61);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Your Business',
          style: GoogleFonts.playfairDisplay(
            color: plum,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'List your business',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: plum,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your listing so couples can find you.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF6E6E6E),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => kVendorPaymentRequired
                      ? VendorSubscriptionPage(userId: widget.userId)
                      : VendorCreatePage(userId: widget.userId),
                ),
              );
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
              foregroundColor: plum,
              side: const BorderSide(color: plum, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF7F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDCC7AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Is your business already listed?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: plum,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'If your business is already listed on easiYESt, claim it on our website. '
                  "We'll email a code to the business email on file to confirm it's yours. "
                  'Then you can manage it here in the app too.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _openWebsite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plum,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Claim on easiyest.com',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
