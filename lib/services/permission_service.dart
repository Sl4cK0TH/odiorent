import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Service to handle runtime permission requests for Camera, Storage, and Notifications
class PermissionService {
  /// Request all required permissions on app first launch
  /// Returns true if all permissions are granted, false otherwise
  static Future<bool> requestAllPermissions(BuildContext context) async {
    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.photos, // For iOS photo library
      Permission.storage, // For Android storage (deprecated on Android 13+)
      Permission.notification,
    ].request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      // Show dialog explaining why permissions are needed if any were denied
      if (context.mounted) {
        _showPermissionDialog(context, statuses);
      }
    }

    return allGranted;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage/photo permission
  static Future<bool> requestStoragePermission() async {
    // On Android 13+, use photos permission; on older versions, use storage
    if (await Permission.photos.isGranted) {
      return true;
    }
    
    PermissionStatus status = await Permission.photos.request();
    
    // Fallback to storage permission for older Android versions
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    
    return status.isGranted;
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> isStorageGranted() async {
    bool photosGranted = await Permission.photos.isGranted;
    bool storageGranted = await Permission.storage.isGranted;
    return photosGranted || storageGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Open app settings if permissions are permanently denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Show dialog explaining permission denials
  static void _showPermissionDialog(
    BuildContext context,
    Map<Permission, PermissionStatus> statuses,
  ) {
    List<String> deniedPermissions = [];

    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        String permissionName = _getPermissionName(permission);
        deniedPermissions.add(permissionName);
      }
    });

    if (deniedPermissions.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following permissions are required for the app to function properly:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...deniedPermissions.map(
              (permission) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(permission)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can grant these permissions in the app settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Get human-readable permission name with explanation
  static String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera - Required to upload property photos and profile pictures';
      case Permission.photos:
        return 'Photo Library - Required to select photos from your gallery';
      case Permission.storage:
        return 'Storage - Required to save and access photos';
      case Permission.notification:
        return 'Notifications - Required to receive booking updates, messages, and important alerts';
      default:
        return permission.toString().split('.').last;
    }
  }

  /// Request permission with explanation dialog before requesting
  static Future<bool> requestPermissionWithExplanation(
    BuildContext context,
    Permission permission,
    String title,
    String explanation,
  ) async {
    // Check if already granted
    if (await permission.isGranted) {
      return true;
    }

    // Show explanation dialog first
    if (!context.mounted) return false;
    
    bool? shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    if (shouldRequest != true) {
      return false;
    }

    // Request the permission
    PermissionStatus status = await permission.request();

    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            'This permission has been permanently denied. Please enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }

    return status.isGranted;
  }
}
