import 'package:flutter/material.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/auth_service.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:odiorent/screens/shared/welcome_screen.dart';
import 'package:odiorent/widgets/property_card.dart';
import 'package:odiorent/screens/renter/property_details_screen.dart';

class RenterHomeScreen extends StatefulWidget {
  const RenterHomeScreen({super.key});

  @override
  State<RenterHomeScreen> createState() => _RenterHomeScreenState();
}

class _RenterHomeScreenState extends State<RenterHomeScreen> {
  // --- Define Brand Colors (Green Palette) ---
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF388E3C);

  // Navigation state
  int _selectedIndex = 0;

  // Services
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  // A Future to hold the list of approved properties
  late Future<List<Property>> _propertiesFuture;
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // User data
  String _userName = 'Renter';
  String? _userProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _refreshProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load user data
  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userName = user.email?.split('@')[0] ?? 'Renter';
      });
    }
  }

  // Function to refresh the list
  void _refreshProperties() {
    setState(() {
      _propertiesFuture = _dbService.getApprovedProperties();
    });
  }

  // Handle bottom navigation tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        _isSearching = false;
        _searchController.clear();
      }
    });
  }

  // Search properties
  void _searchProperties(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProperties = _allProperties;
      });
    } else {
      setState(() {
        _filteredProperties = _allProperties.where((property) {
          final nameLower = property.name.toLowerCase();
          final addressLower = property.address.toLowerCase();
          final searchLower = query.toLowerCase();
          return nameLower.contains(searchLower) ||
              addressLower.contains(searchLower);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildSearchTab(),
          _buildNotificationsTab(),
          _buildAccountTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Home Tab - Property List
  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        // Custom App Bar with User Profile
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: lightGreen,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [lightGreen, primaryGreen],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: () => _onItemTapped(3),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _userProfileImage != null
                              ? ClipOval(
                                  child: Image.network(
                                    _userProfileImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 35,
                                  color: primaryGreen,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User Name and Welcome Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Hello,',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Section Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available Properties',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),

        // Properties FutureBuilder
        FutureBuilder<List<Property>>(
          future: _propertiesFuture,
          builder: (context, snapshot) {
            // --- Loading State ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                ),
              );
            }

            // --- Error State ---
            if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(child: Text("Error: ${snapshot.error}")),
              );
            }

            // --- Empty State ---
            final properties = snapshot.data;
            if (properties == null || properties.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No properties available right now.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Check back later for new listings!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Update all properties for search
            _allProperties = properties;
            if (_filteredProperties.isEmpty && !_isSearching) {
              _filteredProperties = properties;
            }

            // --- Success State (Show List) ---
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final property = properties[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              PropertyDetailsScreen(property: property),
                        ),
                      );
                    },
                    child: PropertyCard(property: property),
                  ),
                );
              }, childCount: properties.length),
            );
          },
        ),
      ],
    );
  }

  // Search Tab
  Widget _buildSearchTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: lightGreen,
          title: const Text('Search Properties'),
          foregroundColor: Colors.white,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _isSearching = true;
                _searchProperties(value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name or location...',
                prefixIcon: const Icon(Icons.search, color: primaryGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchProperties('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: primaryGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: primaryGreen, width: 2),
                ),
              ),
            ),
          ),
        ),
        _filteredProperties.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Start searching for properties'
                            : 'No properties found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final property = _filteredProperties[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                PropertyDetailsScreen(property: property),
                          ),
                        );
                      },
                      child: PropertyCard(property: property),
                    ),
                  );
                }, childCount: _filteredProperties.length),
              ),
      ],
    );
  }

  // Notifications Tab
  Widget _buildNotificationsTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: lightGreen,
          title: const Text('Notifications'),
          foregroundColor: Colors.white,
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see updates about your inquiries here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Account Settings Tab
  Widget _buildAccountTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: lightGreen,
          title: const Text('Account Settings'),
          foregroundColor: Colors.white,
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Profile Picture
              GestureDetector(
                onTap: _showProfileDialog,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: primaryGreen, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _userProfileImage != null
                      ? ClipOval(
                          child: Image.network(
                            _userProfileImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, size: 60, color: primaryGreen),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _authService.getCurrentUser()?.email ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // Settings List
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: _showProfileDialog,
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // TODO: Implement change password
                  _showComingSoonDialog('Change Password');
                },
              ),
              _buildSettingsTile(
                icon: Icons.favorite_border,
                title: 'Favorites',
                onTap: () {
                  // TODO: Implement favorites
                  _showComingSoonDialog('Favorites');
                },
              ),
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  // TODO: Implement help
                  _showComingSoonDialog('Help & Support');
                },
              ),
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Logout',
                onTap: _handleLogout,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Settings Tile Widget
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : primaryGreen),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }

  // Profile Dialog
  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile picture upload feature coming soon!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This is required for security purposes.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // Coming Soon Dialog
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(feature),
        content: Text('$feature feature coming soon!'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // Logout Handler
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }
}
