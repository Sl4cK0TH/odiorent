import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odiorent/widgets/custom_button.dart';
import 'package:odiorent/widgets/login_form_card.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Brand colors (Green Palette)
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF388E3C);

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _usernameEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load saved credentials from simple storage
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _usernameEmailController.text = prefs.getString('saved_email') ?? '';
      }
    });
  }

  // Handles the login logic
  Future<void> _handleLogin() async {
    // Check if form is valid
    if (!_formKey.currentState!.validate()) return;

    // Show loading spinner
    setState(() => _isLoading = true);

    try {
      // Call FirebaseAuthService
      final authService = FirebaseAuthService();
      final input = _usernameEmailController.text.trim();

      // Determine if input is email or username
      // Simple check: if it contains '@', treat it as email
      String? emailToUse;

      if (input.contains('@')) {
        // Input is an email
        debugPrint("=== EMAIL LOGIN DETECTED ===");
        debugPrint("Email provided: $input");
        emailToUse = input;
      } else {
        // Input is a username, fetch the email from database
        debugPrint("=== USERNAME LOGIN DETECTED ===");
        debugPrint("Username provided: $input");

        emailToUse = await authService.getEmailByUsername(input);

        if (emailToUse == null || emailToUse.isEmpty) {
          throw Exception(
            'Username "$input" not found or has no email in database. '
            'Please check the console logs for details, or use your email address to login.',
          );
        }
        debugPrint("Found email for username: $emailToUse");
      }

      // Now sign in with the email
      debugPrint("=== ATTEMPTING SIGN IN ===");
      debugPrint("Email to use: $emailToUse");
      debugPrint(
        "Password length: ${_passwordController.text.length} characters",
      );
      await authService.signIn(
        email: emailToUse,
        password: _passwordController.text,
      );

      // Handle Remember Me
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', input); // Save the raw input (email or username)
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_email');
      }

      debugPrint("✅ Sign in successful!");

      if (!mounted) return;

      // Get the user's role to determine where to navigate
      final user = authService.getCurrentUser();
      if (user == null) {
        throw Exception('User is null after successful login');
      }

      debugPrint("Getting user role for ID: ${user.uid}");
      final role = await authService.getRole(user.uid);
      debugPrint("User role: $role");

      if (!mounted) return;

      // Show success message
      Fluttertoast.showToast(
        msg: "Login successful!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black.withAlpha(179),
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Navigate to appropriate screen based on user role
      if (role == 'admin') {
        // Navigate to Admin Dashboard
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      } else if (role == 'landlord') {
        // Navigate to Landlord Home
        Navigator.of(context).pushReplacementNamed('/landlord-home');
      } else if (role == 'renter') {
        // Navigate to Renter Home
        Navigator.of(context).pushReplacementNamed('/renter-home');
      } else {
        // Unknown role, show error
        throw Exception('Unknown user role: $role');
      }
    } catch (e) {
      if (!mounted) return;
      // Show error message
      debugPrint("❌ LOGIN ERROR ===");
      debugPrint("Error type: ${e.runtimeType}");
      debugPrint("Error message: $e");

      // Extract more user-friendly error message
      String errorMessage = e.toString();

      // Check for common Supabase auth errors
      if (errorMessage.contains('Invalid login credentials')) {
        errorMessage =
            'Invalid email or password. Please check your credentials and try again.';
      } else if (errorMessage.contains('Email not confirmed')) {
        errorMessage = 'Please verify your email address before logging in.';
      } else if (errorMessage.contains('User not found')) {
        errorMessage = 'No account found with this email address.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      // Hide loading spinner
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Handle forgot password
  void _handleForgotPassword() {
    final emailController = TextEditingController();
    // Pre-fill if email is already entered
    if (_usernameEmailController.text.contains('@')) {
      emailController.text = _usernameEmailController.text;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address to receive a password reset link.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                Fluttertoast.showToast(msg: "Please enter a valid email");
                return;
              }

              try {
                // Show loading indicator on button or dialog? 
                // Simple approach: Close dialog and show loading snackbar
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sending reset email...')),
                );

                await FirebaseAuthService().sendPasswordResetEmail(email);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent! Check your inbox.'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Close dialog
                Navigator.of(context).pop();
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lightGreen, darkGreen],
              ),
            ),
          ),

          // Top Content (Logo and Title)
          SafeArea(
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 4),
                // Welcome back text
                const Text(
                  'Welcome Back to',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Logo
                Image.asset('assets/images/logo.png', width: 300),
              ],
            ),
          ),

          // Form Card positioned at bottom
          LoginFormCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Username/Email Field
                      _buildTextField(
                        controller: _usernameEmailController,
                        labelText: 'Username or Email',
                        prefixIcon: Icons.person,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username or email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        prefixIcon: Icons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Remember Me & Forgot Password Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remember Me Checkbox
                          InkWell(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: primaryGreen,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Remember Me',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Forgot Password Link
                          GestureDetector(
                            onTap: _handleForgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sign In Button
                      _isLoading
                          ? const CircularProgressIndicator(color: primaryGreen)
                          : CustomButton(
                              text: 'Sign In',
                              onPressed: _handleLogin,
                              backgroundColor: primaryGreen,
                            ),
                      const SizedBox(height: 10),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.black54),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: primaryGreen,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(prefixIcon, color: Colors.black54),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}
