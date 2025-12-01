import 'package:ecommerce_sabi/src/pages/admin/admin_homepage.dart';
import 'package:ecommerce_sabi/src/pages/user/product_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../services/auth_repository.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailOrUsernameController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailOrUsernameValidator(String? v) {
    if (v == null || v.isEmpty) return 'Email or username is required';
    return null; // boleh format apapun
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _emailError = null;
      _passwordError = null;
    });

    final input = _emailOrUsernameController.text.trim();
    final password = _passwordController.text;

    String emailToLogin = input;

    try {
      // 🔥 Jika user input username (tidak ada '@')
      if (!input.contains("@")) {
        // lookup ke table users
        final res = await Supabase.instance.client
            .from('users')
            .select('email')
            .eq('username', input)
            .maybeSingle();

        if (res == null) {
          setState(() {
            _loading = false;
            _emailError = "Username not found";
          });
          return;
        }

        emailToLogin = res['email'];
      }

      // 🔥 Setelah dapat email → login
      final success =
          await ref.read(authRepositoryProvider).login(emailToLogin, password);

      setState(() => _loading = false);

      if (success) {
        // Fetch user's role from profile
        final profile =
            await ref.read(authRepositoryProvider).getCurrentProfile();
        final role = profile?['role'] ?? 'user';

        if (!mounted) return;

        if (role == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProductListPage()),
          );
        } else if (role == 'owner' || role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomepage()),
          );
        } else {
          // Default fallback
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProductListPage()),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _loading = false;

        if (e.code == 'USER_NOT_FOUND') {
          _emailError = 'Account not found';
        } else if (e.code == 'WRONG_CREDENTIALS') {
          _passwordError = 'Incorrect email/username or password';
        } else {
          _passwordError = 'An error occurred, try again';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _passwordError = 'Unexpected error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: s.width * 0.08),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/sabi_login.png',
                      height: s.height * 0.07,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: s.height * 0.05),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔥 FIELD BARU: Email or Username
                          TextFormField(
                            controller: _emailOrUsernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Email or Username',
                              hintStyle: TextStyle(color: Colors.white54),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white38),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            validator: _emailOrUsernameValidator,
                          ),

                          if (_emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _emailError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          SizedBox(height: s.height * 0.025),

                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white38),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: _passwordValidator,
                          ),

                          if (_passwordError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _passwordError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          SizedBox(height: s.height * 0.02),
                        ],
                      ),
                    ),
                    _loading
                        ? SizedBox(
                            height: s.height * 0.08,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white)),
                          )
                        : GestureDetector(
                            onTap: _login,
                            child: Image.asset(
                              'assets/images/login_button.png',
                              height: s.height * 0.08,
                              fit: BoxFit.contain,
                            ),
                          ),
                    SizedBox(height: s.height * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: s.width * 0.035,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterPage()),
                          ),
                          child: Text(
                            "Sign up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: s.width * 0.035,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
