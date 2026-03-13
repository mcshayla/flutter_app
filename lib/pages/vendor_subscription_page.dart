import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorSubscriptionPage extends StatefulWidget {
  final String userId;

  const VendorSubscriptionPage({
    required this.userId,
    super.key,
  });

  @override
  State<VendorSubscriptionPage> createState() => _VendorSubscriptionPageState();
}

class _VendorSubscriptionPageState extends State<VendorSubscriptionPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Replace these with your actual Stripe Price IDs
  // final String monthlyPriceId = 'price_1SnvuFGv1vBeiVDOIfacBvQS';
  final String monthlyPriceId = 'price_1SoG3VGpavVyOfbN5M6NvL5k';
  // final String yearlyPriceId = 'price_1SnvuFGv1vBeiVDOIfacBvQt';
  final String yearlyPriceId = 'price_1Sq4aNGpavVyOfbN9rpaau8N';
  final String discountedMonthlyPriceId = 'price_1TAMjFGpavVyOfbN0XDE9MtD';

  final _promoController = TextEditingController();
  String? _promoError;
  static const _validCode = 'SAYYES10';

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromoCode() {
    final code = _promoController.text.trim().toUpperCase();
    if (code == _validCode) {
      setState(() => _promoError = null);
      _createCheckoutSession(discountedMonthlyPriceId);
    } else {
      setState(() => _promoError = 'Invalid promo code. Please try again.');
    }
  }

  Future<void> _createCheckoutSession(String priceId) async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'priceId': priceId,
          'userId': widget.userId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      var checkoutUrl = data['url'] as String;
      if (!checkoutUrl.startsWith('http://') && !checkoutUrl.startsWith('https://')) {
        checkoutUrl = 'https://$checkoutUrl';
      }

      final uri = Uri.parse(checkoutUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Could not open Stripe Checkout');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Choose Your Plan',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select a subscription plan',
                style: GoogleFonts.bodoniModa(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get access to manage your vendor profile and reach more couples',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF6E6E6E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Monthly Plan
              _buildPlanCard(
                title: 'Monthly',
                price: '\$20',
                period: 'per month',
                features: [
                  'View and edit your vendor profile',
                  'Track profile views and clicks'
                ],
                onTap: () => _createCheckoutSession(monthlyPriceId),
              ),
              const SizedBox(height: 20),

              // Yearly Plan
              _buildPlanCard(
                title: 'Yearly',
                price: '\$200',
                period: 'per year',
                savings: 'Save \$40',
                features: [
                  'All monthly features',
                  'Save 17% compared to monthly',
                ],
                onTap: () => _createCheckoutSession(yearlyPriceId),
                isRecommended: true,
              ),

              const SizedBox(height: 40),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7B3F61),
                  ),
                ),

              const SizedBox(height: 32),
              const Divider(color: Color(0xFFDCC7AA)),
              const SizedBox(height: 24),

              // Promo code section
              Text(
                'Have a promo code?',
                style: GoogleFonts.bodoniModa(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter code',
                        hintStyle: GoogleFonts.montserrat(
                          color: const Color(0xFF6E6E6E),
                          fontSize: 13,
                        ),
                        errorText: _promoError,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF7B3F61),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _applyPromoCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B3F61),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    String? savings,
    required List<String> features,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended
              ? const Color(0xFF7B3F61)
              : const Color(0xFFDCC7AA),
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isRecommended
            ? const Color(0xFF7B3F61).withOpacity(0.05)
            : Colors.white,
      ),
      child: Column(
        children: [
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7B3F61),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Center(
                child: Text(
                  'RECOMMENDED',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: GoogleFonts.bodoniModa(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7B3F61),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7B3F61),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        period,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF6E6E6E),
                        ),
                      ),
                    ),
                  ],
                ),
                if (savings != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B3F61),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      savings,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF7B3F61),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: const Color(0xFF6E6E6E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B3F61),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Choose $title',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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