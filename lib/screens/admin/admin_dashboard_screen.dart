import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odiorent/services/database_service.dart'; // Re-import DatabaseService
// Removed: import 'package:odiorent/screens/shared/welcome_screen.dart'; // For sign out (no longer directly used here)
import 'package:odiorent/widgets/admin-widgets/statistic_card.dart'; // Import StatisticCard
import 'package:odiorent/screens/admin/admin_property_list_screen.dart'; // Import AdminPropertyListScreen
import 'package:odiorent/screens/admin/admin_account_screen.dart'; // Import AdminAccountScreen

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // --- Brand Colors (Green Palette) ---
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

  // Services
  final DatabaseService _dbService = DatabaseService();
  // Removed: final AuthService _authService = AuthService(); // No longer directly used here

  // A Future to hold the list of pending properties
  // Removed: late Future<List<Property>> _pendingPropertiesFuture;
  DateTime? lastPressed; // For double-tap to exit

  int _selectedIndex = 0; // To manage the selected tab
  String? _selectedPropertyStatusFilter; // New: To store status from clicked card

  // List of widgets to display for each tab
  List<Widget> get _widgetOptions => <Widget>[
        // 0. Dashboard Tab
        _buildDashboardScreen(),

        // 1. Properties Tab
        AdminPropertyListScreen(
          status: _selectedPropertyStatusFilter ?? 'overall', // Pass filter
          title: 'Properties',
        ),

        // 2. Account Tab
        const AdminAccountScreen(), // Use the new AdminAccountScreen
      ];

  // New: Function to handle statistic card tap and navigate to properties tab
  void _handleStatisticCardTap(String status) {
    setState(() {
      _selectedPropertyStatusFilter = status;
      _selectedIndex = 1; // Navigate to Properties tab
    });
  }

  // Handles tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // If navigating to properties tab, clear the filter
      if (index == 1) {
        _selectedPropertyStatusFilter = null;
        // Removed: _refreshPendingList(); // Refresh the list if it's the properties tab
      }
    });
  }

  // Removed: Function to refresh the list
  // Removed: void _refreshPendingList() {
  // Removed:   setState(() {
  // Removed:     _pendingPropertiesFuture = _dbService.getPropertiesByStatusWithLandlordDetails('pending'); // Use new method
  // Removed:   });
  // Removed: }

  // New: Widget for the Dashboard tab content
  Widget _buildDashboardScreen() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryGreen));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Dashboard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, // Two cards per row
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  StatisticCard(
                    title: 'Overall Requests',
                    count: stats['overall']!,
                    icon: Icons.all_inclusive,
                    color: Colors.blue,
                    onTap: () => _handleStatisticCardTap('overall'),
                  ),
                  StatisticCard(
                    title: 'Pending Requests',
                    count: stats['pending']!,
                    icon: Icons.hourglass_empty,
                    color: Colors.orange,
                    onTap: () => _handleStatisticCardTap('pending'),
                  ),
                  StatisticCard(
                    title: 'Approved Requests',
                    count: stats['approved']!,
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onTap: () => _handleStatisticCardTap('approved'),
                  ),
                  StatisticCard(
                    title: 'Rejected Requests',
                    count: stats['rejected']!,
                    icon: Icons.cancel,
                    color: Colors.red,
                    onTap: () => _handleStatisticCardTap('rejected'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // New: Function to fetch all dashboard statistics
  Future<Map<String, int>> _fetchDashboardStats() async {
    final overall = await _dbService.getPropertiesCount();
    final pending = await _dbService.getPropertiesCountByStatus('pending');
    final approved = await _dbService.getPropertiesCountByStatus('approved');
    final rejected = await _dbService.getPropertiesCountByStatus('rejected');

    return {
      'overall': overall,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }

  @override
  void initState() {
    super.initState();
    // Removed: _widgetOptions = <Widget>[ ... ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          return;
        }
        final now = DateTime.now();
        const maxDuration = Duration(seconds: 2);
        final isWarning =
            lastPressed == null || now.difference(lastPressed!) > maxDuration;

        if (isWarning) {
          lastPressed = DateTime.now();
          Fluttertoast.showToast(
            msg: "Press back again to exit",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black.withAlpha(179),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard', // Changed title
            style: TextStyle(fontWeight: FontWeight.bold), // Made bold
          ),
          backgroundColor: lightGreen,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            // Keep Notifications icon
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                Fluttertoast.showToast(msg: "Notifications screen coming soon!");
              },
            ),
          ],
        ),
        body: _widgetOptions.elementAt(_selectedIndex), // Display selected tab content
        bottomNavigationBar: SizedBox(
          height: 54.0, // Set fixed height
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: '', // No label
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: '', // No label
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: '', // No label
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: primaryGreen,
            unselectedItemColor: Colors.black, // Changed to black for visibility
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed, // Ensures all items are visible
            showSelectedLabels: false, // No labels
            showUnselectedLabels: false, // No labels
            enableFeedback: false, // No splash effect
            iconSize: 28.0, // Set icon size
            selectedFontSize: 0.0, // Crucial for fixing overflow with hidden labels
            unselectedFontSize: 0.0, // Crucial for fixing overflow with hidden labels
          ),
        ),
      ),
    );
  }
}