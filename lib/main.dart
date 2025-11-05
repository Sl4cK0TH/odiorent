import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:odiorent/screens/splash_screen.dart';
import 'package:odiorent/screens/renter/renter_home_screen.dart';
import 'package:odiorent/screens/landlord/landlord_home_screen.dart';
import 'package:odiorent/screens/admin/admin_dashboard_screen.dart';

Future<void> main() async {
  // This line is required to ensure Flutter is initialized
  // before you call Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://oxxjpcjusuemhdjpyssy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94eGpwY2p1c3VlbWhkanB5c3N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1NTE2NTcsImV4cCI6MjA3NzEyNzY1N30.46FVUi8lYv3UGR4vC6gc3W1tAMm3Jv7DGmPVV21jPGQ',
  );

  runApp(const MyApp());
}

// You can create a global variable to access the Supabase client
// from anywhere in your app
final supabase = Supabase.instance.client;

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
