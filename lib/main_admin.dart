import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:odiorent/screens/shared/login_screen.dart';
import 'package:odiorent/screens/admin/admin_dashboard_screen.dart';
import 'package:odiorent/screens/renter/renter_home_screen.dart';
import 'package:odiorent/screens/landlord/landlord_home_screen.dart';

Future<void> main() async {
  // This line is required to ensure Flutter is initialized
  // before you call Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (same as in main.dart)
  await Supabase.initialize(
    url: 'https://oxxjpcjusuemhdjpyssy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94eGpwY2p1c3VlbWhkanB5c3N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1NTE2NTcsImV4cCI6MjA3NzEyNzY1N30.46FVUi8lYv3UGR4vC6gc3W1tAMm3Jv7DGmPVV21jPGQ',
  );

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
