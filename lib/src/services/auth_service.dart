import 'package:supabase_flutter/supabase_flutter.dart';

class AuthException implements Exception {
  final String code;
  final String message;
  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}

class AuthService {
  static final _supabase = Supabase.instance.client;

  /// Register user and create a profiles row with separate full_name and username fields.
  /// Returns true on success, false on failure.
  static Future<bool> register(
    String email,
    String password, {
    String? fullName,
    String? username,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) return false;

      // ensure username: if not provided, generate fallback
      String finalUsername = username?.trim() ?? '';
      if (finalUsername.isEmpty) {
        finalUsername =
            'user_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      }

      // try insert profile row
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'full_name': fullName ?? '',
        'username': finalUsername,
        'avatar_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } on AuthApiException catch (e) {
      // supabase auth error
      print('Auth register error: ${e.message}');
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  /// Login
  static Future<bool> login(String email, String password) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
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

  /// Logout
  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Is logged in
  static bool isLoggedIn() {
    return _supabase.auth.currentSession != null;
  }

  /// Get current profile
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final res = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return res;
  }

  /// Update profile (helper)
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    try {
      await _supabase.from('profiles').update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      return true;
    } catch (e) {
      print('updateProfile error: $e');
      return false;
    }
  }
}
