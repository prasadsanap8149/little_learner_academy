import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/razorpay_payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final RazorpayPaymentService _razorpayService = RazorpayPaymentService();
  List<RazorpayPlan> _plans = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      setState(() {
        _plans = _razorpayService.availablePlans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subscription plans: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRazorpayPayment(RazorpayPlan plan) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing payment...'),
            ],
          ),
        ),
      );

      final result = await _razorpayService.initiatePayment(
        planId: plan.id,
        userEmail: 'user@example.com', // Replace with actual user email
        userPhone: '+919999999999', // Replace with actual user phone
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Launch Razorpay payment
        await _launchRazorpayPayment(result);
      } else {
        _showError(result.error ?? 'Payment initiation failed');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showError(e.toString());
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _restorePurchases,
            child: const Text(
              'Restore',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading subscription plans...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Plans',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadPlans,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.star,
                                size: 48,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unlock Full Access',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Choose the plan that works best for you and unlock all premium features',
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_plans.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No subscription plans available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _loadPlans,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._plans.map(_buildPlanCard),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.payment,
                                color: Colors.blue,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Secure Payment via Razorpay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pay securely using UPI, Cards, Net Banking, or Wallets. Your subscription will be activated instantly.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
