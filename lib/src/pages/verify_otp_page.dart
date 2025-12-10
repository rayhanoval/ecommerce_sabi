import 'dart:async';
import 'package:ecommerce_sabi/src/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_repository.dart';
import 'update_password_page.dart';

enum VerificationType { recovery, signup }

class VerifyOtpPage extends ConsumerStatefulWidget {
  final String email;
  final String? username; // Added username parameter
  final VerificationType type;

  const VerifyOtpPage({
    super.key,
    required this.email,
    required this.type,
    this.username,
  });

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _start = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() => _start--);
      }
    });
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (widget.type == VerificationType.recovery) {
        await repo.resendRecoveryOtp(widget.email);
      } else {
        await repo.resendSignupOtp(widget.email);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent again')),
      );
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success = false;
      final repo = ref.read(authRepositoryProvider);

      if (widget.type == VerificationType.recovery) {
        success = await repo.verifyRecoveryOtp(
            widget.email, _otpController.text.trim());
      } else {
        // Pass username for signup verification
        success = await repo.verifySignupOtp(
          widget.email,
          _otpController.text.trim(),
          username: widget.username,
        );
      }

      if (success) {
        if (!mounted) return;

        if (widget.type == VerificationType.recovery) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UpdatePasswordPage()),
          );
        } else {
          // Signup success -> Login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account verified! Please login.')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.width * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: s.height * 0.02),
              const Text(
                'Enter OTP Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We have sent a verification code to ${widget.email}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: s.height * 0.05),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _otpController,
                  style: const TextStyle(color: Colors.white, letterSpacing: 4),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '000000',
                    hintStyle:
                        TextStyle(color: Colors.white38, letterSpacing: 4),
                    counterText: "",
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Code is required';
                    if (v.length < 6) return 'Enter 6 digit code';
                    return null;
                  },
                ),
              ),
              SizedBox(height: s.height * 0.05),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'VERIFY',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: (_canResend && !_isLoading) ? _resendCode : null,
                  child: Text(
                    _canResend ? 'Resend Code' : 'Resend Code (${_start}s)',
                    style: TextStyle(
                      color: _canResend ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
