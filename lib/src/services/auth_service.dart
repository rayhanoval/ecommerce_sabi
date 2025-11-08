// lib/services/auth_service.dart
class AuthService {
  static Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2)); // simulasi network
    if (email == "admin" && password == "123") return true;
    return false;
  }
}