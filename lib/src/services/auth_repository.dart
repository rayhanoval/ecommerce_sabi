import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

abstract class AuthRepository {
  Future<bool> register(String email, String password,
      {String? fullName, String? username});
  Future<bool> login(String email, String password);
  Future<void> logout();
  bool isLoggedIn();
  Future<Map<String, dynamic>?> getCurrentProfile();
  Future<bool> updateProfile(Map<String, dynamic> data);
}

class AuthException implements Exception {
  final String code;
  final String message;
  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Future<bool> register(
    String email,
    String password, {
    String? fullName,
    String? username,
  }) async {
    try {
      // Check if email already exists
      final emailCheck = await _client
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (emailCheck != null) {
        throw AuthException('EMAIL_TAKEN', 'Email is already registered');
      }

      // Check if username already exists
      final finalUsername = (username?.trim().isNotEmpty ?? false)
          ? username!.trim()
          : 'user_${DateTime.now().millisecondsSinceEpoch % 100000}';

      final usernameCheck = await _client
          .from('users')
          .select('username')
          .eq('username', finalUsername)
          .maybeSingle();

      if (usernameCheck != null) {
        throw AuthException('USERNAME_TAKEN', 'Username is already taken');
      }

      final res = await _client.auth.signUp(email: email, password: password);
      final user = res.user;
      if (user == null) {
        // debugPrint('register: signUp returned no user. res: $res');
        return false;
      }

      try {
        await _client.from('users').insert({
          'id': user.id,
          'email': email,
          'username': finalUsername,
          'avatar_url': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).select();
      } catch (e) {
        // debugPrint('users insert error: $e');
        return false;
      }

      return true;
    } catch (e) {
      // debugPrint('register error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.session != null;
    } on AuthApiException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        throw AuthException('WRONG_CREDENTIALS', 'Email atau password salah');
      } else if (msg.contains('user not found')) {
        throw AuthException('USER_NOT_FOUND', 'Email belum terdaftar');
      } else {
        throw AuthException('UNKNOWN', e.message);
      }
    } catch (e) {
      throw AuthException('UNKNOWN', 'Terjadi kesalahan tak terduga');
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  @override
  bool isLoggedIn() {
    return _client.auth.currentSession != null;
  }

  @override
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final res =
        await _client.from('users').select().eq('id', user.id).maybeSingle();
    return res;
  }

  @override
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      await _client.from('users').update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      return true;
    } catch (e) {
      // debugPrint('updateProfile error: $e');
      return false;
    }
  }
}
