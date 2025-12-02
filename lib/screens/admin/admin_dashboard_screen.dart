import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:odiorent/widgets/admin-widgets/statistic_card.dart';
import 'package:odiorent/screens/admin/admin_property_list_screen.dart';
import 'package:odiorent/screens/admin/admin_account_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

  final DatabaseService _dbService = DatabaseService();
  DateTime? lastPressed;

  int _selectedIndex = 0;
  String? _selectedPropertyStatusFilter;

  List<Widget> get _widgetOptions => <Widget>[
        _buildDashboardScreen(),
        AdminPropertyListScreen(
          status: _selectedPropertyStatusFilter ?? 'overall',
          title: 'Properties',
        ),
        const AdminAccountScreen(),
      ];

  void _handleStatisticCardTap(String status) {
    setState(() {
      _selectedPropertyStatusFilter = status;
      _selectedIndex = 1;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _selectedPropertyStatusFilter = null;
      }
    });
  }

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
                crossAxisCount: 2,
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

  Future<Map<String, int>> _fetchDashboardStats() async {
    final overall = await _dbService.getPropertiesCount();
    final pending = await _dbService.getPropertiesCountByStatus(PropertyStatus.pending);
    final approved = await _dbService.getPropertiesCountByStatus(PropertyStatus.approved);
    final rejected = await _dbService.getPropertiesCountByStatus(PropertyStatus.rejected);

    return {
      'overall': overall,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
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
          Fluttertoast.showToast(msg: "Press back again to exit");
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: lightGreen,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                Fluttertoast.showToast(msg: "Notifications screen coming soon!");
              },
            ),
          ],
        ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Properties'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryGreen,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
