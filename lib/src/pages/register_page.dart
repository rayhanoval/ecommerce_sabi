import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // VALIDASI
  String? _usernameValidator(String? v) =>
      (v == null || v.isEmpty) ? 'Username is required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(v)) return 'Invalid email format';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _confirmValidator(String? v) {
    if (v == null || v.isEmpty) return 'Confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authRepositoryProvider).register(
          email,
          password,
          username: username, // PENTING: masuk ke kolom username
        );

    setState(() => _loading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification link sent to your email."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.greenAccent,
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration failed — email might be registered."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
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
                          // USERNAME FIELD
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Username',
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
                            validator: _usernameValidator,
                          ),
                          SizedBox(height: s.height * 0.025),

                          // EMAIL
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

                          // PASSWORD
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
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
                          SizedBox(height: s.height * 0.025),

                          // CONFIRM PASSWORD
                          TextFormField(
                            controller: _confirmController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Confirm Password',
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
                            validator: _confirmValidator,
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
                                color: Colors.white,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _register,
                            child: Image.asset(
                              'assets/images/register_button.png',
                              height: s.height * 0.08,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ],
                ),
              ),
            ),

            // BACK BUTTON
            Positioned(
              top: s.height * 0.02,
              left: s.width * 0.02,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
