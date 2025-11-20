// lib/services/profile_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final _storage = Supabase.instance.client.storage;
  static const _avatarBucket = 'avatars';
  static final _uuid = Uuid();

  /// Upload avatar: return {ok:true, url:'...'} or {ok:false, error:'...'}
  static Future<Map<String, dynamic>> uploadAvatar(
    File f, {
    required String userId,
  }) async {
    try {
      final ext = f.path.split('.').last;
      final key = 'avatars/$userId/${_uuid.v4()}.$ext';

      final upload = await _storage.from(_avatarBucket).upload(key, f);
      debugPrint('storage.upload result: $upload');

      // Try getPublicUrl
      try {
        final pub = _storage.from(_avatarBucket).getPublicUrl(key);

        if (pub is String && pub.isNotEmpty) {
          return {'ok': true, 'url': pub};
        }
      } catch (_) {}

      // fallback signed url
      try {
        final signed = await _storage
            .from(_avatarBucket)
            .createSignedUrl(key, 60 * 60 * 24);

        if (signed != null && signed is String) {
          return {'ok': true, 'url': signed};
        }
      } catch (_) {}

      return {
        'ok': false,
        'error': 'Upload selesai tapi URL tidak ditemukan.'
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  /// Upsert profile
  static Future<Map<String, dynamic>> updateProfile(
    String userId, {
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? defaultAddress,
    String? email,
  }) async {
    try {
      final payload = {
        'id': userId,
        if (username != null) 'username': username,
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
        if (phone != null) 'phone': phone,
        if (defaultAddress != null) 'default_address': defaultAddress,
        if (email != null) 'email': email,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      debugPrint('profile upsert payload: $payload');

      final resp = await _client
          .from('profiles')
          .upsert(payload, onConflict: 'id')
          .select()
          .maybeSingle();

      debugPrint('profile upsert resp: $resp');

      return {'ok': true, 'data': resp};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }
}
