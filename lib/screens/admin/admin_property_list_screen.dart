import 'package:flutter/material.dart';
import 'package:odiorent/widgets/admin-widgets/overall_properties_list.dart';
import 'package:odiorent/widgets/admin-widgets/pending_properties_list.dart';
import 'package:odiorent/widgets/admin-widgets/approved_properties_list.dart';
import 'package:odiorent/widgets/admin-widgets/rejected_properties_list.dart';

class AdminPropertyListScreen extends StatefulWidget {
  final String status; // e.g., 'overall', 'pending', 'approved', 'rejected'
  final String title; // Title for the AppBar

  const AdminPropertyListScreen({
    super.key,
    required this.status,
    required this.title,
  });

  @override
  State<AdminPropertyListScreen> createState() => _AdminPropertyListScreenState();
}

class _AdminPropertyListScreenState extends State<AdminPropertyListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Set initial tab based on the status passed from the dashboard card
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int initialIndex = 0;
      switch (widget.status) {
        case 'overall':
          initialIndex = 0;
          break;
        case 'pending':
          initialIndex = 1;
          break;
        case 'approved':
          initialIndex = 2;
          break;
        case 'rejected':
          initialIndex = 3;
          break;
      }
      _tabController.animateTo(initialIndex);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF66BB6A), // lightGreen
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overall'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OverallPropertiesList(),
          PendingPropertiesList(),
          ApprovedPropertiesList(),
          RejectedPropertiesList(),
        ],
      ),
    );
  }
}
