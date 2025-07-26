import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'firebase_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs for subscriptions
  static const String _monthlySubscriptionId = 'little_learners_monthly';
  static const String _yearlySubscriptionId = 'little_learners_yearly';

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
      final Set<String> ids = {_monthlySubscriptionId, _yearlySubscriptionId};
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

      if (product.id == _monthlySubscriptionId ||
          product.id == _yearlySubscriptionId) {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
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
    // Implement your server-side purchase verification here
    // This is a placeholder implementation
    return true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    // Update user's subscription status in Firebase
    DateTime? expiresAt;
    if (purchaseDetails.productID == _monthlySubscriptionId) {
      expiresAt = DateTime.now().add(const Duration(days: 30));
    } else if (purchaseDetails.productID == _yearlySubscriptionId) {
      expiresAt = DateTime.now().add(const Duration(days: 365));
    }

    await _firebaseService.updateSubscriptionStatus(
      status: 'premium',
      expiresAt: expiresAt,
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
