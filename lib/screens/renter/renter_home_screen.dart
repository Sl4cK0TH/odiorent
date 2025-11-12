import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/auth_service.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:odiorent/screens/shared/welcome_screen.dart';
import 'package:odiorent/widgets/property_card.dart';
import 'package:odiorent/screens/renter/property_details_screen.dart';
import 'package:odiorent/screens/renter/renter_edit_profile_screen.dart'; // New import
import 'package:odiorent/screens/admin/admin_change_password_screen.dart'; // Reusing AdminChangePasswordScreen
import 'package:odiorent/models/user.dart'; // New import for AppUser

class RenterHomeScreen extends StatefulWidget {
  const RenterHomeScreen({super.key});

  @override
  State<RenterHomeScreen> createState() => _RenterHomeScreenState();
}

class _RenterHomeScreenState extends State<RenterHomeScreen> {
  // --- Define Brand Colors (Green Palette) ---
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

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
  final FocusNode _searchFocusNode = FocusNode(); // For search auto-focus
  bool _isSearching = false;

  // User data
  AppUser? _appUser; // New: To hold the full AppUser profile
  String _userName = 'Renter';
  String? _userProfileImage;
  DateTime? lastPressed; // For double-tap to exit

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _refreshProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  // Load user data
  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final appUser = await _authService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _appUser = appUser;
          String resolvedUserName = 'Renter'; // Default if _appUser is null
          if (_appUser != null) {
            final nonNullAppUser = _appUser!; // Explicitly assert non-null
            resolvedUserName = nonNullAppUser.userName;
          }
          _userName = resolvedUserName;
          _userProfileImage = _appUser?.profilePictureUrl;
        });
      }
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
        _searchFocusNode.unfocus(); // Unfocus when leaving search tab
      } else {
        // Request focus when search tab is selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          return;
        }
        // If the user is not on the Home tab, navigate to it.
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }
        // If on the Home tab, proceed with double-tap-to-exit logic.
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
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(),
            _buildSearchTab(),
            _buildNotificationsTab(), // This is now a placeholder tab
            _buildAccountTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // Home Tab - Property List
  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        // Custom App Bar with User Profile
        SliverAppBar(
          automaticallyImplyLeading: false,
          expandedHeight: 80,
          floating: false,
          pinned: true,
          backgroundColor: lightGreen,
          title: const Text(
            'OdioRent',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () => _onItemTapped(2), // Index 2 is Notifications
            ),
            IconButton(
              icon: const Icon(Icons.message_outlined, color: Colors.white),
              onPressed: () {
                // TODO: Navigate to a messages/chat list screen
                Fluttertoast.showToast(msg: "Messages screen coming soon!");
              },
            ),
          ],
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
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                focusNode: _searchFocusNode,
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
      ),
    );
  }

  // Notifications Tab
  Widget _buildNotificationsTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
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
          automaticallyImplyLeading: false,
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
                onTap: () async {
                  if (_appUser != null) {
                    final bool? didUpdate = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RenterEditProfileScreen(appUser: _appUser!),
                      ),
                    );
                    if (didUpdate == true) {
                      _loadUserData(); // Refresh profile after edit
                    }
                  } else {
                    Fluttertoast.showToast(msg: "User data not loaded yet.");
                  }
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: primaryGreen, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
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
                _appUser?.email ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // Settings List
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () async {
                  if (_appUser != null) {
                    final bool? didUpdate = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RenterEditProfileScreen(appUser: _appUser!),
                      ),
                    );
                    if (didUpdate == true) {
                      _loadUserData(); // Refresh profile after edit
                    }
                  } else {
                    Fluttertoast.showToast(msg: "User data not loaded yet.");
                  }
                },
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminChangePasswordScreen(), // Reusing AdminChangePasswordScreen
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.favorite_border,
                title: 'Favorites',
                onTap: () {
                  // TODO: Implement favorites
                  Fluttertoast.showToast(msg: "Favorites feature coming soon!");
                },
              ),
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  // TODO: Implement help
                  Fluttertoast.showToast(msg: "Help & Support feature coming soon!");
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
    return BottomAppBar(
      height: 54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.search,
            activeIcon: Icons.search,
            index: 1,
          ),
          // Disabled placeholder for 'Edit'
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: Colors.grey[300],
                  size: 28,
                ),
              ],
            ),
          ),
          _buildNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            index: 3,
          ),
        ],
      ),
    );
  }

  // Helper widget for each navigation item
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryGreen : Colors.grey[600],
              size: 28,
            ),
          ],
        ),
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
