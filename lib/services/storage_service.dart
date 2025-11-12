import 'dart:io'; // Required to use the 'File' object
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

// Get the global Supabase client
final supabase = Supabase.instance.client;

class StorageService {
  /// --- UPLOAD IMAGE (Day 3 Task) ---
  /// Uploads a file to the 'properties' bucket in Supabase Storage.
  ///
  /// Takes a [File] (from an image picker) and a [userId] to create
  /// a unique and organized file path.
  ///
  /// Returns the public URL of the uploaded image as a [String].
  Future<String> uploadImage(File file, String userId) async {
    try {
      // We create a unique file path for the image.
      // Example: 'public/user_id_123/property_image_1678886400000.jpg'
      // This prevents file name conflicts and organizes uploads by user.
      final String fileExtension = file.path.split('.').last;
      final String fileName =
          'property_image_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final String filePath = 'public/$userId/$fileName';

      // Read the file as bytes to avoid namespace issues on Linux/Web
      final bytes = await file.readAsBytes();

      // Upload the file bytes to the 'properties' bucket
      await supabase.storage
          .from('properties') // This is your bucket name
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600', // Cache for 1 hour
              upsert: false, // Don't overwrite existing files
              contentType: _getContentType(fileExtension),
            ),
          );

      // Get the public URL of the file you just uploaded
      final String publicUrl = supabase.storage
          .from('properties')
          .getPublicUrl(filePath);

      debugPrint("Image uploaded successfully: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      rethrow; // Re-throw the error for the UI to handle
    }
  }

  /// Helper method to get the correct MIME type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default to jpeg
    }
  }

  /// --- UPLOAD PROFILE PICTURE ---
  /// Uploads a profile picture to the 'profile_pictures' bucket.
  ///
  /// Takes a [File] and a [userId].
  /// Returns the public URL of the uploaded image.
  Future<String> uploadProfilePicture(File file, String userId) async {
    try {
      final String fileExtension = file.path.split('.').last;
      // Use a consistent file name for profile pictures to allow easy replacement
      final String fileName = 'profile_pic.$fileExtension';
      final String filePath = 'public/$userId/$fileName';

      final bytes = await file.readAsBytes();

      await supabase.storage
          .from('profile_pictures') // Use a dedicated bucket for profile pictures
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true, // Allow overwriting existing profile pictures
              contentType: _getContentType(fileExtension),
            ),
          );

      final String publicUrl = supabase.storage
          .from('profile_pictures')
          .getPublicUrl(filePath);

      debugPrint("Profile picture uploaded successfully: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading profile picture: $e");
      rethrow;
    }
  }
}
