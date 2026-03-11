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

class _VendorSubscriptionPageState extends State<VendorSubscriptionPage>
    with WidgetsBindingObserver {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _awaitingReturn = false;
  bool _subscriptionActivated = false;

  // Stripe Price IDs
  final String monthlyPriceId = 'price_1SoG3VGpavVyOfbN5M6NvL5k';
  final String yearlyPriceId = 'price_1Sq4aNGpavVyOfbN9rpaau8N';
  // Premium & Elite tiers - set these once Stripe products are created
  final String premiumMonthlyPriceId = 'price_PREMIUM_MONTHLY';
  final String eliteMonthlyPriceId = 'price_ELITE_MONTHLY';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingReturn) {
      _awaitingReturn = false;
      _checkSubscriptionStatus();
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    setState(() => _isLoading = true);
    try {
      // Poll up to 10 times with 2s delay to allow webhook to process
      for (int i = 0; i < 10; i++) {
        final data = await supabase
            .from('vendor_subscriptions')
            .select('status')
            .eq('user_id', widget.userId)
            .eq('status', 'active')
            .maybeSingle();

        if (data != null) {
          if (mounted) {
            setState(() {
              _subscriptionActivated = true;
              _isLoading = false;
            });
          }
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
      // Timed out — webhook may still be processing
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment received! Your subscription may take a moment to activate.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
      _awaitingReturn = true;
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
      body: _subscriptionActivated
          ? _buildSuccessView()
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Your Plan',
                style: GoogleFonts.bodoniModa(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get your vendor profile in front of couples actively planning their wedding',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF6E6E6E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Basic Plan (Monthly)
              _buildPlanCard(
                title: 'Basic',
                price: '\$20',
                period: 'per month',
                features: [
                  'Vendor listing on easiYESt',
                  'Edit your profile & photos',
                  'Track profile views and link clicks',
                  'Hearts & diamond counts',
                ],
                onTap: () => _createCheckoutSession(monthlyPriceId),
              ),
              const SizedBox(height: 20),

              // Premium Plan
              _buildPlanCard(
                title: 'Premium',
                price: '\$50',
                period: 'per month',
                badge: 'POPULAR',
                features: [
                  'Everything in Basic',
                  'Featured badge on your listing',
                  'Priority placement in category',
                  'Respond to couple reviews',
                  'Enhanced analytics dashboard',
                ],
                onTap: () => _createCheckoutSession(premiumMonthlyPriceId),
                isRecommended: true,
              ),
              const SizedBox(height: 20),

              // Elite Plan
              _buildPlanCard(
                title: 'Elite',
                price: '\$100',
                period: 'per month',
                badge: 'BEST VISIBILITY',
                features: [
                  'Everything in Premium',
                  'Homepage featured placement',
                  'Top of category results',
                  'Promoted listing badge',
                  'Priority support',
                ],
                onTap: () => _createCheckoutSession(eliteMonthlyPriceId),
              ),
              const SizedBox(height: 12),

              // Annual savings note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC7AA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCC7AA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF7B3F61), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pay annually and save up to 17%. Annual plans available at checkout.',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7B3F61),
                  ),
                ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF7B3F61), size: 80),
            const SizedBox(height: 24),
            Text(
              'Subscription Activated!',
              style: GoogleFonts.bodoniModa(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7B3F61),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your vendor profile is now live. Couples can discover you on easiYESt.',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF6E6E6E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B3F61),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Go to My Profile',
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
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    String? savings,
    String? badge,
    required List<String> features,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    final showBadge = badge != null || isRecommended;
    final badgeLabel = badge ?? (isRecommended ? 'RECOMMENDED' : '');

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
          if (showBadge)
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
                  badgeLabel,
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