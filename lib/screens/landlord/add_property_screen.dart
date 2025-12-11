import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart'; // Import the package
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/services/cloudinary_service.dart';
import 'package:odiorent/widgets/custom_button.dart';
import 'package:path/path.dart' as p; // Import path package with prefix

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
  final _streetAddressController = TextEditingController();
  final List<String> _barangays = [
    "Amatong", "Bangon", "Batiano", "Budiong", "Canduyong", "Dapawan",
    "Gabas", "Gabawan", "Libertad", "Ligaya", "Liwanag", "Liwayway",
    "Progreso Este", "Progreso Weste", "Poctoy", "Panique", "Pato-o",
    "Rizal", "Tabing Dagat", "Tabobo-an", "Tumingad", "Tulay", "Tuburan",
    "Anahao", "Bangcogon"
  ];
  String? _selectedBarangay;
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController();
  final _bedsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Services
  final _dbService = FirebaseDatabaseService();
  final _storageService = CloudinaryService();
  final _authService = FirebaseAuthService();

  // State variables
  bool _isLoading = false;
  final List<File> _selectedImages = []; // To hold the image files
  final ImagePicker _picker = ImagePicker(); // The image picker instance

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _streetAddressController.dispose();
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
      Fluttertoast.showToast(
        msg: "Please upload at least one image.",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? userId = _authService.getCurrentUser()?.uid;
      if (userId == null) {
        throw Exception("User not logged in.");
      }

      // 1. Upload Images concurrently
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploadTasks = _selectedImages.asMap().entries.map((entry) async {
        final imageFile = entry.value;
        final bytes = await imageFile.readAsBytes();
        final extension = p.extension(imageFile.path).isEmpty
            ? '.jpg'
            : p.extension(imageFile.path);
        final fileName = 'property_${userId}_${timestamp}_${entry.key}$extension';

        return _storageService.uploadFile(
          folder: 'properties',
          bytes: bytes,
          fileName: fileName,
          userId: userId,
        );
      }).toList();
      final imageUrls = await Future.wait(uploadTasks);

      // 2. Create Property Object
      final fullAddress = "${_streetAddressController.text.trim()}, $_selectedBarangay, Odiongan, Romblon";
      final newProperty = Property(
        landlordId: userId,
        name: _nameController.text.trim(),
        address: fullAddress,
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        rooms: int.parse(_roomsController.text.trim()),
        beds: int.parse(_bedsController.text.trim()),
        imageUrls: imageUrls,
        status: PropertyStatus.pending, // Always 'pending' on creation
        createdAt: DateTime.now().toUtc(), // Set creation date
      );

      // 3. Save to Database
      await _dbService.createProperty(newProperty);

      if (!mounted) return;

      Fluttertoast.showToast(
        msg: "Property submitted for review!",
        backgroundColor: Colors.green,
      );

      // 4. Go back to home screen
      // Pass 'true' back to tell the home screen to refresh
      Navigator.of(context).pop(true);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error creating property: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Barangay", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBarangay,
                          hint: const Text("Select Barangay"),
                          items: _barangays.map((String barangay) {
                            return DropdownMenuItem<String>(
                              value: barangay,
                              child: Text(barangay),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedBarangay = newValue;
                            });
                          },
                          validator: (value) => value == null ? "Please select a barangay" : null,
                          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Street / House No.", style: Theme.of(context).textTheme.titleMedium),
                        TextFormField(
                          controller: _streetAddressController,
                          decoration: const InputDecoration(
                            hintText: "e.g., 123 Main St, Zone 1",
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter the street address";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
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
                    validator: (value) => _validateNumber(
                      value,
                      allowDecimal: true,
                      emptyMessage: 'Price is required',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _roomsController,
                    labelText: 'Rooms',
                    prefixIcon: Icons.meeting_room,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNumber(
                      value,
                      emptyMessage: 'Number of rooms is required',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bedsController,
                    labelText: 'Beds',
                    prefixIcon: Icons.bed,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNumber(
                      value,
                      emptyMessage: 'Number of beds is required',
                    ),
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

  String? _validateNumber(
    String? value, {
    bool allowDecimal = false,
    required String emptyMessage,
  }) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage;
    }
    final sanitizedValue = value.trim();
    if (allowDecimal) {
      final parsed = double.tryParse(sanitizedValue);
      if (parsed == null || parsed <= 0) {
        return 'Enter a valid amount';
      }
    } else {
      final parsed = int.tryParse(sanitizedValue);
      if (parsed == null || parsed <= 0) {
        return 'Enter a whole number';
      }
    }
    return null;
  }
}
