import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:odiorent/models/user.dart'; // Import the AppUser model
import 'package:odiorent/models/admin_user.dart'; // Import the AdminUser model

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
      if (kDebugMode) {
        debugPrint("Auth Exception: ${e.message}");
      }
      rethrow; // Re-throw the error to handle it in the UI
    } catch (e) {
      if (kDebugMode) {
        debugPrint("An unknown error occurred: $e");
      }
      rethrow;
    }
  }

  /// --- SIGN IN (Day 2 Task) ---
  /// Signs in an existing user.
  Future<void> signIn({required String email, required String password}) async {
    try {
      if (kDebugMode) {
        debugPrint("=== AUTH SERVICE SIGN IN ===");
      }
      if (kDebugMode) {
        debugPrint("Attempting to sign in with email: $email");
      }

      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint("Auth response received");
      }
      if (kDebugMode) {
        debugPrint("User ID: ${authResponse.user?.id}");
      }
      if (kDebugMode) {
        debugPrint("User email: ${authResponse.user?.email}");
      }
      if (kDebugMode) {
        debugPrint("Email confirmed: ${authResponse.user?.emailConfirmedAt}");
      }

      if (authResponse.user == null) {
        if (kDebugMode) {
          debugPrint("❌ User is null in auth response");
        }
        throw const AuthException('Sign in failed: User is null');
      }

      if (kDebugMode) {
        debugPrint("✅ Sign in successful in AuthService");
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Auth Exception during sign in:");
      }
      if (kDebugMode) {
        debugPrint("   Message: ${e.message}");
      }
      if (kDebugMode) {
        debugPrint("   Status code: ${e.statusCode}");
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Unknown error during sign in: $e");
      }
      rethrow;
    }
  }

  /// --- SIGN OUT (Day 2 Task) ---
  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint("Auth Exception: ${e.message}");
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("An unknown error occurred: $e");
      }
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
        if (kDebugMode) {
          debugPrint("Error getting role: User profile not found or empty.");
        }
        return null;
      }

      return data['role'] as String;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error getting role: $e");
      }
      return null;
    }
  }

  /// --- GET CURRENT AUTH USER ---
  /// A handy helper to get the currently logged-in user from Supabase.
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  /// --- GET CURRENT USER PROFILE ---
  /// Fetches the full profile details of the currently logged-in user.
  Future<AppUser?> getCurrentUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        return null; // No user logged in
      }

      final response = await supabase
          .from('profiles')
          .select('*') // Select all profile fields
          .eq('id', user.id)
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error getting current user profile: $e");
      }
      return null;
    }
  }

  /// --- GET CURRENT ADMIN USER PROFILE ---
  /// Fetches the full profile details of the currently logged-in admin user.
  /// Maps to the AdminUser model to handle potentially nullable fields for admin profiles.
  Future<AdminUser?> getAdminUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        return null; // No user logged in
      }

      final response = await supabase
          .from('profiles')
          .select('*') // Select all profile fields
          .eq('id', user.id)
          .single();

      return AdminUser.fromMap(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error getting current admin user profile: $e");
      }
      return null;
    }
  }

  /// --- UPDATE USER PASSWORD ---
  /// Updates the password for the currently authenticated user.
  Future<void> updateUserPassword({required String newPassword}) async {
    try {
      await supabase.auth.updateUser(UserAttributes(
        password: newPassword,
      ));
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint("Auth Exception during password update: ${e.message}");
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("An unknown error occurred during password update: $e");
      }
      rethrow;
    }
  }

  /// --- REAUTHENTICATE USER ---
  /// Re-authenticates the user by attempting to sign in with provided credentials.
  /// Used to verify the current password before sensitive operations.
  Future<void> reauthenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // If signInWithPassword succeeds, it means the credentials are correct.
      // No need to do anything else, as the user is already authenticated.
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint("Auth Exception during reauthentication: ${e.message}");
      }
      rethrow; // Re-throw to indicate re-authentication failure
    } catch (e) {
      if (kDebugMode) {
        debugPrint("An unknown error occurred during reauthentication: $e");
      }
      rethrow;
    }
  }

  /// --- GET EMAIL BY USERNAME (Day 2 Task) ---
  /// Fetches the email address associated with a username.
  /// Returns null if username not found.
  Future<String?> getEmailByUsername(String username) async {
    try {
      // First, let's check if the user exists at all
      final userCheckResponse = await supabase
          .from('profiles')
          .select('id, user_name, email')
          .eq('user_name', username)
          .maybeSingle();

      if (userCheckResponse == null) {
        return null;
      }

      final email = userCheckResponse['email'] as String?;

      if (email == null || email.isEmpty) {
        return null;
      }

      return email;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Error getting email by username: $e");
      }
      if (kDebugMode) {
        debugPrint("   Stack trace: ${StackTrace.current}");
      }
      return null;
    }
  }

  /// --- DEBUG: GET ALL PROFILES ---
  /// Helper method to see what's in the profiles table (for debugging)
  Future<void> debugPrintAllProfiles() async {
    try {
      if (kDebugMode) {
        debugPrint("=== FETCHING ALL PROFILES FOR DEBUG ===");
      }
      final response = await supabase
          .from('profiles')
          .select('id, user_name, email, role')
          .limit(10);

      if (kDebugMode) {
        debugPrint("Total profiles found: ${(response as List).length}");
      }
      for (var i = 0; i < response.length; i++) {
        final profile = response[i];
        if (kDebugMode) {
          debugPrint("Profile ${i + 1}:");
        }
        if (kDebugMode) {
          debugPrint("  - ID: ${profile['id']}");
        }
        if (kDebugMode) {
          debugPrint("  - Username: ${profile['user_name']}");
        }
        if (kDebugMode) {
          debugPrint("  - Email: ${profile['email']}");
        }
        if (kDebugMode) {
          debugPrint("  - Role: ${profile['role']}");
        }
      }
      if (kDebugMode) {
        debugPrint("=== END DEBUG ===");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching profiles: $e");
      }
    }
  }
}
