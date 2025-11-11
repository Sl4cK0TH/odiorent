import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/auth_service.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:odiorent/screens/landlord/add_property_screen.dart';
import 'package:odiorent/screens/shared/welcome_screen.dart';
import 'package:odiorent/widgets/property_card.dart';

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

  late Future<List<Property>> _propertiesFuture;
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  String _userName = 'Landlord';
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
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userName = user.email?.split('@')[0] ?? 'Landlord';
      });
    }
  }

  void _refreshProperties() {
    final String? userId = _authService.getCurrentUser()?.id;
    if (userId != null) {
      setState(() {
        _propertiesFuture = _dbService.getLandlordProperties(userId);
      });
    } else {
      _propertiesFuture = Future.value([]);
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _navigateToAddProperty();
    } else {
      setState(() {
        _selectedIndex = index;
        if (index != 1) {
          _isSearching = false;
          _searchController.clear();
        }
      });
    }
  }

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

  Future<void> _navigateToAddProperty() async {
    final bool? propertyCreated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
    );

    if (propertyCreated == true) {
      _refreshProperties();
      setState(() {
        _selectedIndex = 0;
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
        final now = DateTime.now();
        const maxDuration = Duration(seconds: 2);
        final isWarning =
            lastPressed == null || now.difference(lastPressed!) > maxDuration;

        if (isWarning) {
          lastPressed = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: maxDuration,
            ),
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
            _buildHomeTab(),
            _buildSearchTab(),
            Container(),
            _buildNotificationsTab(),
            _buildAccountTab(),
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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
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
                      GestureDetector(
                        onTap: () => _onItemTapped(4),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Welcome back,',
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
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: _handleLogout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
            if (_filteredProperties.isEmpty && !_isSearching) {
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
                  child: PropertyCard(property: property),
                );
              }, childCount: properties.length),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
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
                    child: PropertyCard(property: property),
                  );
                }, childCount: _filteredProperties.length),
              ),
      ],
    );
  }

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
                  'You\'ll see updates about your properties here',
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
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _onItemTapped(0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                        color: _selectedIndex == 0
                            ? primaryGreen
                            : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedIndex == 0
                              ? primaryGreen
                              : Colors.grey[600],
                          fontWeight: _selectedIndex == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _onItemTapped(1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        color: _selectedIndex == 1
                            ? primaryGreen
                            : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedIndex == 1
                              ? primaryGreen
                              : Colors.grey[600],
                          fontWeight: _selectedIndex == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: InkWell(
                  onTap: () => _onItemTapped(3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedIndex == 3
                            ? Icons.notifications
                            : Icons.notifications_outlined,
                        color: _selectedIndex == 3
                            ? primaryGreen
                            : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedIndex == 3
                              ? primaryGreen
                              : Colors.grey[600],
                          fontWeight: _selectedIndex == 3
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _onItemTapped(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedIndex == 4
                            ? Icons.person
                            : Icons.person_outline,
                        color: _selectedIndex == 4
                            ? primaryGreen
                            : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedIndex == 4
                              ? primaryGreen
                              : Colors.grey[600],
                          fontWeight: _selectedIndex == 4
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
                onTap: _showProfileDialog,
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () => _showComingSoonDialog('Change Password'),
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
