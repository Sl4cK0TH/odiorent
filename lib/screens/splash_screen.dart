import 'dart:async';
import 'package:flutter/material.dart';
import 'package:odiorent/screens/shared/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Added TickerProviderStateMixin for animation

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Define your brand colors (Green Palette)
  static const Color primaryGreen = Color(0xFF4CAF50); // Main green
  static const Color lightGreen = Color(
    0xFF66BB6A,
  ); // Light green for gradient start
  static const Color darkGreen = Color(
    0xFF388E3C,
  ); // Dark green for gradient end

  @override
  void initState() {
    super.initState();

    // Setup animation controller for logo fade-in
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 1.5 seconds fade-in
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Start the animation
    _animationController.forward();

    // Start the timer to navigate after a delay
    _startTimer();
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _startTimer() {
    // Wait for 5 seconds total before navigating (increased for testing)
    Timer(const Duration(seconds: 5), _navigateToWelcome);
  }

  void _navigateToWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Use BoxDecoration for the gradient background
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
          // Use Stack to layer the subtle background houses
          children: [
            // --- Subtle Background House Pattern (Optional, based on image) ---
            Positioned(
              top: -50,
              left: -50,
              child: Opacity(
                opacity: 0.1, // Very subtle
                child: Image.asset(
                  'assets/images/logo.png', // Use your logo image as a pattern
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
                opacity: 0.1, // Very subtle
                child: Image.asset(
                  'assets/images/logo.png', // Use your logo image as a pattern
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // --- End Subtle Background House Pattern ---
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Animated Logo ---
                  FadeTransition(
                    opacity: _fadeAnimation, // Apply fade-in animation
                    child: Image.asset(
                      'assets/images/logo.png', // Your logo path
                      width: 300, // Adjust size as needed
                      // The logo in your image has a lighter, almost white appearance
                      // You might need to edit the logo file itself for this,
                      // or use a ColorFiltered widget if you want to tint it dynamically.
                      // For now, assuming your `logo.png` might be the lightened version.
                    ),
                  ),

                  // --- End Animated Logo ---
                  const SizedBox(height: 32),

                  // Loading indicator matching your brand color
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
