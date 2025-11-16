// lib/services/profile_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ProfileService {
  static final _client = Supabase.instance.client;

  /// Upload avatar file to 'avatars' bucket, return public URL (or null)
  static Future<String?> uploadAvatar(File file, {String? userId}) async {
    try {
      final uid = userId ?? _client.auth.currentUser?.id;
      if (uid == null) throw Exception('Not logged in');

      // build remote path: avatars/{userId}/{timestamp}_{filename}
      final filename = p.basename(file.path);
      final remotePath =
          'avatars/$uid/${DateTime.now().millisecondsSinceEpoch}_$filename';

      // upload file
      final res = await _client.storage.from('avatars').uploadBinary(
            remotePath,
            await file.readAsBytes(),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // get public url (if bucket is public)
      final publicUrl =
          _client.storage.from('avatars').getPublicUrl(remotePath);
      // if bucket private, use createSignedUrl
      // final signed = await _client.storage.from('avatars').createSignedUrl(remotePath, 60*60*24);
      return publicUrl;
    } catch (e) {
      // fallback: return null
      print('uploadAvatar error: $e');
      return null;
    }
  }

  /// Update profile row fields
  static Future<bool> updateProfile(String userId,
      {String? displayName,
      String? username,
      String? bio,
      String? avatarUrl}) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (username != null) data['username'] = username;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      data['updated_at'] = DateTime.now().toIso8601String();

      final res = await _client.from('profiles').update(data).eq('id', userId);
      // Supabase v2 returns PostgrestResponse-like without .error execute; treat as success
      return true;
    } catch (e) {
      print('updateProfile error: $e');
      return false;
    }
  }
}
