import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import the package
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/auth_service.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:odiorent/services/storage_service.dart';
import 'package:odiorent/widgets/custom_button.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  // --- Define Brand Colors (Green Palette) ---
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

  // Form key and controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController();
  final _bedsController = TextEditingController();

  // Services
  final _dbService = DatabaseService();
  final _storageService = StorageService();
  final _authService = AuthService();

  // State variables
  bool _isLoading = false;
  final List<File> _selectedImages = []; // To hold the image files
  final ImagePicker _picker = ImagePicker(); // The image picker instance

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _bedsController.dispose();
    super.dispose();
  }

  // --- Image Picker Function ---
  Future<void> _pickImages() async {
    // Pick multiple images from the gallery
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        // Add the selected images (as Files) to our list
        _selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
      });
    }
  }

  // --- Create Property Function ---
  Future<void> _handleCreateProperty() async {
    if (!_formKey.currentState!.validate()) return; // Check form
    if (_selectedImages.isEmpty) {
      // Check if at least one image is selected
      _showErrorDialog("Please upload at least one image.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? userId = _authService.getCurrentUser()?.id;
      if (userId == null) {
        throw Exception("User not logged in.");
      }

      // 1. Upload Images
      List<String> imageUrls = [];
      for (File imageFile in _selectedImages) {
        final String url = await _storageService.uploadImage(imageFile, userId);
        imageUrls.add(url);
      }

      // 2. Create Property Object
      final newProperty = Property(
        landlordId: userId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        rooms: int.parse(_roomsController.text.trim()),
        beds: int.parse(_bedsController.text.trim()),
        imageUrls: imageUrls,
        status: 'pending', // Always 'pending' on creation
        createdAt: DateTime.now(), // Set creation date
      );

      // 3. Save to Database
      await _dbService.createProperty(newProperty);

      if (!mounted) return;

      // 4. Go back to home screen
      // Pass 'true' back to tell the home screen to refresh
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Error creating property: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper for error dialogs
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Property'),
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 100.0), // Added bottom padding
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    labelText: 'Property Name (e.g., "Cozy 2-Bedroom Condo")',
                    prefixIcon: Icons.home,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    labelText: 'Address',
                    prefixIcon: Icons.location_on,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    labelText: 'Description',
                    prefixIcon: Icons.description,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _priceController,
                    labelText: 'Price (₱)',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _roomsController,
                    labelText: 'Rooms',
                    prefixIcon: Icons.meeting_room,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bedsController,
                    labelText: 'Beds',
                    prefixIcon: Icons.bed,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // --- Image Upload Section ---
                  const Text(
                    'Property Images',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: primaryGreen),
                    ),
                    onPressed: _pickImages,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select Images'),
                  ),
                  const SizedBox(height: 16),
                  // --- Image Preview Grid ---
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // --- Remove Image Button ---
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 16,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // --- Submit Button (Fixed at bottom) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).scaffoldBackgroundColor, // Match scaffold background
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    )
                  : CustomButton(
                      text: 'Create Property',
                      onPressed: _handleCreateProperty,
                      backgroundColor: primaryGreen,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryGreen, width: 2.0),
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'This field cannot be empty';
            }
            return null;
          },
    );
  }
}
