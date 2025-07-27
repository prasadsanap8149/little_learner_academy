import 'dart:async';
import 'firebase_service.dart';
import 'razorpay_payment_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final RazorpayPaymentService _razorpayService = RazorpayPaymentService();

  Future<void> initialize() async {
    // Initialize any required services
    print('Subscription service initialized with Razorpay');
  }

  Future<List<RazorpayPlan>> loadProducts() async {
    return _razorpayService.availablePlans;
  }

  Future<bool> isSubscriptionActive() async {
    return await _firebaseService.isSubscribed();
  }

  Future<void> activateSubscription(String planId) async {
    DateTime expiresAt;
    if (planId == 'monthly') {
      expiresAt = DateTime.now().add(const Duration(days: 30));
    } else if (planId == 'yearly') {
      expiresAt = DateTime.now().add(const Duration(days: 365));
    } else {
      throw Exception('Invalid plan ID');
    }

    await _firebaseService.updateSubscriptionStatus(
      status: 'premium',
      expiresAt: expiresAt,
    );
  }

  Future<void> cancelSubscription() async {
    await _firebaseService.updateSubscriptionStatus(
      status: 'canceled',
      expiresAt: null,
    );
  }

  void dispose() {
    // Clean up any resources
  }
}
