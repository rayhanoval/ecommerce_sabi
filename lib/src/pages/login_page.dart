import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'product_list_page.dart'; // ganti sesuai page utama app kamu

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return 'Email wajib diisi';
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(v)) return 'Email tidak valid';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password wajib diisi';
    if (v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _loading = false);

      if (res.session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProductListPage()),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content:
                Text('Login gagal — cek email/password atau konfirmasi email.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Login gagal — ${e.message}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Login gagal — ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
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
                  mainAxisSize: MainAxisSize.min,
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
                        children: [
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(color: Colors.white54),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white38),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                            validator: _emailValidator,
                          ),
                          SizedBox(height: s.height * 0.025),
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.white54),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white38),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                            validator: _passwordValidator,
                          ),
                          SizedBox(height: s.height * 0.02),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: implement forgot password flow
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(40, 20),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: s.width * 0.034,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: s.height * 0.04),
                        ],
                      ),
                    ),
                    _loading
                        ? SizedBox(
                            height: s.height * 0.08,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterPage()),
                            );
                          },
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
