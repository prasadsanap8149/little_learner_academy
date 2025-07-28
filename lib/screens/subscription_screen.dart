import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/razorpay_payment_service.dart';
import '../services/auth_service.dart';
import '../models/subscription_plan.dart';
import 'home_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isInitialSetup;
  
  const SubscriptionScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final RazorpayPaymentService _razorpayService = RazorpayPaymentService();
  final AuthService _authService = AuthService();
  final List<SubscriptionPlan> _plans = SubscriptionPlan.availablePlans;
  bool _isLoading = false;
  SubscriptionPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _selectedPlan = _plans.firstWhere((plan) => plan.isPopular, 
        orElse: () => _plans[1]); // Default to yearly plan
  }

  Future<void> _handleSubscription(SubscriptionPlan plan) async {
    if (plan.type == PlanType.free) {
      await _selectFreePlan();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Processing subscription...'),
              ],
            ),
          ),
        );
      }

      // Get user details
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create Razorpay plan mapping
      final razorpayPlan = _mapToRazorpayPlan(plan);
      
      final result = await _razorpayService.initiatePayment(
        planId: razorpayPlan.id,
        userEmail: user.email ?? 'user@example.com',
        userPhone: '+919999999999', // In real app, get from user profile
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // In a real app, you would use Razorpay SDK here
        // For now, simulate successful payment
        await _completeSubscription(plan);
      } else {
        _showError(result.error ?? 'Payment initiation failed');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRazorpayPayment(RazorpayPlan plan) async {

  }

  RazorpayPlan _mapToRazorpayPlan(SubscriptionPlan plan) {
    // Map our SubscriptionPlan to RazorpayPlan
    return RazorpayPlan(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      amount: (plan.price * 100).toInt(), // Convert to paise
      currency: 'INR',
      period: plan.type == PlanType.monthly ? 'monthly' : 'yearly',
      interval: 1,
    );
  }

  Future<void> _selectFreePlan() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update subscription to free plan
      await _authService.updateSubscription(
        planId: 'free',
        status: 'active',
        features: SubscriptionPlan.getPlanById('free')?.features ?? [],
      );

      _navigateToHome();
    } catch (e) {
      _showError('Failed to activate free plan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeSubscription(SubscriptionPlan plan) async {
    try {
      // Calculate end date
      DateTime endDate = DateTime.now().add(plan.duration);
      
      // Update subscription in Firebase
      await _authService.updateSubscription(
        planId: plan.id,
        status: 'active',
        endDate: endDate,
        features: plan.features,
      );

      // Show success message
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Success!'),
            content: Text('You\'ve successfully subscribed to ${plan.name}!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToHome();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Failed to complete subscription: $e');
    }
  }

  void _navigateToHome() {
    if (widget.isInitialSetup) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _launchRazorpayPayment(RazorpayPaymentResult result) async {
    // For web/mobile integration, you would use Razorpay SDK
    // For now, we'll show payment details and launch UPI payment
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: ${result.name}'),
            Text('Amount: ₹${(result.amount! / 100).toStringAsFixed(2)}'),
            Text('Order ID: ${result.orderId}'),
            const SizedBox(height: 16),
            const Text('Choose payment method:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _launchUpiPayment(result);
            },
            child: const Text('Pay via UPI'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _launchWebPayment(result);
            },
            child: const Text('Pay via Web'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUpiPayment(RazorpayPaymentResult result) async {
    final amount = (result.amount! / 100).toStringAsFixed(2);
    final upiUrl = 'upi://pay?pa=merchant@paytm&pn=Little Learners Academy'
        '&am=$amount&cu=INR&tn=Subscription Payment&tr=${result.orderId}';
    
    try {
      // Copy UPI URL to clipboard
      await Clipboard.setData(ClipboardData(text: upiUrl));
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('UPI Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('UPI payment URL has been copied to clipboard.'),
                const SizedBox(height: 16),
                Text('Amount: ₹$amount'),
                Text('Order ID: ${result.orderId}'),
                const SizedBox(height: 16),
                const Text('Please open your UPI app and paste the payment URL.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentSuccess();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Failed to prepare UPI payment: $e');
    }
  }

  Future<void> _launchWebPayment(RazorpayPaymentResult result) async {
    final amount = (result.amount! / 100).toStringAsFixed(2);
    final paymentUrl = 'https://your-payment-gateway.com/pay'
        '?amount=$amount&order_id=${result.orderId}&plan=${result.description}';
    
    try {
      // Copy payment URL to clipboard
      await Clipboard.setData(ClipboardData(text: paymentUrl));
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Web Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Payment URL has been copied to clipboard.'),
                const SizedBox(height: 16),
                Text('Amount: ₹$amount'),
                Text('Order ID: ${result.orderId}'),
                const SizedBox(height: 16),
                const Text('Please open your browser and paste the URL to complete payment.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentSuccess();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Failed to prepare web payment: $e');
    }
  }

  void _showPaymentSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment initiated! You will receive confirmation shortly.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
    Navigator.of(context).pop(); // Go back to previous screen
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() => _isLoading = true);
      
      // In a real app, you would verify with your backend
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to restore purchases: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPlanCard(RazorpayPlan plan) {
    final bool isYearly = plan.id.contains('yearly');
    final Color cardColor = isYearly ? Colors.blue.shade50 : Colors.green.shade50;
    final Color borderColor = isYearly ? Colors.blue : Colors.green;
    final IconData icon = isYearly ? Icons.calendar_today : Icons.today;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: InkWell(
          onTap: () => _handleRazorpayPayment(plan),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.formattedPrice,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: borderColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'per ${plan.period}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem('✓ Ad-free experience', borderColor),
                      const SizedBox(height: 4),
                      _buildFeatureItem('✓ All premium content', borderColor),
                      const SizedBox(height: 4),
                      _buildFeatureItem('✓ Unlimited access', borderColor),
                      const SizedBox(height: 4),
                      _buildFeatureItem('✓ Offline support', borderColor),
                      if (isYearly) ...[
                        const SizedBox(height: 4),
                        _buildFeatureItem('✓ Save 20%', borderColor, isHighlight: true),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Subscribe Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, Color color, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 16,
          color: isHighlight ? Colors.orange : color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isHighlight ? Colors.orange : Colors.grey[700],
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }



  void _skipForNow() {
    if (widget.isInitialSetup) {
      _selectFreePlan();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Choose Your Plan' : 'Upgrade Plan'),
        backgroundColor: const Color(0xFF6B73FF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: widget.isInitialSetup ? [
          TextButton(
            onPressed: _skipForNow,
            child: const Text(
              'Skip for now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ] : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B73FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unlock Premium Learning',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get access to all educational games and features',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Plans Section
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Free Plan
                        _buildSubscriptionPlanCard(_plans[0]),
                        const SizedBox(height: 16),

                        // Premium Plans
                        ..._plans.skip(1).map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSubscriptionPlanCard(plan),
                        )),

                        const SizedBox(height: 24),

                        // Features Comparison
                        _buildFeaturesComparison(),

                        const SizedBox(height: 24),

                        // Trust Indicators
                        _buildTrustIndicators(),
                      ],
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

  Widget _buildSubscriptionPlanCard(SubscriptionPlan plan) {
    final isSelected = _selectedPlan?.id == plan.id;
    final isFree = plan.type == PlanType.free;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFree ? const Color(0xFFF8F9FA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF6B73FF)
                : plan.isPopular
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFE8E8E8),
            width: isSelected ? 3 : plan.isPopular ? 2 : 1,
          ),
          boxShadow: [
            if (plan.isPopular || isSelected)
              BoxShadow(
                color: (plan.isPopular ? const Color(0xFFFFD700) : const Color(0xFF6B73FF))
                    .withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ),
                if (plan.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (plan.discountText != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      plan.discountText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              plan.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isFree ? 'Free' : '₹${plan.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                if (!isFree) ...[
                  const SizedBox(width: 4),
                  Text(
                    '/${plan.type == PlanType.monthly ? 'month' : 'year'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7F8C8D),
                    ),
                  ),
                ],
                if (plan.type == PlanType.yearly) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(₹${plan.pricePerMonth.toStringAsFixed(0)}/month)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Features
            ...plan.features.take(4).map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: isFree ? const Color(0xFF95A5A6) : const Color(0xFF27AE60),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _handleSubscription(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFree 
                      ? const Color(0xFF95A5A6)
                      : const Color(0xFF6B73FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isFree ? 0 : 4,
                ),
                child: _isLoading && _selectedPlan?.id == plan.id
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isFree ? 'Continue with Free' : 'Subscribe Now',
                        style: const TextStyle(
                          fontSize: 16,
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

  Widget _buildFeaturesComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you get with Premium',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          
          ...[
            {'icon': Icons.games, 'text': 'Access to ALL educational games'},
            {'icon': Icons.schedule, 'text': 'Unlimited daily play time'},
            {'icon': Icons.analytics, 'text': 'Detailed progress tracking'},
            {'icon': Icons.block, 'text': 'Completely ad-free experience'},
            {'icon': Icons.offline_bolt, 'text': 'Offline mode for games'},
            {'icon': Icons.family_restroom, 'text': 'Family sharing (up to 4 children)'},
            {'icon': Icons.support_agent, 'text': 'Priority customer support'},
            {'icon': Icons.emoji_events, 'text': 'Exclusive achievement badges'},
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B73FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 18,
                    color: const Color(0xFF6B73FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['text'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrustItem(Icons.security, 'Secure\nPayments'),
              _buildTrustItem(Icons.cancel, 'Cancel\nAnytime'),
              _buildTrustItem(Icons.family_restroom, '10K+\nHappy Families'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '30-day money-back guarantee',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: const Color(0xFF6B73FF),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF7F8C8D),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


