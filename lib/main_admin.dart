import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:odiorent/screens/shared/login_screen.dart';
import 'package:odiorent/screens/admin/admin_dashboard_screen.dart';
import 'package:odiorent/screens/renter/renter_home_screen.dart';
import 'package:odiorent/screens/landlord/landlord_home_screen.dart';

Future<void> main() async {
  // This line is required to ensure Flutter is initialized
  // before you call Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  // Check if already initialized to prevent duplicate app error
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized (happens during hot reload)
    debugPrint('Firebase already initialized: $e');
  }

  runApp(const AdminWebApp());
}

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OdioRent Admin Panel',

      // Start directly with the LoginScreen
      home: const LoginScreen(),

      // Define named routes for navigation after login
      routes: {
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        // We can add other routes here if needed, but for now,
        // we'll redirect non-admins away. The login screen handles this.
        '/renter-home': (context) => const RenterHomeScreen(),
        '/landlord-home': (context) => const LandlordHomeScreen(),
      },
    );
  }
}
