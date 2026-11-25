import 'dart:io';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _kAvatarPrefKey = 'user_custom_avatar_path';

/// Manages the user's custom profile avatar image path (local file path or network URL).
class ProfilePictureNotifier extends StateNotifier<String?> {
  ProfilePictureNotifier() : super(null) {
    _loadInitialAvatar();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _loadInitialAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString(_kAvatarPrefKey);

      if (savedPath != null && savedPath.isNotEmpty) {
        // If it's a web URL, accept it
        if (savedPath.startsWith('http://') || savedPath.startsWith('https://')) {
          state = savedPath;
          return;
        }

        // If it's a local file, verify existence
        final file = File(savedPath);
        if (await file.exists()) {
          state = savedPath;
          return;
        }
      }

      // Fallback: Check if Supabase user has an avatar_url in metadata
      final currentUser = Supabase.instance.client.auth.currentUser;
      final metadataUrl = currentUser?.userMetadata?['avatar_url'] as String?;
      if (metadataUrl != null && metadataUrl.isNotEmpty) {
        state = metadataUrl;
      }
    } catch (_) {
      // Graceful fallback to null initials if error loading storage
    }
  }

  /// Picks a photo from the device photo gallery.
  Future<bool> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );

      if (pickedFile == null) return false;

      return await _saveAvatarPath(pickedFile.path);
    } catch (_) {
      return false;
    }
  }

  /// Takes a new photo using the device camera.
  Future<bool> takePhotoWithCamera() async {
    try {
      final XFile? capturedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );

      if (capturedFile == null) return false;

      return await _saveAvatarPath(capturedFile.path);
    } catch (_) {
      return false;
    }
  }

  /// Saves the avatar path to persistent storage and updates state.
  Future<bool> _saveAvatarPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAvatarPrefKey, path);
      state = path;

      // Also persist to Supabase user metadata if signed in
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                ...?currentUser.userMetadata,
                'avatar_url': path,
              },
            ),
          );
        } catch (_) {
          // Local storage is updated, silent catch for network/auth offline
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resets profile picture back to default monogram initials.
  Future<void> removePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAvatarPrefKey);
      state = null;

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        try {
          final metadata = Map<String, dynamic>.from(currentUser.userMetadata ?? {});
          metadata.remove('avatar_url');
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: metadata),
          );
        } catch (_) {}
      }
    } catch (_) {}
  }
}

/// Global provider for the user's custom profile avatar picture.
final StateNotifierProvider<ProfilePictureNotifier, String?> profilePictureProvider =
    StateNotifierProvider<ProfilePictureNotifier, String?>(
  (ref) => ProfilePictureNotifier(),
);
