import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum _PickerAction { camera, gallery, remove }

/// Result returned by [ImagePickerService.pick].
class ImagePickResult {
  /// Picked file, or null if the user cancelled / permission denied.
  final File? file;

  /// Human-readable reason why file is null (empty when file is non-null).
  final String? error;

  /// True if the user selected to remove/delete the picture.
  final bool isRemoved;

  const ImagePickResult({this.file, this.error, this.isRemoved = false});
  bool get success => file != null;
}

class ImagePickerService {
  ImagePickerService._();

  static final _picker = ImagePicker();

  static Future<ImagePickResult> pick({
    required ImageSource source,
    double maxWidth = 512,
    double maxHeight = 512,
    int quality = 85,
  }) async {
    // 1. Check / request permissions
    final permResult = await _requestPermission(source);
    if (!permResult) {
      return const ImagePickResult(error: 'Permission denied');
    }
    try {
      final XFile? xFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality,
        requestFullMetadata: false,
      );

      if (xFile == null) {
        return const ImagePickResult();
      }

      return ImagePickResult(file: File(xFile.path));
    } catch (e) {
      return ImagePickResult(error: 'Failed to pick image: $e');
    }
  }

  /// Pass a [BuildContext] so the sheet is parented to the correct route.
  static Future<ImagePickResult?> showPickerSheet(
    BuildContext context, {
    bool showRemoveOption = false,
  }) async {
    final theme = Theme.of(context);
    final action = await showModalBottomSheet<_PickerAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) => _PickerSheet(theme: theme, showRemoveOption: showRemoveOption),
    );

    if (action == null) return null; // dismissed

    if (action == _PickerAction.remove) {
      return const ImagePickResult(isRemoved: true);
    }

    final source = action == _PickerAction.camera ? ImageSource.camera : ImageSource.gallery;
    return pick(source: source);
  }

  static Future<bool> _requestPermission(ImageSource source) async {
    if (Platform.isIOS) {
      Permission permission = source == ImageSource.camera ? Permission.camera : Permission.photos;

      final status = await permission.request();

      if (status.isGranted || status.isLimited) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        await _showSettingsDialog(
          title: source == ImageSource.camera ? "Camera Access" : "Photo Library Access",
          message:
              source == ImageSource.camera
                  ? "Please allow camera access from Settings."
                  : "Please allow photo library access from Settings.",
        );
      }

      return false;
    }

    // Android: version-specific permissions
    final permissions = await _requiredPermissions(source);
    final statuses = await permissions.request();

    bool allGranted = true;
    bool anyPermanentlyDenied = false;

    for (final perm in permissions) {
      final s = statuses[perm];
      if (s == null || s.isDenied) {
        allGranted = false;
      }
      if (s?.isPermanentlyDenied == true) {
        anyPermanentlyDenied = true;
      }
    }

    if (anyPermanentlyDenied) {
      await _showSettingsDialog(
        title: source == ImageSource.camera ? 'Camera Access Required' : 'Gallery Access Required',
        message:
            source == ImageSource.camera
                ? 'Camera permission is required to take a photo. Please enable it in Settings.'
                : 'Storage/media permission is required to pick a photo from gallery. Please enable it in Settings.',
      );
      return false;
    }

    if (!allGranted) {
      return false;
    }

    return true;
  }

  /// Returns the set of [Permission]s needed based on Android version and source.
  static Future<List<Permission>> _requiredPermissions(ImageSource source) async {
    if (Platform.isIOS) return [Permission.photos];

    final perms = <Permission>[];

    if (source == ImageSource.camera) {
      perms.add(Permission.camera);
    } else {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        if (sdkInt >= 33) {
          perms.add(Permission.photos);
        } else {
          perms.add(Permission.storage);
        }
      } else {
        perms.add(Permission.photos);
      }
    }

    return perms;
  }

  // ── Settings redirect dialog ───────────────────────────────────────────────

  static Future<void> _showSettingsDialog({required String title, required String message}) async {
    await Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

// ── Internal Bottom-Sheet widget ───────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final ThemeData theme;
  final bool showRemoveOption;
  const _PickerSheet({required this.theme, this.showRemoveOption = false});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ───────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Title ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
              child: Text(
                'Profile Photo',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),

            const Divider(height: 1),

            // ── Camera ───────────────────────────────────────────────
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary, size: 20),
              ),
              title: Text(
                'Take photo',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Open camera to take a new photo',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              onTap: () => Navigator.pop(context, _PickerAction.camera),
            ),

            // ── Gallery ──────────────────────────────────────────────
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_rounded, color: theme.colorScheme.secondary, size: 20),
              ),
              title: Text(
                'Choose from gallery',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Pick an existing photo from your device',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              onTap: () => Navigator.pop(context, _PickerAction.gallery),
            ),

            if (showRemoveOption) ...[
              const Divider(height: 1),
              // ── Remove Photo ─────────────────────────────────────────
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                ),
                title: Text(
                  'Remove photo',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: Colors.red),
                ),
                subtitle: Text(
                  'Delete current profile photo',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.withValues(alpha: 0.7)),
                ),
                onTap: () => Navigator.pop(context, _PickerAction.remove),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
