import 'dart:async';
import 'package:flutter/material.dart';

// 1. --- Import all the screens we need to navigate to ---
import 'package:odiorent/screens/shared/welcome_screen.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/push_notification_service.dart';
import 'package:odiorent/screens/renter/renter_home_screen.dart';
import 'package:odiorent/screens/landlord/landlord_home_screen.dart';
import 'package:odiorent/screens/admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Define your brand colors (Green Palette)
  static const Color lightGreen = Color(0xFF66BB6A); // Light green for gradient
  static const Color darkGreen = Color(0xFF388E3C); // Dark green for gradient

  // 2. --- Add the FirebaseAuthService ---
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void initState() {
    super.initState();

    // Setup animation controller (same as before)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // 3. --- Call the new redirection logic ---
    // Instead of a simple timer, we call _redirectUser
    _redirectUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 4. --- This is the new "Auth-Aware" logic ---
  Future<void> _redirectUser() async {
    // We wait for at least 2 seconds (2000ms) to let the animation play
    // and to ensure Supabase has initialized.
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return; // Check if the widget is still on screen

    // Get the current user from Supabase
    final currentUser = _authService.getCurrentUser();

    if (currentUser == null) {
      // --- Case 1: No user is logged in ---
      _navigateTo(const WelcomeScreen());
    } else {
      // --- Case 2: A user is logged in ---
      // Initialize Push Notification Service
      // We do this here because we need the user's ID.
      // This is a "fire-and-forget" call.
      PushNotificationService().init(currentUser.uid);
      
      // Get their role from our 'profiles' table
      final role = await _authService.getRole(currentUser.uid);

      if (!mounted) return; // Check again after the async call

      // Navigate based on the role
      switch (role) {
        case 'renter':
          _navigateTo(const RenterHomeScreen());
          break;
        case 'landlord':
          _navigateTo(const LandlordHomeScreen());
          break;
        case 'admin':
          _navigateTo(const AdminDashboardScreen());
          break;
        default:
          // Fallback: If role is null or unknown, send to Welcome Screen
          _navigateTo(const WelcomeScreen());
      }
    }
  }

  /// 5. --- A helper function for navigation ---
  void _navigateTo(Widget screen) {
    // Use pushReplacement to prevent the user from pressing "back"
    // and returning to the splash screen.
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => screen));
  }

  // 6. --- The build method is UNCHANGED ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightGreen, // Start with light green
              darkGreen, // End with dark green
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset('assets/images/logo.png', width: 300),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
