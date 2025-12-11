import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:odiorent/screens/splash_screen.dart';
import 'package:odiorent/screens/renter/renter_home_screen.dart';
import 'package:odiorent/screens/landlord/landlord_home_screen.dart';
import 'package:odiorent/screens/admin/admin_dashboard_screen.dart';

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OdioRent',

      // Set the SplashScreen as the starting screen
      home: const SplashScreen(),

      // Define named routes for navigation
      routes: {
        '/renter-home': (context) => const RenterHomeScreen(),
        '/landlord-home': (context) => const LandlordHomeScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
