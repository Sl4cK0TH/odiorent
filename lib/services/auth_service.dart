import 'package:flutter/foundation.dart';
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

  /// --- GET EMAIL BY USERNAME (Day 2 Task) ---
  /// Fetches the email address associated with a username.
  /// Returns null if username not found.
  Future<String?> getEmailByUsername(String username) async {
    try {
      if (kDebugMode) {
        debugPrint("=== GET EMAIL BY USERNAME DEBUG ===");
      }
      if (kDebugMode) {
        debugPrint("Searching for username: '$username'");
      }

      // First, let's check if the user exists at all
      final userCheckResponse = await supabase
          .from('profiles')
          .select('id, user_name, email')
          .eq('user_name', username)
          .maybeSingle();

      if (kDebugMode) {
        debugPrint("Full query response: $userCheckResponse");
      }

      if (userCheckResponse == null) {
        if (kDebugMode) {
          debugPrint("❌ No user found with username: '$username'");
        }
        if (kDebugMode) {
          debugPrint(
            "   This means the username doesn't exist in the profiles table",
          );
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint("✅ User found in profiles table:");
      }
      if (kDebugMode) {
        debugPrint("   - ID: ${userCheckResponse['id']}");
      }
      if (kDebugMode) {
        debugPrint("   - Username: ${userCheckResponse['user_name']}");
      }
      if (kDebugMode) {
        debugPrint("   - Email: ${userCheckResponse['email']}");
      }

      final email = userCheckResponse['email'] as String?;

      if (email == null || email.isEmpty) {
        if (kDebugMode) {
          debugPrint("⚠️  User exists but email field is NULL or empty!");
        }
        if (kDebugMode) {
          debugPrint(
            "   This user was created before the email field was added to signup.",
          );
        }
        if (kDebugMode) {
          debugPrint(
            "   You need to manually update this user's email in the database.",
          );
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint("✅ Found email for username '$username': $email");
      }
      if (kDebugMode) {
        debugPrint("=== END DEBUG ===");
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
