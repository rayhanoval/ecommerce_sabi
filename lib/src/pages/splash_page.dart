import 'package:ecommerce_sabi/src/pages/login_page.dart';
import 'package:ecommerce_sabi/src/pages/product_list_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.11),

            // Logo SB
            Center(
              child: CircleAvatar(
                backgroundImage:
                    const AssetImage('assets/images/sb_symbol.png'),
                backgroundColor: Colors.black,
                radius: screenWidth * 0.4,
              ),
            ),

            SizedBox(height: screenHeight * 0.20),

            // Tombol LOGIN/SIGNUP → tampil hanya kalau belum login
            if (!isLoggedIn)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
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

            // Tombol Start Exploring (tetap ada)
            IconButton(
              icon: Image.asset(
                'assets/images/start_exploring_button.png',
                width: screenWidth * 0.7,
                height: screenHeight * 0.15,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductListPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
