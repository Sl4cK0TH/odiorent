import 'dart:typed_data'; // For Uint8List
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:path/path.dart' as p; // For extension

// Get the global Supabase client
final supabase = Supabase.instance.client;

class StorageService {
  /// --- UPLOAD FILE (Generic) ---
  /// Uploads a file to a specified Supabase Storage bucket.
  ///
  /// Takes [Uint8List bytes] (the file content), a [fileName] (e.g., 'image.jpg'),
  /// a [userId] to create a unique and organized file path, and the [bucket] name.
  ///
  /// Returns the public URL of the uploaded file as a [String].
  Future<String> uploadFile({
    required String bucket,
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    try {
      final String filePath = '$userId/$fileName';

      await supabase.storage
          .from(bucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600', // Cache for 1 hour
              upsert: true, // Allow overwriting existing files (especially for profile pics)
              contentType: _getContentType(p.extension(fileName)),
            ),
          );

      final String publicUrl =
          supabase.storage.from(bucket).getPublicUrl(filePath);

      debugPrint("File uploaded successfully to $bucket: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading file to $bucket: $e");
      rethrow;
    }
  }

  /// Helper method to get the correct MIME type based on file extension
  String _getContentType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream'; // Generic binary data
    }
  }
}
