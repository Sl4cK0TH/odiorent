import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart'; // Import the package
import 'package:odiorent/models/property.dart';
import 'package:odiorent/models/property_room.dart'; // NEW
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/services/cloudinary_service.dart';
import 'package:odiorent/widgets/custom_button.dart';
import 'package:odiorent/widgets/location_picker.dart'; // Import LocationPicker
import 'package:path/path.dart' as p; // Import path package with prefix

// Helper class for UI state before upload
class _PendingRoom {
  String title;
  int capacity;
  double price;
  String description;
  List<File> images;

  _PendingRoom({
    required this.title,
    required this.capacity,
    required this.price,
    required this.description,
    required this.images,
  });
}

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
  final _roomsController = TextEditingController(text: '0'); // Auto-calculated
  final _bedsController = TextEditingController(text: '0'); // Auto-calculated
  final _showersController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Services
  final _dbService = FirebaseDatabaseService();
  final _storageService = CloudinaryService();
  final _authService = FirebaseAuthService();

  // State variables
  bool _isLoading = false;
  final List<File> _selectedImages = []; // To hold the image files
  final List<XFile> _selectedVideos = []; // To hold the video files
  final ImagePicker _picker = ImagePicker(); // The image picker instance
  bool _isUploadingVideo = false;
  double _videoUploadProgress = 0.0;
  
  // New: Coordinates
  double? _latitude;
  double? _longitude;
  
  // New: Pending Rooms
  final List<_PendingRoom> _pendingRooms = [];

  void _calculateTotals() {
    int totalRooms = _pendingRooms.length;
    int totalBeds = _pendingRooms.fold(0, (sum, room) => sum + room.capacity);
    
    // If we have rooms, use their lowest price as the "Starting Price"
    if (_pendingRooms.isNotEmpty) {
        double minPrice = _pendingRooms.map((r) => r.price).reduce((a, b) => a < b ? a : b);
        _priceController.text = minPrice.toStringAsFixed(0);
    }

    setState(() {
      _roomsController.text = totalRooms.toString();
      _bedsController.text = totalBeds.toString();
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _streetAddressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _bedsController.dispose();
    _showersController.dispose();
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

  // --- Video Picker Functions ---
  Future<void> _pickVideo({required ImageSource source}) async {
    if (_selectedVideos.isNotEmpty) {
      Fluttertoast.showToast(
        msg: "Maximum 1 video allowed",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickVideo(source: source);

      if (pickedFile != null) {
        // Validate video
        final validation = await _storageService.validateVideo(
          videoFile: pickedFile,
          maxSizeMB: 50,
          maxDurationSeconds: 180, // 3 minutes
        );

        if (validation != null) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: validation,
              backgroundColor: Colors.red,
              toastLength: Toast.LENGTH_LONG,
            );
          }
          return;
        }

        setState(() {
          _selectedVideos.add(pickedFile);
        });

        Fluttertoast.showToast(
          msg: "Video added successfully",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error selecting video: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  void _showVideoSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Video Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(source: ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Room Management Dialog ---
  void _showAddRoomDialog() {
    final titleController = TextEditingController();
    final capacityController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    List<File> roomImages = [];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Room / Unit"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Room Title (e.g., Room 101)"),
                    ),
                    TextField(
                        controller: capacityController,
                        decoration: const InputDecoration(labelText: "Capacity (Beds)"),
                        keyboardType: TextInputType.number,
                    ),
                    TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: "Price (Per Month)"),
                        keyboardType: TextInputType.number,
                    ),
                     TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: "Description (Optional)"),
                    ),
                    const SizedBox(height: 10),
                    const Text("Room Images (Required)"),
                    const SizedBox(height: 5),
                    Wrap(
                        spacing: 8,
                        children: [
                            ...roomImages.map((img) => Stack(
                                children: [
                                    Image.file(img, width: 60, height: 60, fit: BoxFit.cover),
                                    Positioned(
                                        right: 0,
                                        top: 0,
                                        child: InkWell(
                                            onTap: () {
                                                setStateDialog(() {
                                                    roomImages.remove(img);
                                                });
                                            },
                                            child: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                        ),
                                    )
                                ],
                            )),
                            IconButton(
                                icon: const Icon(Icons.add_a_photo),
                                onPressed: () async {
                                    final picked = await _picker.pickMultiImage();
                                    if (picked.isNotEmpty) {
                                        setStateDialog(() {
                                            roomImages.addAll(picked.map((x) => File(x.path)));
                                        });
                                    }
                                },
                            ),
                        ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                ),
                ElevatedButton(
                    onPressed: () {
                        if (titleController.text.isEmpty || capacityController.text.isEmpty || priceController.text.isEmpty) {
                             Fluttertoast.showToast(msg: "Please fill Title, Capacity, and Price");
                             return;
                        }
                        if (roomImages.isEmpty) {
                            Fluttertoast.showToast(msg: "Please upload at least one image for this room");
                            return;
                        }
                        
                        final newRoom = _PendingRoom(
                            title: titleController.text.trim(),
                            capacity: int.tryParse(capacityController.text.trim()) ?? 1,
                            price: double.tryParse(priceController.text.trim()) ?? 0.0,
                            description: descriptionController.text.trim(),
                            images: roomImages,
                        );
                        
                        setState(() {
                            _pendingRooms.add(newRoom);
                            _calculateTotals(); // Update main form totals
                        });
                        
                        Navigator.pop(context);
                    },
                    child: const Text("Add Room"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeRoom(int index) {
      setState(() {
          _pendingRooms.removeAt(index);
          _calculateTotals();
      });
  }

  // --- Create Property Function ---
  Future<void> _handleCreateProperty() async {
    if (!_formKey.currentState!.validate()) return; // Check form
    if (_selectedImages.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please upload at least one main property image.",
        backgroundColor: Colors.red,
      );
      return;
    }
    if (_selectedVideos.length != 1) {
      Fluttertoast.showToast(
        msg: "Please upload exactly 1 video for virtual tour.",
        backgroundColor: Colors.red,
      );
      return;
    }
    if (_pendingRooms.isEmpty) {
       Fluttertoast.showToast(
        msg: "Please add at least one Room/Unit.",
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

      // 1. Upload Main Property Images
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

      // 2. Upload Video
      setState(() => _isUploadingVideo = true);
      final List<String> videoUrls = [];
      for (int i = 0; i < _selectedVideos.length; i++) {
        final videoFile = _selectedVideos[i];
        final videoUrl = await _storageService.uploadVideoWithCompression(
          videoFile: videoFile,
          folder: 'virtual_tours',
          userId: userId,
          maxSizeMB: 50,
          maxDurationSeconds: 180,
          onProgress: (progress) {
            setState(() {
              _videoUploadProgress = ((i + progress) / _selectedVideos.length);
            });
          },
        );
        videoUrls.add(videoUrl);
      }
      setState(() => _isUploadingVideo = false);

      // 3. Create Property Object
      final fullAddress = "${_streetAddressController.text.trim()}, $_selectedBarangay, Odiongan, Romblon";
      
      // Note: Rooms/Beds/Price are derived or taken from inputs (which were auto-updated)
      // We ensure price is consistent with rooms
      
      final newProperty = Property(
        landlordId: userId,
        name: _nameController.text.trim(),
        address: fullAddress,
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()), // Starting price
        rooms: int.parse(_roomsController.text.trim()),
        beds: int.parse(_bedsController.text.trim()),
        showers: int.parse(_showersController.text.trim()),
        imageUrls: imageUrls,
        videoUrls: videoUrls,
        status: PropertyStatus.pending,
        createdAt: DateTime.now().toUtc(),
        latitude: _latitude,
        longitude: _longitude,
      );

      // 4. Save Property & Get ID
      final String propertyId = await _dbService.createProperty(newProperty);

      // 5. Upload & Create Rooms
      for (int i = 0; i < _pendingRooms.length; i++) {
          final room = _pendingRooms[i];
          
          // Upload Room Images
          final roomUploadTasks = room.images.asMap().entries.map((entry) async {
            final f = entry.value;
            final b = await f.readAsBytes();
            final ext = p.extension(f.path).isEmpty ? '.jpg' : p.extension(f.path);
            final fname = 'room_${propertyId}_${i}_${entry.key}$ext';
            return _storageService.uploadFile(folder: 'rooms', bytes: b, fileName: fname, userId: userId);
          }).toList();
          
          final roomImageUrls = await Future.wait(roomUploadTasks);
          
          final propertyRoom = PropertyRoom(
              propertyId: propertyId,
              title: room.title,
              description: room.description,
              price: room.price,
              capacity: room.capacity,
              imageUrls: roomImageUrls,
              createdAt: DateTime.now(),
          );
          
          await _dbService.addRoomToProperty(propertyId, propertyRoom);
      }

      if (!mounted) return;

      Fluttertoast.showToast(
        msg: "Property & Rooms submitted successfully!",
        backgroundColor: Colors.green,
      );

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
                
                // --- Location Picker ---
                const Text(
                  'Pin Location on Map (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LocationPicker(
                  onLocationPicked: (lat, lng) {
                    setState(() {
                      _latitude = lat;
                      _longitude = lng;
                    });
                  },
                ),
                const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  
                  // --- Rooms Section ---
                  const Text("Rooms / Units", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_pendingRooms.isEmpty)
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text("No rooms added yet. Please add at least one.")),
                    ),
                  ..._pendingRooms.asMap().entries.map((entry) {
                      final index = entry.key;
                      final room = entry.value;
                      return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                              leading: room.images.isNotEmpty 
                                ? Image.file(room.images.first, width: 50, height: 50, fit: BoxFit.cover)
                                : const Icon(Icons.bed),
                              title: Text(room.title),
                              subtitle: Text("${room.capacity} Beds • ₱${room.price.toStringAsFixed(0)}/mo"),
                              trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeRoom(index),
                              ),
                          ),
                      );
                  }),
                  const SizedBox(height: 8),
                  CustomButton(
                      text: "Add Room",
                      onPressed: _showAddRoomDialog,
                      backgroundColor: Colors.orange,
                  ),
                  const Divider(height: 32),
                  
                  _buildTextField(
                    controller: _descriptionController,
                    labelText: 'Description',
                    prefixIcon: Icons.description,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _priceController,
                    labelText: 'Starting Price (₱)',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNumber(
                      value,
                      allowDecimal: true,
                      emptyMessage: 'Price is required',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                        Expanded(child: _buildTextField(
                            controller: _roomsController,
                            labelText: "Total Rooms",
                            prefixIcon: Icons.meeting_room,
                            readOnly: true,
                        )),
                        const SizedBox(width: 10),
                         Expanded(child: _buildTextField(
                            controller: _bedsController,
                            labelText: "Total Capacity (Beds)",
                            prefixIcon: Icons.bed,
                            readOnly: true,
                        )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _showersController,
                    labelText: 'Shower Rooms',
                    prefixIcon: Icons.shower,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNumber(
                      value,
                      emptyMessage: 'Number of shower rooms is required',
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
                  const SizedBox(height: 24),

                  // --- Virtual Tour Videos Section ---
                  const Text(
                    'Virtual Tour Video (Required)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload 1 video (max 3 minutes, 50MB max)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: primaryGreen),
                    ),
                    onPressed: _selectedVideos.isEmpty ? _showVideoSourceDialog : null,
                    icon: const Icon(Icons.video_library),
                    label: Text('Add Video (${_selectedVideos.length}/1)'),
                  ),
                  const SizedBox(height: 16),

                  // --- Video Preview ---
                  if (_selectedVideos.isNotEmpty)
                    Column(
                      children: _selectedVideos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final video = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildVideoPreview(video, index),
                        );
                      }).toList(),
                    ),

                  if (_isUploadingVideo)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        const Text('Compressing and uploading videos...'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _videoUploadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                        ),
                        const SizedBox(height: 4),
                        Text('${(_videoUploadProgress * 100).toStringAsFixed(0)}%'),
                      ],
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

  // Build video preview widget
  Widget _buildVideoPreview(XFile video, int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.play_circle_outline,
            color: Colors.white,
            size: 32,
          ),
        ),
        title: Text(
          video.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: FutureBuilder<int>(
          future: video.readAsBytes().then((bytes) => bytes.length),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final sizeMB = snapshot.data! / (1024 * 1024);
              return Text('${sizeMB.toStringAsFixed(2)} MB');
            }
            return const Text('Calculating size...');
          },
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeVideo(index),
        ),
      ),
    );
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  // Helper widget for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: readOnly ? const TextStyle(color: Colors.grey) : null,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: primaryGreen),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
          borderSide: BorderSide(color: primaryGreen, width: 2.0),
        ),
      ),
      validator: validator,
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
