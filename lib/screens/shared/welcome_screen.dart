import 'package:flutter/material.dart';
import 'package:odiorent/screens/shared/login_screen.dart';
import 'package:odiorent/screens/shared/signup_screen.dart';
import 'package:odiorent/widgets/glass_container.dart';
import 'package:odiorent/widgets/custom_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // --- Define Brand Colors (Green Palette) ---
  static const Color primaryGreen = Color(0xFF4CAF50); // Main green
  static const Color lightGreen = Color(
    0xFF66BB6A,
  ); // Light green for gradient start
  static const Color darkGreen = Color(
    0xFF388E3C,
  ); // Dark green for gradient end
  static const Color darkText = Color(0xFF1B5E20); // Dark green text

  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo fade-in and scale animation
    _logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Card slide up from bottom animation
    _cardSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.3), // Start 30% below
          end: Offset.zero, // End at normal position
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    // Card fade-in animation
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToSignUp(BuildContext context, String role) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => SignUpScreen(role: role)));
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- Background Gradient ---
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lightGreen, darkGreen],
              ),
            ),
          ),

          // --- Animated Logo at the top ---
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: FadeTransition(
                  opacity: _logoAnimation,
                  child: ScaleTransition(
                    scale: _logoAnimation,
                    child: Image.asset('assets/images/logo.png', width: 300),
                  ),
                ),
              ),
            ),
          ),

          // --- Animated Bottom Card with Glass Effect ---
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _cardSlideAnimation,
              child: FadeTransition(
                opacity: _cardFadeAnimation,
                child: GlassContainer(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: double.infinity,
                  opacity: 0.2,
                  blurAmount: 10,
                  customBorderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Welcome',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- Sign up as Renter Button ---
                        CustomButton(
                          text: 'Sign up as Renter',
                          onPressed: () => _navigateToSignUp(context, 'renter'),
                          backgroundColor: primaryGreen,
                        ),
                        const SizedBox(height: 16),

                        // --- Sign up as Landlord Button ---
                        CustomButton(
                          text: 'Sign up as Landlord',
                          onPressed: () =>
                              _navigateToSignUp(context, 'landlord'),
                          backgroundColor: primaryGreen,
                        ),
                        const SizedBox(height: 32),

                        // --- Sign In Link ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(color: Colors.white70),
                            ),
                            GestureDetector(
                              onTap: () => _navigateToLogin(context),
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
