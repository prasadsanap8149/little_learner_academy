import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

class RazorpayPaymentService {
  static final RazorpayPaymentService _instance = RazorpayPaymentService._internal();
  factory RazorpayPaymentService() => _instance;
  RazorpayPaymentService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  
  // Razorpay configuration (replace with your actual keys)
  static const String _keyId = 'rzp_test_your_key_id';
  static const String _keySecret = 'your_key_secret'; // Keep on server!
  static const String _baseUrl = 'https://api.razorpay.com/v1';

  final List<RazorpayPlan> _plans = [
    RazorpayPlan(
      id: 'monthly',
      name: 'Monthly Plan',
      description: 'Full access for 1 month',
      amount: 499, // Amount in paise (₹4.99)
      currency: 'INR',
      period: 'monthly',
    ),
    RazorpayPlan(
      id: 'yearly',
      name: 'Yearly Plan',
      description: 'Full access for 1 year - Save 20%',
      amount: 3999, // Amount in paise (₹39.99)
      currency: 'INR',
      period: 'yearly',
    ),
  ];

  List<RazorpayPlan> get availablePlans => _plans;

  Future<RazorpayPaymentResult> initiatePayment({
    required String planId,
    required String userEmail,
    required String userPhone,
  }) async {
    try {
      final plan = _plans.firstWhere((p) => p.id == planId);
      
      // Create Razorpay order
      final orderId = await _createRazorpayOrder(plan);
      
      return RazorpayPaymentResult(
        success: true,
        orderId: orderId,
        keyId: _keyId,
        amount: plan.amount,
        currency: plan.currency,
        name: 'Little Learners Academy',
        description: plan.description,
        prefill: {
          'email': userEmail,
          'contact': userPhone,
        },
      );
      
    } catch (e) {
      return RazorpayPaymentResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<String> _createRazorpayOrder(RazorpayPlan plan) async {
    final auth = base64Encode(utf8.encode('$_keyId:$_keySecret'));
    
    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': plan.amount,
        'currency': plan.currency,
        'receipt': 'order_${DateTime.now().millisecondsSinceEpoch}',
        'notes': {
          'plan_id': plan.id,
          'plan_name': plan.name,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception('Failed to create Razorpay order: ${response.body}');
    }
  }

  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      // Verify payment signature
      if (_verifySignature(paymentId, orderId, signature)) {
        // Update subscription status
        await _updateSubscriptionStatus(orderId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }

  bool _verifySignature(String paymentId, String orderId, String signature) {
    // Implement HMAC SHA256 signature verification
    // This should be done on your backend for security
    // For demo purposes, we'll return true
    return true;
  }

  Future<void> _updateSubscriptionStatus(String orderId) async {
    // Fetch order details to get plan info
    final orderDetails = await _getOrderDetails(orderId);
    final planId = orderDetails['notes']['plan_id'];
    
    DateTime expiresAt;
    if (planId == 'monthly') {
      expiresAt = DateTime.now().add(const Duration(days: 30));
    } else {
      expiresAt = DateTime.now().add(const Duration(days: 365));
    }

    await _firebaseService.updateSubscriptionStatus(
      status: 'premium',
      expiresAt: expiresAt,
    );
  }

  Future<Map<String, dynamic>> _getOrderDetails(String orderId) async {
    final auth = base64Encode(utf8.encode('$_keyId:$_keySecret'));
    
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/$orderId'),
      headers: {
        'Authorization': 'Basic $auth',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch order details');
    }
  }

  // For UPI payments (simplified)
  Future<String> generateUpiPaymentLink({
    required String planId,
    required String userEmail,
  }) async {
    final plan = _plans.firstWhere((p) => p.id == planId);
    final amount = (plan.amount / 100).toStringAsFixed(2); // Convert paise to rupees
    
    // Generate UPI payment link
    final upiLink = 'upi://pay?pa=merchant@paytm&pn=Little Learners Academy'
        '&am=$amount&cu=INR&tn=Subscription Payment';
    
    return upiLink;
  }
}

class RazorpayPlan {
  final String id;
  final String name;
  final String description;
  final int amount; // Amount in paise
  final String currency;
  final String period;

  RazorpayPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.currency,
    required this.period,
  });

  String get formattedPrice => '₹${(amount / 100).toStringAsFixed(2)}';
}

class RazorpayPaymentResult {
  final bool success;
  final String? orderId;
  final String? keyId;
  final int? amount;
  final String? currency;
  final String? name;
  final String? description;
  final Map<String, String>? prefill;
  final String? error;

  RazorpayPaymentResult({
    required this.success,
    this.orderId,
    this.keyId,
    this.amount,
    this.currency,
    this.name,
    this.description,
    this.prefill,
    this.error,
  });
}
