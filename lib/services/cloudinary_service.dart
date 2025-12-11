import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Cloudinary Storage Service
/// FREE alternative to Firebase Storage
/// 25GB storage + 25GB bandwidth FREE
class CloudinaryService {
  // TODO: Replace with your Cloudinary credentials
  // Get them from: https://cloudinary.com/console
  static const String _cloudName = 'dyms1cj8s'; // e.g., 'dxxxxx'
  static const String _uploadPreset = 'odiorent_uploads'; // Create in settings

  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// Upload file from bytes
  /// Returns the public URL of uploaded file
  /// Supports: Images (JPG, PNG, GIF, WebP) and Videos (MP4, MOV, AVI, etc.)
  Future<String> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String folder, // e.g., 'profile_pictures', 'property_images', 'virtual_tours'
    String? userId,
    CloudinaryResourceType? resourceType, // Auto-detect if null
  }) async {
    try {
      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = userId != null 
          ? '${userId}_${timestamp}_$fileName'
          : '${timestamp}_$fileName';

      // Auto-detect resource type from file extension if not specified
      final detectedResourceType = resourceType ?? _detectResourceType(fileName);

      // Upload to Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: uniqueFileName,
          folder: folder,
          resourceType: detectedResourceType,
        ),
      );

      final fileType = detectedResourceType == CloudinaryResourceType.Video ? 'video' : 'image';
      debugPrint('✅ $fileType uploaded to Cloudinary: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      debugPrint('❌ Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  /// Detect resource type from file extension
  CloudinaryResourceType _detectResourceType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    // Video extensions
    const videoExtensions = [
      'mp4', 'mov', 'avi', 'wmv', 'flv', 'mkv', 
      'webm', 'mpeg', 'mpg', '3gp', 'm4v'
    ];
    
    if (videoExtensions.contains(extension)) {
      return CloudinaryResourceType.Video;
    }
    
    return CloudinaryResourceType.Image; // Default to image
  }

  /// Upload file from XFile (from image_picker)
  Future<String> uploadXFile({
    required XFile file,
    required String folder,
    String? userId,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadFile(
        bytes: bytes,
        fileName: file.name,
        folder: folder,
        userId: userId,
      );
    } catch (e) {
      debugPrint('❌ Error uploading XFile: $e');
      rethrow;
    }
  }

  /// Upload multiple files
  Future<List<String>> uploadMultipleFiles({
    required List<Uint8List> filesBytesList,
    required List<String> fileNames,
    required String folder,
    String? userId,
  }) async {
    try {
      final List<String> urls = [];

      for (int i = 0; i < filesBytesList.length; i++) {
        final url = await uploadFile(
          bytes: filesBytesList[i],
          fileName: fileNames[i],
          folder: folder,
          userId: userId,
        );
        urls.add(url);
      }

      debugPrint('✅ Uploaded ${urls.length} files to Cloudinary');
      return urls;
    } catch (e) {
      debugPrint('❌ Error uploading multiple files: $e');
      rethrow;
    }
  }

  /// Upload multiple XFiles (from image_picker)
  Future<List<String>> uploadMultipleXFiles({
    required List<XFile> files,
    required String folder,
    String? userId,
  }) async {
    try {
      final List<String> urls = [];

      for (final file in files) {
        final url = await uploadXFile(
          file: file,
          folder: folder,
          userId: userId,
        );
        urls.add(url);
      }

      debugPrint('✅ Uploaded ${urls.length} files to Cloudinary');
      return urls;
    } catch (e) {
      debugPrint('❌ Error uploading multiple XFiles: $e');
      rethrow;
    }
  }

  /// Delete a file by public ID
  /// Extract public_id from URL: 
  /// https://res.cloudinary.com/cloud_name/image/upload/v1234567890/folder/file.jpg
  /// public_id = folder/file
  /// NOTE: Cloudinary free tier doesn't support API deletion
  /// Files can be deleted manually from Cloudinary dashboard
  Future<void> deleteFile(String publicId) async {
    try {
      // TODO: Cloudinary free tier API doesn't support deleteFile method
      // For now, files need to be deleted manually from dashboard
      // Or upgrade to paid plan for API deletion
      debugPrint('ℹ️ File deletion not supported in free tier: $publicId');
      debugPrint('ℹ️ Please delete manually from Cloudinary dashboard if needed');
      
      // await _cloudinary.deleteFile(
      //   url: publicId,
      //   resourceType: CloudinaryResourceType.Image,
      //   invalidate: true,
      // );
    } catch (e) {
      debugPrint('❌ Error deleting from Cloudinary: $e');
      // Don't throw - file might already be deleted
    }
  }

  /// Get optimized image URL with transformations
  /// Example: Resize to 800x600, quality 80%
  String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    int quality = 80,
  }) {
    // Cloudinary transformation URL pattern
    // https://res.cloudinary.com/cloud_name/image/upload/w_800,h_600,q_80/folder/file.jpg
    
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl; // Not a Cloudinary URL
    }

    final transformations = <String>[];
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');

    final transformation = transformations.join(',');
    
    // Insert transformation after /upload/
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/$transformation/',
    );
  }

  /// Get thumbnail URL (square, 200x200)
  String getThumbnailUrl(String originalUrl) {
    return getOptimizedImageUrl(
      originalUrl,
      width: 200,
      height: 200,
      quality: 70,
    );
  }

  /// Get video thumbnail (auto-generated from video)
  /// Cloudinary automatically generates thumbnails for videos
  String getVideoThumbnail(String videoUrl, {int timeOffset = 0}) {
    if (!videoUrl.contains('cloudinary.com')) {
      return videoUrl;
    }

    // Convert video URL to thumbnail image
    // Example: video/upload/v123/video.mp4 → image/upload/v123/video.jpg
    // Add so_<seconds> for specific frame
    final thumbnail = videoUrl
        .replaceFirst('/video/', '/image/')
        .replaceFirst(RegExp(r'\.(mp4|mov|avi|webm)$'), '.jpg');
    
    if (timeOffset > 0) {
      // Get frame at specific second
      return thumbnail.replaceFirst('/upload/', '/upload/so_$timeOffset/');
    }
    
    return thumbnail;
  }

  /// Check if URL is a video
  bool isVideoUrl(String url) {
    return url.contains('/video/upload/') || 
           url.toLowerCase().endsWith('.mp4') ||
           url.toLowerCase().endsWith('.mov') ||
           url.toLowerCase().endsWith('.webm') ||
           url.toLowerCase().endsWith('.avi');
  }

  /// Get optimized video URL
  /// Quality: 'auto', 'good', 'best', 'low'
  String getOptimizedVideoUrl(
    String originalUrl, {
    int? width,
    String quality = 'auto',
    String format = 'mp4',
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    final transformations = <String>[];
    if (width != null) transformations.add('w_$width');
    transformations.add('q_$quality');
    transformations.add('f_$format');

    final transformation = transformations.join(',');
    
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/$transformation/',
    );
  }
}
