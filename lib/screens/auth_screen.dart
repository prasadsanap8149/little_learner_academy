import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/subscription_plan.dart';

enum AuthStatus { unauthenticated, authenticated, loading }

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    if (currentUser == null) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to ensure account picker is shown
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create or update user profile
      await _createOrUpdateUserProfile(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Create or update user profile in Firestore
  Future<void> _createOrUpdateUserProfile(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final userData = await userDoc.get();

      if (!userData.exists) {
        // Create new user profile
        final userProfile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'Anonymous User',
          role: UserRole.student,
          accountType: AccountType.free,
          createdAt: DateTime.now(),
          metadata: {
            'photoURL': user.photoURL,
            'provider': 'google',
            'firstLoginAt': FieldValue.serverTimestamp(),
          },
        );

        await userDoc.set(userProfile.toFirestore());
        
        // Create subscription document
        await _createDefaultSubscription(user.uid);
        
        // Create player progress document
        await _createPlayerProgress(user.uid);
        
      } else {
        // Update existing user profile
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'metadata.photoURL': user.photoURL,
        });
      }
    } catch (e) {
      print('Error creating/updating user profile: $e');
      rethrow;
    }
  }

  // Create default subscription for new users
  Future<void> _createDefaultSubscription(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .set({
        'planId': 'free',
        'status': 'active',
        'startDate': FieldValue.serverTimestamp(),
        'endDate': null,
        'features': [
          'Limited game access',
          'Basic progress tracking',
          'Ads supported',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating default subscription: $e');
      rethrow;
    }
  }

  // Create player progress document
  Future<void> _createPlayerProgress(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('player_data')
          .set({
        'totalScore': 0,
        'levelsCompleted': 0,
        'achievements': [],
        'streakDays': 0,
        'lastPlayedAt': null,
        'totalPlayTime': 0, // in minutes
        'favoriteSubjects': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating player progress: $e');
      rethrow;
    }
  }

  // Complete user setup with child details
  Future<void> completeUserSetup({
    required String childName,
    required int childAge,
    String? parentName,
    UserRole? role,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final userDoc = _firestore.collection('users').doc(currentUser!.uid);
      
      await userDoc.update({
        'metadata.childName': childName,
        'metadata.childAge': childAge,
        'metadata.parentName': parentName,
        'metadata.setupCompleted': true,
        'role': (role ?? UserRole.student).toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update player progress with child details
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('progress')
          .doc('player_data')
          .update({
        'playerName': childName,
        'playerAge': childAge,
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error completing user setup: $e');
      rethrow;
    }
  }

  // Check subscription status
  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    if (currentUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('subscription')
          .doc('current')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting subscription status: $e');
      return null;
    }
  }

  // Update subscription
  Future<void> updateSubscription({
    required String planId,
    required String status,
    DateTime? endDate,
    List<String>? features,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('subscription')
          .doc('current')
          .update({
        'planId': planId,
        'status': status,
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'features': features ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user account type
      AccountType accountType;
      switch (planId) {
        case 'monthly':
        case 'yearly':
          accountType = AccountType.premiumIndividual;
          break;
        case 'school':
          accountType = AccountType.schoolMember;
          break;
        default:
          accountType = AccountType.free;
      }

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'accountType': accountType.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error updating subscription: $e');
      rethrow;
    }
  }

  // Check if user has premium subscription
  Future<bool> hasPremiumSubscription() async {
    final subscription = await getSubscriptionStatus();
    if (subscription == null) return false;

    final status = subscription['status'];
    final endDate = subscription['endDate'] as Timestamp?;
    final planId = subscription['planId'];

    if (status == 'active' && 
        planId != 'free' && 
        (endDate == null || endDate.toDate().isAfter(DateTime.now()))) {
      return true;
    }

    return false;
  }

  // Get user's children profiles (for parent accounts)
  Future<List<Map<String, dynamic>>> getChildrenProfiles() async {
    if (currentUser == null) return [];

    try {
      final query = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('children')
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting children profiles: $e');
      return [];
    }
  }

  // Add child profile (for parent accounts)
  Future<void> addChildProfile({
    required String name,
    required int age,
    String? grade,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('children')
          .add({
        'name': name,
        'age': age,
        'grade': grade,
        'createdAt': FieldValue.serverTimestamp(),
        'progress': {
          'totalScore': 0,
          'levelsCompleted': 0,
          'achievements': [],
        },
      });
    } catch (e) {
      print('Error adding child profile: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final userId = currentUser!.uid;
      
      // Delete user data from Firestore
      await _deleteUserData(userId);
      
      // Delete the user account
      await currentUser!.delete();
      
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // Delete all user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Delete user profile
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Delete subscription data
      final subscriptionDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .get();
      
      for (final doc in subscriptionDocs.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete progress data
      final progressDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .get();
      
      for (final doc in progressDocs.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete children data
      final childrenDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .get();
      
      for (final doc in childrenDocs.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }
}
