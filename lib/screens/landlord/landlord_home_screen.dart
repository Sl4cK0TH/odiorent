import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/auth_service.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:odiorent/screens/landlord/add_property_screen.dart';
import 'package:odiorent/screens/shared/welcome_screen.dart';
import 'package:odiorent/widgets/property_card.dart';
import 'package:odiorent/screens/landlord/landlord_edit_profile_screen.dart';
import 'package:odiorent/screens/landlord/landlord_change_password_screen.dart';
import 'package:odiorent/screens/shared/notifications_screen.dart';
import 'package:odiorent/models/admin_user.dart'; // New import for AdminUser
import 'package:odiorent/screens/landlord/landlord_edit_property_screen.dart'; // Explicitly re-add this import
import 'package:odiorent/screens/landlord/landlord_property_details_screen.dart';

class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  Future<List<Property>> _propertiesFuture = Future.value(<Property>[]);
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // For search auto-focus
  bool _isSearching = false;

  String _userName = 'Landlord';
  String? _userProfileImage;
  AdminUser? _adminUser; // New state variable to hold AdminUser profile
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

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final adminUser = await _authService.getAdminUserProfile();
      if (mounted) {
        setState(() {
          _adminUser = adminUser;
          _userName = adminUser?.userName ?? user.email?.split('@')[0] ?? 'Landlord';
          _userProfileImage = adminUser?.profilePictureUrl != null
              ? '${adminUser!.profilePictureUrl}?t=${DateTime.now().millisecondsSinceEpoch}'
              : null;
        });
      }
    }
  }

  Future<void> _refreshProperties() async {
    final String? userId = _authService.getCurrentUser()?.id;
    final future = userId != null
        ? _dbService.getLandlordProperties(userId)
        : Future.value(<Property>[]);

    if (mounted) {
      setState(() {
        _propertiesFuture = future;
      });
    } else {
      _propertiesFuture = future;
    }

    await future;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index && index == 0) {
      // If already on Home tab and Home is tapped again, refresh properties
      _refreshProperties();
    }
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        _isSearching = false;
        _searchController.clear();
        _filteredProperties = _allProperties;
        _searchFocusNode.unfocus(); // Unfocus when leaving search tab
      } else {
        // Request focus when search tab is selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _searchProperties(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredProperties = _allProperties;
      } else {
        _filteredProperties = _allProperties.where((property) {
          final nameLower = property.name.toLowerCase();
          final addressLower = property.address.toLowerCase();
          final searchLower = query.toLowerCase();
          return nameLower.contains(searchLower) ||
              addressLower.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddProperty() async {
    final bool? propertyCreated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
    );

    if (propertyCreated == true) {
      await _refreshProperties();
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    if (result == true) {
      await _refreshProperties();
    }
  }

  Future<void> _openPropertyDetails(Property property) async {
    final bool? didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LandlordPropertyDetailsScreen(property: property),
      ),
    );

    if (didChange == true) {
      await _refreshProperties();
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
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(), // 0
            _buildSearchTab(), // 1
            _buildEditTab(), // 2
            _buildNotificationsTab(), // 3
            _buildAccountTab(), // 4
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToAddProperty,
          backgroundColor: primaryGreen,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _refreshProperties,
      color: primaryGreen,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            // No expanded height, just a regular app bar
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
                onPressed: () => _onItemTapped(3), // Index 3 is Notifications
              ),
              IconButton(
                icon: const Icon(Icons.message_outlined, color: Colors.white),
                onPressed: () {
                  Fluttertoast.showToast(msg: "Messages screen coming soon!");
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'My Properties',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),
          FutureBuilder<List<Property>>(
            future: _propertiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text("Error: ${snapshot.error}")),
                );
              }
              final properties = snapshot.data;
              if (properties == null || properties.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_work_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "You haven't added any properties yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tap the '+' button below to get started!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              _allProperties = properties;
              if (_isSearching) {
                _searchProperties(_searchController.text);
              } else {
                _filteredProperties = properties;
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final property = properties[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: GestureDetector(
                      onTap: () => _openPropertyDetails(property),
                      child: PropertyCard(property: property),
                    ),
                  );
                }, childCount: properties.length),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return SafeArea(
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                onChanged: _searchProperties,
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
                              ? 'Start searching for your properties'
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
                        onTap: () => _openPropertyDetails(property),
                        child: PropertyCard(property: property),
                      ),
                    );
                  }, childCount: _filteredProperties.length),
                ),
        ],
      ),
    );
  }

  Widget _buildEditTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: true,
          backgroundColor: lightGreen,
          title: const Text('My Properties'),
          foregroundColor: Colors.white,
        ),
        FutureBuilder<List<Property>>(
          future: _propertiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                ),
              );
            }
            if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(child: Text("Error: ${snapshot.error}")),
              );
            }
            final properties = snapshot.data;
            if (properties == null || properties.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "You haven't added any properties yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Tap the '+' button below to get started!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
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
                      _navigateAndRefresh(
                        LandlordEditPropertyScreen(property: property),
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

  Widget _buildNotificationsTab() {
    return const NotificationsScreen();
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(77),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomAppBar(
        height: 54,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, index: 0),
            _buildNavItem(icon: Icons.search, activeIcon: Icons.search, index: 1),
            const SizedBox(width: 40), // The gap for the FAB
            _buildNavItem(icon: Icons.edit_outlined, activeIcon: Icons.edit, index: 2),
            _buildNavItem(icon: Icons.person_outline, activeIcon: Icons.person, index: 4),
          ],
        ),
      ),
    );
  }

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
              GestureDetector(
                onTap: () async {
                  if (_adminUser != null) {
                    final bool? didUpdate = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LandlordEditProfileScreen(appUser: _adminUser!),
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
                _authService.getCurrentUser()?.email ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () async {
                  if (_adminUser != null) {
                    final bool? didUpdate = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LandlordEditProfileScreen(appUser: _adminUser!),
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
                onTap: () => _navigateAndRefresh(const LandlordChangePasswordScreen()),
              ),
              _buildSettingsTile(
                icon: Icons.business_outlined,
                title: 'My Properties',
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _buildSettingsTile(
                icon: Icons.analytics_outlined,
                title: 'Property Analytics',
                onTap: () => _showComingSoonDialog('Property Analytics'),
              ),
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => _showComingSoonDialog('Help & Support'),
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
