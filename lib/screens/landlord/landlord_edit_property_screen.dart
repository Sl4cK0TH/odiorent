import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odiorent/models/property.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:odiorent/models/admin_user.dart';
import 'package:odiorent/services/firebase_auth_service.dart';

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

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _roomsController;
  late TextEditingController _bedsController;

  bool _isLoading = false;
  AdminUser? _landlordProfile;

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
    super.dispose();
  }

  Future<void> _handleUpdateProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProperty = Property(
        id: widget.property.id,
        landlordId: widget.property.landlordId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        rooms: int.parse(_roomsController.text.trim()),
        beds: int.parse(_bedsController.text.trim()),
        imageUrls: widget.property.imageUrls,
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
              const SizedBox(height: 24),
              // TODO: Add image editing functionality here
              const Text("Image editing is not yet available.", style: TextStyle(color: Colors.grey)),
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
