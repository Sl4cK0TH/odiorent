import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/models/admin_user.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class LandlordEditPropertyScreen extends StatefulWidget {
  final Property property;

  const LandlordEditPropertyScreen({super.key, required this.property});

  @override
  State<LandlordEditPropertyScreen> createState() =>
      _LandlordEditPropertyScreenState();
}

class _LandlordEditPropertyScreenState
    extends State<LandlordEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final CloudinaryService _storageService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _roomsController;
  late TextEditingController _bedsController;
  late TextEditingController _showersController;

  bool _isLoading = false;
  AdminUser? _landlordProfile;
  
  // Image management
  List<String> _currentImageUrls = [];
  final List<XFile> _newImageFiles = [];
  final Set<int> _imagesToDelete = {}; // Track indices of images to delete

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.property.name);
    _addressController = TextEditingController(text: widget.property.address);
    _descriptionController =
        TextEditingController(text: widget.property.description);
    _priceController =
        TextEditingController(text: widget.property.price.toString());
    _roomsController =
        TextEditingController(text: widget.property.rooms.toString());
    _bedsController =
        TextEditingController(text: widget.property.beds.toString());
    _showersController =
        TextEditingController(text: widget.property.showers.toString());
    
    // Initialize with current images
    _currentImageUrls = List.from(widget.property.imageUrls);

    _fetchLandlordProfile();
  }

  Future<void> _fetchLandlordProfile() async {
    final profile = await _authService.getAdminUserProfile();
    if (mounted) {
      setState(() {
        _landlordProfile = profile;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _bedsController.dispose();
    _showersController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate images
    final remainingImages = _currentImageUrls.length - _imagesToDelete.length;
    final totalImages = remainingImages + _newImageFiles.length;
    
    if (totalImages == 0) {
      Fluttertoast.showToast(
        msg: "Please add at least one image",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId == null) throw Exception("User not logged in");

      // 1. Upload new images to Cloudinary
      List<String> newUploadedUrls = [];
      if (_newImageFiles.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uploadTasks = _newImageFiles.asMap().entries.map((entry) async {
          final imageFile = entry.value;
          final bytes = await imageFile.readAsBytes();
          final extension = p.extension(imageFile.path).isEmpty
              ? '.jpg'
              : p.extension(imageFile.path);
          final fileName = 'property_${userId}_${timestamp}_edit_${entry.key}$extension';

          return _storageService.uploadFile(
            folder: 'properties',
            bytes: bytes,
            fileName: fileName,
            userId: userId,
          );
        }).toList();
        newUploadedUrls = await Future.wait(uploadTasks);
      }

      // 2. Build final image URLs list (remove deleted, add new)
      List<String> finalImageUrls = [];
      for (int i = 0; i < _currentImageUrls.length; i++) {
        if (!_imagesToDelete.contains(i)) {
          finalImageUrls.add(_currentImageUrls[i]);
        }
      }
      finalImageUrls.addAll(newUploadedUrls);

      // 3. Update property
      final updatedProperty = Property(
        id: widget.property.id,
        landlordId: widget.property.landlordId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        rooms: int.parse(_roomsController.text.trim()),
        beds: int.parse(_bedsController.text.trim()),
        showers: int.parse(_showersController.text.trim()),
        imageUrls: finalImageUrls,
        status: widget.property.status,
        createdAt: widget.property.createdAt,
        approvedAt: widget.property.approvedAt,
      );

      await _dbService.updateProperty(updatedProperty);

      Fluttertoast.showToast(
        msg: "Property updated successfully!",
        backgroundColor: Colors.green,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating property: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85, // Compress to reduce issues
      );
      
      if (pickedFiles.isNotEmpty) {
        // Validate each image
        List<XFile> validImages = [];
        for (var file in pickedFiles) {
          try {
            // Try to read the file to validate it
            final bytes = await file.readAsBytes();
            if (bytes.isEmpty) {
              debugPrint("⚠️ Skipping empty image: ${file.name}");
              continue;
            }
            
            // Check file size (max 10MB)
            if (bytes.length > 10 * 1024 * 1024) {
              Fluttertoast.showToast(
                msg: "Image ${file.name} is too large (max 10MB)",
                backgroundColor: Colors.orange,
              );
              continue;
            }
            
            validImages.add(file);
          } catch (e) {
            debugPrint("⚠️ Invalid image ${file.name}: $e");
            Fluttertoast.showToast(
              msg: "Skipped invalid image: ${file.name}",
              backgroundColor: Colors.orange,
            );
          }
        }
        
        if (validImages.isNotEmpty) {
          setState(() {
            _newImageFiles.addAll(validImages);
          });
          Fluttertoast.showToast(
            msg: "Added ${validImages.length} image(s)",
            backgroundColor: Colors.green,
          );
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error picking images: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  void _toggleDeleteCurrentImage(int index) {
    setState(() {
      if (_imagesToDelete.contains(index)) {
        _imagesToDelete.remove(index);
      } else {
        _imagesToDelete.add(index);
      }
    });
  }

  Future<void> _replaceImage(int index) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress to reduce issues
      );
      
      if (pickedFile != null) {
        // Validate the image
        try {
          final bytes = await pickedFile.readAsBytes();
          if (bytes.isEmpty) {
            Fluttertoast.showToast(
              msg: "Selected image is empty",
              backgroundColor: Colors.red,
            );
            return;
          }
          
          // Check file size (max 10MB)
          if (bytes.length > 10 * 1024 * 1024) {
            Fluttertoast.showToast(
              msg: "Image is too large (max 10MB)",
              backgroundColor: Colors.red,
            );
            return;
          }
          
          setState(() {
            // Mark old image for deletion and add new one
            _imagesToDelete.add(index);
            _newImageFiles.add(pickedFile);
          });
          
          Fluttertoast.showToast(
            msg: "Image will be replaced when you save",
            backgroundColor: Colors.blue,
          );
        } catch (e) {
          Fluttertoast.showToast(
            msg: "Invalid image file",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error picking image: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Property'),
        backgroundColor: const Color(0xFF66BB6A), // lightGreen
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Landlord Info Section ---
              if (_landlordProfile != null) ...[
                const Text(
                  'Owner Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Name', '${_landlordProfile!.firstName ?? ''} ${_landlordProfile!.lastName ?? ''}'),
                _buildInfoRow('Username', _landlordProfile!.userName ?? 'N/A'),
                _buildInfoRow('Email', _landlordProfile!.email),
                _buildInfoRow('Phone', _landlordProfile!.phoneNumber ?? 'N/A'),
                const Divider(height: 32),
              ],
              // --- End Landlord Info Section ---

              _buildTextField(
                  controller: _nameController, label: 'Property Name'),
              _buildTextField(
                  controller: _addressController, label: 'Address'),
              _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 4),
              _buildTextField(
                  controller: _priceController,
                  label: 'Price per Month',
                  keyboardType: TextInputType.number),
              _buildTextField(
                  controller: _roomsController,
                  label: 'Number of Bathrooms',
                  keyboardType: TextInputType.number),
              _buildTextField(
                  controller: _bedsController,
                  label: 'Number of Beds',
                  keyboardType: TextInputType.number),
              _buildTextField(
                  controller: _showersController,
                  label: 'Number of Shower Rooms',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              
              // --- Image Management Section ---
              const Text(
                'Property Images',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Current Images
              if (_currentImageUrls.isNotEmpty) ...[
                const Text(
                  'Current Images (tap to replace, long-press to delete)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentImageUrls.length,
                    itemBuilder: (context, index) {
                      final isMarkedForDeletion = _imagesToDelete.contains(index);
                      return GestureDetector(
                        onTap: () => _replaceImage(index),
                        onLongPress: () => _toggleDeleteCurrentImage(index),
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isMarkedForDeletion ? Colors.red : Colors.grey,
                              width: isMarkedForDeletion ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _currentImageUrls[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  colorBlendMode: isMarkedForDeletion 
                                      ? BlendMode.saturation 
                                      : BlendMode.dst,
                                  color: isMarkedForDeletion 
                                      ? Colors.grey 
                                      : null,
                                ),
                              ),
                              if (isMarkedForDeletion)
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.delete_forever,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // New Images to Upload
              if (_newImageFiles.isNotEmpty) ...[
                const Text(
                  'New Images to Upload',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImageFiles.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_newImageFiles[index].path),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error, color: Colors.red),
                                        SizedBox(height: 4),
                                        Text(
                                          'Invalid\nImage',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Add Images Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add More Images'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              
              const SizedBox(height: 8),
              Text(
                'Total: ${(_currentImageUrls.length - _imagesToDelete.length) + _newImageFiles.length} images',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdateProperty,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value for $label';
          }
          return null;
        },
      ),
    );
  }
}
