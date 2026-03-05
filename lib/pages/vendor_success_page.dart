import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_dashboard.dart';
import 'vendor_create.dart';

class VendorSuccessPage extends StatefulWidget {
  final String? sessionId;

  const VendorSuccessPage({
    this.sessionId,
    super.key,
  });

  @override
  State<VendorSuccessPage> createState() => _VendorSuccessPageState();
}

class _VendorSuccessPageState extends State<VendorSuccessPage> {
  @override
  void initState() {
    super.initState();
    _navigateToClaimPage();
  }

  Future<void> _navigateToClaimPage() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not found. Please sign in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profile = await supabase
        .from('vendor_profiles')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (!mounted) return;

    if (profile != null) {
      // Already claimed a vendor — go to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VendorDashboard()),
      );
    } else {
      // No profile yet — go to create vendor form
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VendorCreatePage(userId: user.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF7B3F61),
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Successful!',
                style: GoogleFonts.bodoniModa(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your subscription is now active.\nRedirecting you...',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF6E6E6E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFF7B3F61),
              ),
            ],
          ),
        ),
      ),
    );
  }
}