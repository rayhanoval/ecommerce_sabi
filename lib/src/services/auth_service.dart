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

  /// Register with email/password, then save full name in profiles
  static Future<bool> register(String email, String password,
      {String? fullName}) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = res.user;

      if (user != null) {
        // save full name in profiles table
        if (fullName != null && fullName.isNotEmpty) {
          await _supabase.from('profiles').insert({
            'id': user.id,
            'full_name': fullName,
            'email': email,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  /// Login with email/password — throws AuthException on specific error
  static Future<bool> login(String email, String password) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.session != null;
    } on AuthApiException catch (e) {
      // handle error dari Supabase
      final msg = e.message.toLowerCase();

      if (msg.contains('invalid login credentials')) {
        // Supabase tidak bisa bedakan email/password salah
        // jadi kita bisa lempar pesan umum
        throw AuthException('WRONG_CREDENTIALS', 'Email atau password salah');
      } else if (msg.contains('user not found')) {
        throw AuthException('USER_NOT_FOUND', 'Email belum terdaftar');
      } else {
        throw AuthException('UNKNOWN', e.message);
      }
    } catch (e) {
      print('Login error: $e');
      throw AuthException('UNKNOWN', 'Terjadi kesalahan tak terduga');
    }
  }

  /// Logout
  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Check if logged in
  static bool isLoggedIn() {
    return _supabase.auth.currentSession != null;
  }
}
