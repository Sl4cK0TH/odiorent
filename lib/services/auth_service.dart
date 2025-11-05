import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// We'll define the AppUser model in 'lib/models/user.dart'
// import 'package:odiorent/models/user.dart'; // Make sure this path is correct

// Get the global Supabase client
final supabase = Supabase.instance.client;

class AuthService {
  /// --- SIGN UP (Day 2 Task - REFACTORED) ---
  /// Creates a new user in `auth.users` and (thanks to our trigger)
  /// a new row in `public.profiles`.
  Future<void> signUp({
    required String email,
    required String password,
    required String role, // "renter" or "landlord"
    // --- UPDATED FIELDS ---
    required String lastName,
    required String firstName,
    String? middleName, // Nullable
    required String userName,
    required String phoneNumber,
    // --- END UPDATED FIELDS ---
  }) async {
    try {
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        // 'data' is where we pass the extra fields for our 'profiles' table.
        // Our SQL trigger (handle_new_user) will use this.
        data: {
          'email': email, // Include email in metadata
          'role': role,
          // --- UPDATED DATA MAP ---
          'last_name': lastName,
          'first_name': firstName,
          'middle_name': middleName,
          'user_name': userName,
          'phone_number': phoneNumber,
          // --- END UPDATED DATA MAP ---
        },
      );

      // Note: By default, Supabase sends a confirmation email.
      // You can disable this in your Supabase project settings if you want.
      // Go to: Authentication -> Providers -> Email -> Enable email confirmation (toggle off)
      if (authResponse.user == null) {
        // This is a safeguard
        throw const AuthException('Sign up failed: User is null');
      }
    } on AuthException catch (e) {
      // Show a snackbar or print the error
      debugPrint("Auth Exception: ${e.message}");
      rethrow; // Re-throw the error to handle it in the UI
    } catch (e) {
      debugPrint("An unknown error occurred: $e");
      rethrow;
    }
  }

  /// --- SIGN IN (Day 2 Task) ---
  /// Signs in an existing user.
  Future<void> signIn({required String email, required String password}) async {
    try {
      debugPrint("=== AUTH SERVICE SIGN IN ===");
      debugPrint("Attempting to sign in with email: $email");

      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint("Auth response received");
      debugPrint("User ID: ${authResponse.user?.id}");
      debugPrint("User email: ${authResponse.user?.email}");
      debugPrint("Email confirmed: ${authResponse.user?.emailConfirmedAt}");

      if (authResponse.user == null) {
        debugPrint("❌ User is null in auth response");
        throw const AuthException('Sign in failed: User is null');
      }

      debugPrint("✅ Sign in successful in AuthService");
    } on AuthException catch (e) {
      debugPrint("❌ Auth Exception during sign in:");
      debugPrint("   Message: ${e.message}");
      debugPrint("   Status code: ${e.statusCode}");
      rethrow;
    } catch (e) {
      debugPrint("❌ Unknown error during sign in: $e");
      rethrow;
    }
  }

  /// --- SIGN OUT (Day 2 Task) ---
  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      debugPrint("Auth Exception: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("An unknown error occurred: $e");
      rethrow;
    }
  }

  /// --- GET ROLE (Day 2 Task - Fixed) ---
  /// Fetches the user's role from the `profiles` table.
  /// We'll call this after login to know where to send the user.
  Future<String?> getRole(String userId) async {
    try {
      // Select 'role' from the 'profiles' table where 'id' matches
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single(); // .single() expects one row and returns it as a Map

      // The response data will be a Map, e.g., {'role': 'renter'}
      // We cast it as nullable Map and check if it's null
      final data = response as Map<String, dynamic>?;

      if (data == null || data.isEmpty) {
        debugPrint("Error getting role: User profile not found or empty.");
        return null;
      }

      return data['role'] as String;
    } catch (e) {
      debugPrint("Error getting role: $e");
      return null;
    }
  }

  /// --- GET CURRENT AUTH USER ---
  /// A handy helper to get the currently logged-in user from Supabase.
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  /// --- GET EMAIL BY USERNAME (Day 2 Task) ---
  /// Fetches the email address associated with a username.
  /// Returns null if username not found.
  Future<String?> getEmailByUsername(String username) async {
    try {
      debugPrint("=== GET EMAIL BY USERNAME DEBUG ===");
      debugPrint("Searching for username: '$username'");

      // First, let's check if the user exists at all
      final userCheckResponse = await supabase
          .from('profiles')
          .select('id, user_name, email')
          .eq('user_name', username)
          .maybeSingle();

      debugPrint("Full query response: $userCheckResponse");

      if (userCheckResponse == null) {
        debugPrint("❌ No user found with username: '$username'");
        debugPrint(
          "   This means the username doesn't exist in the profiles table",
        );
        return null;
      }

      debugPrint("✅ User found in profiles table:");
      debugPrint("   - ID: ${userCheckResponse['id']}");
      debugPrint("   - Username: ${userCheckResponse['user_name']}");
      debugPrint("   - Email: ${userCheckResponse['email']}");

      final email = userCheckResponse['email'] as String?;

      if (email == null || email.isEmpty) {
        debugPrint("⚠️  User exists but email field is NULL or empty!");
        debugPrint(
          "   This user was created before the email field was added to signup.",
        );
        debugPrint(
          "   You need to manually update this user's email in the database.",
        );
        return null;
      }

      debugPrint("✅ Found email for username '$username': $email");
      debugPrint("=== END DEBUG ===");
      return email;
    } catch (e) {
      debugPrint("❌ Error getting email by username: $e");
      debugPrint("   Stack trace: ${StackTrace.current}");
      return null;
    }
  }

  /// --- DEBUG: GET ALL PROFILES ---
  /// Helper method to see what's in the profiles table (for debugging)
  Future<void> debugPrintAllProfiles() async {
    try {
      debugPrint("=== FETCHING ALL PROFILES FOR DEBUG ===");
      final response = await supabase
          .from('profiles')
          .select('id, user_name, email, role')
          .limit(10);

      debugPrint("Total profiles found: ${(response as List).length}");
      for (var i = 0; i < response.length; i++) {
        final profile = response[i];
        debugPrint("Profile ${i + 1}:");
        debugPrint("  - ID: ${profile['id']}");
        debugPrint("  - Username: ${profile['user_name']}");
        debugPrint("  - Email: ${profile['email']}");
        debugPrint("  - Role: ${profile['role']}");
      }
      debugPrint("=== END DEBUG ===");
    } catch (e) {
      debugPrint("Error fetching profiles: $e");
    }
  }
}
