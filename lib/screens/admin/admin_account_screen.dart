import 'package:flutter/material.dart';
import 'package:odiorent/models/admin_user.dart'; // Import the AdminUser model
import 'package:odiorent/services/auth_service.dart';
import 'package:odiorent/screens/shared/welcome_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odiorent/screens/admin/admin_edit_profile_screen.dart'; // New import
import 'package:odiorent/screens/admin/admin_change_password_screen.dart'; // New import

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  final AuthService _authService = AuthService();
  late Future<AdminUser?> _userProfileFuture; // Changed to AdminUser

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _authService.getAdminUserProfile(); // Use new method
  }

  // Method to refresh the profile data
  void _refreshProfile() {
    setState(() {
      _userProfileFuture = _authService.getAdminUserProfile();
    });
  }

  Future<void> _handleLogout() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed

    if (!confirm) {
      return; // User cancelled
    }

    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Logout failed: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminUser?>( // Changed to AdminUser
      future: _userProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text("User profile not found."));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account Information',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Display Profile Information
              _buildInfoRow('Name', '${user.firstName ?? ''} ${user.middleName != null ? '${user.middleName} ' : ''}${user.lastName ?? ''}'.trim()),
              _buildInfoRow('Username', user.userName ?? 'N/A'),
              _buildInfoRow('Email', user.email),
              _buildInfoRow('Phone Number', user.phoneNumber ?? 'N/A'), // Display phone number
              _buildInfoRow('Role', user.role),
              const SizedBox(height: 30),

              // Edit Profile Button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  onPressed: () async {
                    final bool? didUpdate = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AdminEditProfileScreen(adminUser: user),
                      ),
                    );
                    if (didUpdate == true) {
                      _refreshProfile(); // Refresh profile after edit
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50), // primaryGreen
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Change Password Button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text('Change Password'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminChangePasswordScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50), // primaryGreen
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Logout Button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Use red for logout
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
