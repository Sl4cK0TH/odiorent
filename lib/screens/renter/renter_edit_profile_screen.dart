import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odiorent/models/admin_user.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/services/cloudinary_service.dart';
import 'package:path/path.dart' as p; // Import path package with prefix

class RenterEditProfileScreen extends StatefulWidget {
  final AdminUser appUser; // Accept AdminUser in constructor

  const RenterEditProfileScreen({super.key, required this.appUser});

  @override
  State<RenterEditProfileScreen> createState() =>
      _RenterEditProfileScreenState();
}

class _RenterEditProfileScreenState extends State<RenterEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  final CloudinaryService _storageService = CloudinaryService();

  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _userNameController;

  AdminUser? _currentUserProfile; // This will now be initialized from widget.appUser
  bool _isLoading = false;
  String? _profilePictureUrl;
  Uint8List? _newProfileImageBytes; // To hold selected image bytes

  @override
  void initState() {
    super.initState();
    _currentUserProfile = widget.appUser; // Initialize from constructor
    _firstNameController = TextEditingController(text: widget.appUser.firstName ?? '');
    _middleNameController = TextEditingController(text: widget.appUser.middleName ?? '');
    _lastNameController = TextEditingController(text: widget.appUser.lastName ?? '');
    _phoneNumberController = TextEditingController(text: widget.appUser.phoneNumber ?? '');
    _userNameController = TextEditingController(text: widget.appUser.userName ?? '');
    _profilePictureUrl = widget.appUser.profilePictureUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _newProfileImageBytes = bytes;
      });
    }
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? finalProfilePictureUrl = _profilePictureUrl;

    try {
      if (_newProfileImageBytes != null) {
        final userId = _authService.getCurrentUser()!.uid;
        final fileName = 'profile_$userId${p.extension(_currentUserProfile?.profilePictureUrl ?? '.png')}'; // Use path.extension
        finalProfilePictureUrl = await _storageService.uploadFile(
          folder: 'profile_pictures',
          bytes: _newProfileImageBytes!,
          fileName: fileName,
          userId: userId,
        );
      }

      await _dbService.updateUserProfile(
        userId: _currentUserProfile!.id,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        userName: _userNameController.text.trim(),
        profilePictureUrl: finalProfilePictureUrl,
      );

      Fluttertoast.showToast(
        msg: "Profile updated successfully!",
        backgroundColor: Colors.green,
      );
      if (mounted) {
        Navigator.of(context).pop(true); // Signal that profile was updated
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating profile: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF66BB6A), // lightGreen
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _currentUserProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _newProfileImageBytes != null
                              ? MemoryImage(_newProfileImageBytes!)
                              : (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                                  ? NetworkImage(_profilePictureUrl!)
                                  : null) as ImageProvider?,
                          child: _newProfileImageBytes == null &&
                                  (_profilePictureUrl == null || _profilePictureUrl!.isEmpty)
                              ? Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey[600],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        }),
                    _buildTextField(
                        controller: _middleNameController,
                        label: 'Middle Name (Optional)'),
                    _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        }),
                    _buildTextField(
                        controller: _userNameController,
                        label: 'Username (Optional)'),
                    _buildTextField(
                        controller: _phoneNumberController,
                        label: 'Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50), // primaryGreen
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
