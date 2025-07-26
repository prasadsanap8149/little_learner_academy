import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import '../models/subscription_plan.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs for subscriptions
  static const String _individualMonthlyId =
      'little_learners_individual_monthly';
  static const String _individualYearlyId = 'little_learners_individual_yearly';
  static const String _schoolMonthlyId = 'little_learners_school_monthly';
  static const String _schoolYearlyId = 'little_learners_school_yearly';

  Future<void> initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print('Store not available');
      return;
    }

    // Set up purchase stream listener
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Error: $error'),
    );

    // Load products
    await loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final Set<String> ids = {
        _individualMonthlyId,
        _individualYearlyId,
        _schoolMonthlyId,
        _schoolYearlyId
      };

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(ids);

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        print('Error loading products: ${response.error}');
        return;
      }

      // Products are available
      for (var product in response.productDetails) {
        print('Product found: ${product.id} - ${product.price}');
      }
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> purchaseSubscription(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Error purchasing subscription: $e');
    }
  }

  Future<void> _handlePurchaseUpdate(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show loading UI
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Show error UI
        print('Error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Grant access to premium features
        final bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          await _deliverProduct(purchaseDetails);
        }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Server-side purchase verification should be implemented here
    return true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    DateTime expiresAt;
    bool isSchoolPlan = purchaseDetails.productID.contains('school');

    // Set expiration based on subscription type
    if (purchaseDetails.productID.contains('monthly')) {
      expiresAt = DateTime.now().add(const Duration(days: 30));
    } else {
      expiresAt = DateTime.now().add(const Duration(days: 365));
    }

    // Update subscription in Firestore
    await _firestore.collection('users').doc(userId).update({
      'subscription': {
        'status': 'premium',
        'type': isSchoolPlan ? 'school' : 'individual',
        'productId': purchaseDetails.productID,
        'purchaseDate': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
        'autoRenewing': true,
      }
    });
  }

  Future<bool> isSubscribed() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    final subscription = data['subscription'] as Map<String, dynamic>?;

    if (subscription == null) return false;

    // Check if subscription is active
    if (subscription['status'] != 'premium') return false;

    // Check expiration
    final expiresAt = (subscription['expiresAt'] as Timestamp).toDate();
    return DateTime.now().isBefore(expiresAt);
  }

  Future<bool> isSchoolPlan() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    final subscription = data['subscription'] as Map<String, dynamic>?;

    return subscription?['type'] == 'school' && await isSubscribed();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
