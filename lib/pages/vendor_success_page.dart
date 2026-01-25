import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vendor_claim.dart';

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
    // Wait a moment to show the success message
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VendorClaimPage(userId: user.id),
        ),
      );
    } else {
      // If no user, something went wrong - show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not found. Please sign in again.'),
          backgroundColor: Colors.red,
        ),
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
                'Your subscription is now active.\nRedirecting you to set up your vendor profile...',
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