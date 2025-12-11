import 'dart:typed_data';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

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

  /// Compress video if larger than maxSizeMB
  /// Returns compressed video file or original if already small enough
  Future<XFile> compressVideoIfNeeded({
    required XFile videoFile,
    int maxSizeMB = 50,
    VideoQuality quality = VideoQuality.MediumQuality,
  }) async {
    try {
      // Check original file size
      final bytes = await videoFile.readAsBytes();
      final sizeMB = bytes.length / (1024 * 1024);

      debugPrint('📹 Original video size: ${sizeMB.toStringAsFixed(2)} MB');

      if (sizeMB <= maxSizeMB) {
        debugPrint('✅ Video size OK, no compression needed');
        return videoFile;
      }

      debugPrint('🔄 Compressing video from ${sizeMB.toStringAsFixed(2)} MB...');

      // Compress video
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: false,
      );

      if (info == null || info.file == null) {
        debugPrint('⚠️ Compression failed, using original video');
        return videoFile;
      }

      final compressedSizeMB = info.filesize! / (1024 * 1024);
      debugPrint('✅ Video compressed to ${compressedSizeMB.toStringAsFixed(2)} MB');

      // If still too large, try lower quality
      if (compressedSizeMB > maxSizeMB && quality != VideoQuality.LowQuality) {
        debugPrint('⚠️ Still too large, trying lower quality...');
        return await compressVideoIfNeeded(
          videoFile: XFile(info.file!.path),
          maxSizeMB: maxSizeMB,
          quality: VideoQuality.LowQuality,
        );
      }

      return XFile(info.file!.path);
    } catch (e) {
      debugPrint('❌ Error compressing video: $e');
      return videoFile; // Return original on error
    }
  }

  /// Validate video file
  /// Returns error message or null if valid
  Future<String?> validateVideo({
    required XFile videoFile,
    int maxSizeMB = 50,
    int maxDurationSeconds = 180, // 3 minutes
  }) async {
    try {
      // Check file size
      final bytes = await videoFile.readAsBytes();
      final sizeMB = bytes.length / (1024 * 1024);

      if (sizeMB > maxSizeMB) {
        return 'Video is too large (${sizeMB.toStringAsFixed(1)} MB). Maximum is $maxSizeMB MB.';
      }

      // Check file extension
      final extension = videoFile.path.split('.').last.toLowerCase();
      const validExtensions = ['mp4', 'mov', 'avi', 'webm', 'm4v'];
      
      if (!validExtensions.contains(extension)) {
        return 'Invalid video format. Supported formats: ${validExtensions.join(", ")}';
      }

      // Get video info for duration check
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      
      if (info.duration != null) {
        final durationSeconds = info.duration! / 1000; // Convert ms to seconds
        
        if (durationSeconds > maxDurationSeconds) {
          final minutes = (durationSeconds / 60).toStringAsFixed(1);
          final maxMinutes = (maxDurationSeconds / 60).toStringAsFixed(0);
          return 'Video is too long ($minutes min). Maximum is $maxMinutes minutes.';
        }
      }

      return null; // Valid
    } catch (e) {
      debugPrint('❌ Error validating video: $e');
      return 'Error validating video: $e';
    }
  }

  /// Upload video with compression and validation
  Future<String> uploadVideoWithCompression({
    required XFile videoFile,
    required String folder,
    String? userId,
    int maxSizeMB = 50,
    int maxDurationSeconds = 180,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate video
      final validationError = await validateVideo(
        videoFile: videoFile,
        maxSizeMB: maxSizeMB,
        maxDurationSeconds: maxDurationSeconds,
      );

      if (validationError != null) {
        throw Exception(validationError);
      }

      // Compress if needed
      onProgress?.call(0.1);
      final compressedVideo = await compressVideoIfNeeded(
        videoFile: videoFile,
        maxSizeMB: maxSizeMB,
      );

      // Upload to Cloudinary
      onProgress?.call(0.5);
      final url = await uploadXFile(
        file: compressedVideo,
        folder: folder,
        userId: userId,
      );

      onProgress?.call(1.0);
      
      // Cleanup compressed file if different from original
      if (compressedVideo.path != videoFile.path) {
        try {
          await File(compressedVideo.path).delete();
        } catch (e) {
          debugPrint('⚠️ Could not delete temp file: $e');
        }
      }

      return url;
    } catch (e) {
      debugPrint('❌ Error uploading video: $e');
      rethrow;
    }
  }

  /// Cancel ongoing video compression
  Future<void> cancelVideoCompression() async {
    try {
      await VideoCompress.cancelCompression();
      debugPrint('✅ Video compression cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling compression: $e');
    }
  }

  /// Delete all temporary compressed videos
  Future<void> deleteAllTempVideos() async {
    try {
      await VideoCompress.deleteAllCache();
      debugPrint('✅ Deleted all temp videos');
    } catch (e) {
      debugPrint('❌ Error deleting temp videos: $e');
    }
  }
}
