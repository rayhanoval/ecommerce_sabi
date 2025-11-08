import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'product_list_page.dart';
import 'register_page.dart';

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

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _loading = true);

      bool success = await AuthService.login(
        _emailController.text,
        _passwordController.text,
      );

      setState(() => _loading = false);

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProductListPage(isLoggedIn: true),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login gagal")),
        );
      }
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
            // Konten utama
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: s.width * 0.08),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // logo sabi
                    Image.asset(
                      'assets/images/sabi_login.png',
                      height: s.height * 0.07,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: s.height * 0.05),

                    // form login
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
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Email wajib diisi'
                                : null,
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
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Password wajib diisi'
                                : null,
                          ),
                          SizedBox(height: s.height * 0.02),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(40, 20),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
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

                    // tombol login
                    _loading
                        ? SizedBox(
                            height: s.height * 0.08,
                            child: const Center(
                              child:
                                  CircularProgressIndicator(color: Colors.white),
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

                    // teks "Don't have an account? Sign up"
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

            // Tombol back di pojok kiri atas
            Positioned(
              top: s.height * 0.02,
              left: s.width * 0.02,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
