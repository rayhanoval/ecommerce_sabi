import 'package:flutter/material.dart';
import '../pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800)); // simulasi request
    setState(() => _loading = false);

    // Setelah sukses registrasi, navigasi ke ProductListPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    final horizontalPadding = s.width * 0.08;
    final logoHeight = s.height * 0.07;
    final fieldGap = s.height * 0.025;
    final buttonHeight = s.height * 0.08;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'assets/images/sabi_login.png',
                  height: logoHeight,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: s.height * 0.05),

                // Form registrasi
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Full Name',
                          hintStyle: TextStyle(color: Colors.white54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Nama wajib diisi'
                            : null,
                      ),

                      SizedBox(height: fieldGap),

                      // Email
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
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Email wajib diisi'
                            : null,
                      ),

                      SizedBox(height: fieldGap),

                      // Password
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
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password wajib diisi';
                          }
                          if (v.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: fieldGap),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          hintStyle: const TextStyle(color: Colors.white54),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }
                          if (v != _passwordController.text) {
                            return 'Password tidak cocok';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: s.height * 0.04),
                    ],
                  ),
                ),

                // Tombol register
                _loading
                    ? SizedBox(
                        height: buttonHeight,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : GestureDetector(
                        onTap: _register,
                        child: Image.asset(
                          'assets/images/register_button.png',
                          height: buttonHeight,
                          fit: BoxFit.contain,
                        ),
                      ),

                SizedBox(height: s.height * 0.03),

                // Tambahan: teks login balik ke LoginPage
                // Teks "Already have an account? Login"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: s.width * 0.035,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: Text(
                        "Login",
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

                SizedBox(height: s.height * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
