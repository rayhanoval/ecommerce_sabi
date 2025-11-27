import 'package:ecommerce_sabi/src/pages/admin/admin_homepage.dart'
    show AdminHomepage;
import 'package:ecommerce_sabi/src/pages/login_page.dart';
import 'package:ecommerce_sabi/src/pages/user/product_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce_sabi/src/pages/admin/edit_product_page.dart';
import '../services/auth_repository.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    // cek session Supabase
    final session = Supabase.instance.client.auth.currentSession;
    setState(() => isLoggedIn = session != null);

    // listen auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        setState(() => isLoggedIn = true);
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() => isLoggedIn = false);
      }
    });
  }

  Future<void> _handleStartExploring(BuildContext context) async {
    if (!isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductListPage()),
      );
      return;
    }

    // get profile data including role
    final profile = await ref.read(authRepositoryProvider).getCurrentProfile();
    final role = profile?['role']?.toString().toLowerCase() ?? '';

    if (role == 'admin' || role == 'owner') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomepage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductListPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            return Column(
              children: [
                SizedBox(height: screenHeight * 0.05),

                // Logo SB
                Flexible(
                  flex: 5,
                  child: Center(
                    child: CircleAvatar(
                      backgroundImage:
                          const AssetImage('assets/images/sb_symbol.png'),
                      backgroundColor: Colors.black,
                      radius: screenWidth * 0.4,
                    ),
                  ),
                ),

                // Spacer dorong tombol ke bawah tapi lebih pendek supaya Start Exploring tidak terlalu rendah
                const Spacer(flex: 1),

                // Tombol LOGIN/SIGNUP + Start Exploring
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isLoggedIn)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.15,
                            vertical: screenHeight * 0.02,
                          ),
                        ),
                        child: Text(
                          "LOGIN/SIGNUP",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                    if (!isLoggedIn)
                      SizedBox(height: 2), // tetap mepet LOGIN/SIGNUP

                    // Tombol Start Exploring → selalu ada, naik sedikit ke atas
                    IconButton(
                      icon: Image.asset(
                        'assets/images/start_exploring_button.png',
                        width: screenWidth * 0.7,
                        height: screenHeight * 0.15,
                      ),
                      onPressed: () async {
                        await _handleStartExploring(context);
                      },
                    ),
                  ],
                ),

                SizedBox(
                    height: screenHeight *
                        0.08), // padding bawah agar tidak terlalu ke bawah
              ],
            );
          },
        ),
      ),
    );
  }
}
