import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _createUserDocument(userCredential.user!);
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final userData = await userDoc.get();

    if (!userData.exists) {
      await userDoc.set({
        'email': user.email,
        'name': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'subscription': {
          'status': 'free',
          'expiresAt': null,
        },
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
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
