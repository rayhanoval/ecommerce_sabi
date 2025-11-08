import 'package:ecommerce_sabi/src/pages/login_page.dart';
import 'package:ecommerce_sabi/src/pages/product_list_page.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil tinggi dan lebar layar
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.11), // jarak atas proporsional

            // ===== Logo SB =====
            Center(
              child: CircleAvatar(
                backgroundImage:
                    const AssetImage('assets/images/sb_symbol.png'),
                backgroundColor: Colors.black,
                radius: screenWidth * 0.4, // radius logo proporsional
              ),
            ),

            // ===== Jarak antara logo dan tombol login =====
            SizedBox(height: screenHeight * 0.20),

            // ===== Tombol Login =====
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

            // ===== Tombol Start Exploring =====
            IconButton(
              icon: Image.asset(
                'assets/images/button.png',
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

            //SizedBox(height: screenHeight * 0.02), // jarak bawah
          ],
        ),
      ),
    );
  }
}
