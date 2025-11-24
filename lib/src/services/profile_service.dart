import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProfileService {
  static final _client = Supabase.instance.client;
  static final _storage = Supabase.instance.client.storage;
  static const bucket = 'avatars';

  /// UPLOAD AVATAR (Mobile / Web SAFE-ish)
  static Future<Map<String, dynamic>> uploadAvatarFile(
    File file, {
    required String userId,
  }) async {
    try {
      final path = file.path;

      // Default ext kalau gagal deteksi
      String ext = 'jpeg';

      // Coba ambil ext dari path kalau ada titik
      final dotIndex = path.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < path.length - 1) {
        final rawExt = path.substring(dotIndex + 1); // setelah "."
        // Kalau rawExt keliatan kayak ext bener (nggak ada ":" atau "/")
        if (!rawExt.contains(':') && !rawExt.contains('/')) {
          ext = rawExt;
        }
      }

      final fileName = "${userId}_${const Uuid().v4()}.$ext";

      // Aman: contentType jadi image/jpeg / image/png / dst, bukan blob:...
      await _storage.from(bucket).upload(
            fileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: "image/$ext",
            ),
          );

      final publicUrl = _storage.from(bucket).getPublicUrl(fileName);

      return {
        "ok": true,
        "url": publicUrl,
      };
    } catch (e) {
      return {
        "ok": false,
        "error": e.toString(),
      };
    }
  }

  /// UPDATE PROFILE
  static Future<Map<String, dynamic>> updateProfile(
    String userId, {
    String? displayName,
    String? bio,
    String? phone,
    String? defaultAddress,
    String? avatarUrl,
  }) async {
    try {
      final res = await _client
          .from("profiles")
          .upsert({
            "id": userId,
            "display_name": displayName,
            "bio": bio,
            "phone": phone,
            "default_address": defaultAddress,
            "avatar_url": avatarUrl,
            "updated_at": DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();

      return {"ok": true, "data": res};
    } catch (e) {
      return {"ok": false, "error": e.toString()};
    }
  }
}
