import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);
  Future<bool> verifyRecoveryOtp(String email, String token);
  Future<bool> verifySignupOtp(String email, String token, {String? username});
  Future<void> resendSignupOtp(String email);
  Future<void> resendRecoveryOtp(String email);
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
  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();

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

      // NOTE: Data user akan di-insert ke table 'users' SETELAH verifikasi OTP berhasil
      // di method verifySignupOtp.

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

      if (res.session != null && res.user != null) {
        // Generate, Store, and Update Session ID
        final sessionId = _uuid.v4();
        await _storage.write(key: 'session_id', value: sessionId);

        try {
          await _client.from('users').update({
            'active_session_id': sessionId,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', res.user!.id);
        } catch (_) {}
      }

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
    await _storage.delete(key: 'session_id');
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

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException(
          'RESET_PASSWORD_FAILED', 'Gagal mengirim email reset password');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AuthException('UPDATE_PASSWORD_FAILED', 'Gagal update password');
    }
  }

  @override
  Future<bool> verifyRecoveryOtp(String email, String token) async {
    try {
      final res = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      return res.session != null;
    } catch (e) {
      throw AuthException(
          'VERIFY_OTP_FAILED', 'Kode OTP salah atau kadaluarsa');
    }
  }

  @override
  Future<bool> verifySignupOtp(String email, String token,
      {String? username}) async {
    try {
      final res = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );

      final session = res.session;
      final user = res.user;

      // Jika verifikasi sukses dan kita punya data user, baru insert ke DB public.users
      if (session != null && user != null && username != null) {
        try {
          final sessionId = _uuid.v4();
          await _storage.write(key: 'session_id', value: sessionId);

          await _client.from('users').insert({
            'id': user.id,
            'email': email,
            'username': username,
            'avatar_url': null,
            'active_session_id': sessionId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Jika insert gagal (misal duplikat yg lolos), bisa dianggap gagal atau warning
          // Tapi auth session sudah terbentuk.
          // Idealnya kita lempar error atau handle gracefully.
          // Disini kita biarkan, user sudah login di auth.
        }
      }

      return session != null;
    } catch (e) {
      throw AuthException(
          'VERIFY_OTP_FAILED', 'Kode OTP salah atau kadaluarsa');
    }
  }

  @override
  Future<void> resendSignupOtp(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw AuthException(
          'RESEND_FAILED', 'Gagal mengirim ulang kode OTP signup');
    }
  }

  @override
  Future<void> resendRecoveryOtp(String email) async {
    // Untuk recovery, kita gunakan resetPasswordForEmail lagi
    // karena otp type recovery biasa di-trigger lewat situ
    return resetPassword(email);
  }
}
