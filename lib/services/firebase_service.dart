import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> isSubscribed() async {
    if (currentUser == null) return false;

    final userData =
        await _firestore.collection('users').doc(currentUser!.uid).get();

    if (!userData.exists) return false;

    final subscriptionStatus = userData.data()?['subscription']['status'];
    final expiresAt = userData.data()?['subscription']['expiresAt'];

    if (subscriptionStatus == 'premium' &&
        expiresAt != null &&
        (expiresAt as Timestamp).toDate().isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  Future<void> updateSubscriptionStatus({
    required String status,
    DateTime? expiresAt,
  }) async {
    if (currentUser == null) return;

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'subscription': {
        'status': status,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      },
    });
  }
}
final FirebaseService firebaseService = FirebaseService();
