import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Authentication Service
/// Replaces Supabase Auth with Firebase Auth
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// --- SIGN UP ---
  /// Creates a new user in Firebase Auth and creates profile in Firestore
  Future<void> signUp({
    required String email,
    required String password,
    required String role, // "renter", "landlord", or "admin"
    required String lastName,
    required String firstName,
    String? middleName,
    required String userName,
    required String phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint("=== FIREBASE AUTH SERVICE SIGN UP ===");
        debugPrint("Email: $email, Role: $role");
      }

      // 1. Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Sign up failed: User is null');
      }

      final userId = userCredential.user!.uid;

      if (kDebugMode) {
        debugPrint("✅ User created in Firebase Auth: $userId");
      }

      // 2. Create user profile in Firestore
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'role': role,
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName,
        'userName': userName,
        'phoneNumber': phoneNumber,
        'profilePictureUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint("✅ User profile created in Firestore");
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Firebase Auth Exception: ${e.code} - ${e.message}");
      }
      
      // Provide user-friendly error messages
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign up.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error during sign up: $e");
      }
      rethrow;
    }
  }

  /// --- SIGN IN ---
  /// Signs in an existing user with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint("=== FIREBASE AUTH SERVICE SIGN IN ===");
        debugPrint("Attempting to sign in with email: $email");
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint("✅ User signed in: ${userCredential.user?.uid}");
      }

      // Update last seen
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Firebase Auth Exception: ${e.code} - ${e.message}");
      }

      // Provide user-friendly error messages
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign in.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error during sign in: $e");
      }
      rethrow;
    }
  }

  /// --- SIGN OUT ---
  /// Signs out the current user
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        debugPrint("=== FIREBASE AUTH SERVICE SIGN OUT ===");
      }

      await _auth.signOut();

      if (kDebugMode) {
        debugPrint("✅ User signed out successfully");
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Firebase Auth Exception: ${e.message}");
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error during sign out: $e");
      }
      rethrow;
    }
  }

  /// --- GET ROLE ---
  /// Fetches the user's role from Firestore
  Future<String?> getRole(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint("=== FETCHING USER ROLE ===");
        debugPrint("User ID: $userId");
      }

      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint("❌ User profile not found in Firestore");
        }
        return null;
      }

      final role = doc.data()?['role'] as String?;

      if (kDebugMode) {
        debugPrint("✅ User role: $role");
      }

      return role;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Error fetching user role: $e");
      }
      rethrow;
    }
  }

  /// --- GET USER DATA ---
  /// Fetches complete user profile from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint("❌ User profile not found");
        }
        return null;
      }

      return doc.data();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Error fetching user data: $e");
      }
      rethrow;
    }
  }

  /// --- CHANGE PASSWORD ---
  /// Changes the password for the currently signed-in user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user is currently signed in');
      }

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      if (kDebugMode) {
        debugPrint("✅ Password changed successfully");
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Firebase Auth Exception: ${e.code} - ${e.message}");
      }

      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect.';
          break;
        case 'weak-password':
          errorMessage = 'The new password is too weak.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please sign in again before changing your password.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred while changing password.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error changing password: $e");
      }
      rethrow;
    }
  }

  /// --- SEND PASSWORD RESET EMAIL ---
  /// Sends a password reset email to the specified email address
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (kDebugMode) {
        debugPrint("✅ Password reset email sent to $email");
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Firebase Auth Exception: ${e.code} - ${e.message}");
      }

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error sending password reset: $e");
      }
      rethrow;
    }
  }

  /// --- DELETE ACCOUNT ---
  /// Deletes the current user account
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user is currently signed in');
      }

      // Re-authenticate before deletion
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      final userId = user.uid;

      // Delete user profile from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Delete auth account
      await user.delete();

      if (kDebugMode) {
        debugPrint("✅ Account deleted successfully");
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Firebase Auth Exception: ${e.code} - ${e.message}");
      }

      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Password is incorrect.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please sign in again before deleting your account.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred while deleting account.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error deleting account: $e");
      }
      rethrow;
    }
  }

  /// --- GET CURRENT USER ---
  /// Returns the currently authenticated Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// --- GET EMAIL BY USERNAME ---
  /// Fetches the email address associated with a username
  /// Returns null if username not found
  Future<String?> getEmailByUsername(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userName', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final email = querySnapshot.docs.first.data()['email'] as String?;
      return email;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Error getting email by username: $e");
      }
      return null;
    }
  }

  /// --- GET ADMIN USER PROFILE ---
  /// Fetches the full profile details of the currently logged-in user as AdminUser
  Future<AdminUser?> getAdminUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        return null;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        return null;
      }

      return AdminUser.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error getting admin user profile: $e");
      }
      return null;
    }
  }

  /// --- REAUTHENTICATE USER ---
  /// Re-authenticates the user with their email and password
  /// Used to verify current password before sensitive operations
  Future<void> reauthenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Firebase Auth Exception during reauthentication: ${e.code} - ${e.message}");
      }

      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Password is incorrect.';
          break;
        case 'user-mismatch':
          errorMessage = 'The credential does not match the current user.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential is invalid or has expired.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during reauthentication.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error during reauthentication: $e");
      }
      rethrow;
    }
  }

  /// --- UPDATE USER PASSWORD ---
  /// Updates the password for the currently authenticated user
  Future<void> updateUserPassword({required String newPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Firebase Auth Exception during password update: ${e.code} - ${e.message}");
      }

      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak. Please use a stronger password.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please sign in again before changing your password.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred while updating password.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error during password update: $e");
      }
      rethrow;
    }
  }
}
