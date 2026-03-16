// vendor_claim.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_subscription_page.dart';
import 'vendor_dashboard.dart';
import 'vendor_login.dart';

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
  void initState() {
    super.initState();
    _checkAlreadyVendor();
  }

  /// If this user already has a vendor profile, block them and tell them to log in.
  Future<void> _checkAlreadyVendor() async {
    try {
      final existing = await supabase
          .from('vendor_profiles')
          .select('vendor_id')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (existing != null && mounted) {
        await supabase.auth.signOut();
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Account Already Exists',
              style: GoogleFonts.bodoniModa(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B3F61),
              ),
            ),
            content: Text(
              'A vendor account already exists for this email. Please log in instead.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF6E6E6E),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const VendorLogin()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B3F61),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Go to Login',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // If the check fails just let them proceed normally.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Pushes a full verification page and returns true if ownership is proved.
  /// Using Navigator.push instead of a bottom sheet ensures the screen is not
  /// dismissed by Supabase auth-state events that fire on mobile when
  /// signInWithOtp is called.
  Future<bool> _verifyOwnership(Map<String, dynamic> vendor) async {
    final vendorContactEmail =
        (vendor['contact_email'] ?? '').toString().toLowerCase().trim();

    if (vendorContactEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This profile has no contact email on file. Please contact support to claim it.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _VerifyOwnershipPage(vendorContactEmail: vendorContactEmail),
      ),
    );

    return result == true;
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

      await supabase.from('vendor_profiles').insert({
        'user_id': widget.userId,
        'vendor_id': vendor['vendor_id'],
        'business_name': vendor['vendor_name'],
      });

      if (mounted) {
        // If the vendor record itself is already active, skip subscription
        final vendorIsActive = vendor['subscription_status'] == 'active';

        if (vendorIsActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VendorDashboard()),
          );
          return;
        }

        // Otherwise check vendor_subscriptions table
        final sub = await supabase
            .from('vendor_subscriptions')
            .select('status')
            .eq('user_id', widget.userId)
            .eq('status', 'active')
            .maybeSingle();

        if (!mounted) return;
        if (sub != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VendorDashboard()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VendorSubscriptionPage(userId: widget.userId),
            ),
          );
        }
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
        backgroundColor: Colors.transparent,
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorSubscriptionPage(userId: widget.userId),
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
                              : () async {
                                  final verified =
                                      await _verifyOwnership(vendor);
                                  if (verified) {
                                    await _claimVendor(vendor);
                                  }
                                },
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

// ---------------------------------------------------------------------------
// Standalone two-step verification page
// Using a full route (instead of a bottom sheet) ensures it survives the
// Supabase auth-state change that fires when signInWithOtp is called on mobile.
// ---------------------------------------------------------------------------

class _VerifyOwnershipPage extends StatefulWidget {
  final String vendorContactEmail;

  const _VerifyOwnershipPage({required this.vendorContactEmail});

  @override
  State<_VerifyOwnershipPage> createState() => _VerifyOwnershipPageState();
}

class _VerifyOwnershipPageState extends State<_VerifyOwnershipPage> {
  final supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String _sentToEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final entered = _emailController.text.trim().toLowerCase();
    if (entered.isEmpty || !entered.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email.')),
      );
      return;
    }
    if (entered != widget.vendorContactEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'That email doesn\'t match our records for this business.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithOtp(
        email: entered,
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() {
        _sentToEmail = entered;
        _codeSent = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please enter the verification code from your email.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Save the original user's refresh token before OTP verification
    // changes the active session.
    final originalRefreshToken = supabase.auth.currentSession?.refreshToken;

    try {
      await supabase.auth.verifyOTP(
        email: _sentToEmail,
        token: code,
        type: OtpType.email,
      );

      // Restore the original user's session so the claim is attributed
      // to the correct account.
      if (originalRefreshToken != null) {
        await supabase.auth.setSession(originalRefreshToken);
      }

      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid code: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _codeSent ? 'Enter Verification Code' : 'Verify Business Ownership',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_codeSent) ...[
              Text(
                'Verify Business Ownership',
                style: GoogleFonts.bodoniModa(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the contact email listed on this business profile. We\'ll send a verification code to confirm you own it.',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF6E6E6E),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Business Contact Email',
                  labelStyle:
                      GoogleFonts.montserrat(color: const Color(0xFF7B3F61)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
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
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B3F61),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Send Verification Code',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ] else ...[
              Text(
                'Enter Verification Code',
                style: GoogleFonts.bodoniModa(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification code to $_sentToEmail. Check your inbox and paste it below.',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF6E6E6E),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Paste the code from your email',
                  labelStyle:
                      GoogleFonts.montserrat(color: const Color(0xFF7B3F61)),
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF6E6E6E),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B3F61),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Verify & Claim',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() {
                          _codeSent = false;
                          _codeController.clear();
                        }),
                child: Text(
                  'Back',
                  style:
                      GoogleFonts.montserrat(color: const Color(0xFF7B3F61)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}