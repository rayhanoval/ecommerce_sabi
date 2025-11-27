import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ecommerce_sabi/src/pages/edit_profile_page.dart';
import 'package:ecommerce_sabi/src/pages/splash_page.dart';
import 'package:ecommerce_sabi/src/pages/admin/edit_product_page.dart'; // <- pastikan file & class ini ada
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';
import '../../services/product_repository.dart';
import '../../services/auth_repository.dart';

class AdminHomepage extends ConsumerStatefulWidget {
  const AdminHomepage({super.key});

  @override
  ConsumerState<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends ConsumerState<AdminHomepage> {
  List<Product> products = [];
  bool isLoading = true;
  String _role = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() async {
    final profile = await ref.read(authRepositoryProvider).getCurrentProfile();
    final role = profile?['role']?.toString().toLowerCase() ?? '';
    final repo = ref.read(productRepositoryProvider);
    final fetched = await repo.fetchLimitedProduct();
    setState(() {
      _role = role;
      products = fetched;
      isLoading = false;
    });
  }

  bool isLoggedIn = true; // TODO: Initialize based on actual auth state

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 80,
        leadingWidth: screenWidth * 0.35, // <- ini yg bikin logo bisa besar
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/images/sabi_catalog.png',
            fit: BoxFit.contain,
          ),
        ),
        titleSpacing: 0, // biar ga ada extra space
        actions: [
          IconButton(
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
              if (res == true) {
                // optionally refresh UI
              }
            },
            icon: const Icon(Icons.person_outline),
            color: Colors.white70,
            iconSize: 20,
            padding: const EdgeInsets.only(right: 16),
            tooltip: 'Profile',
          ),
          if (isLoggedIn) ...[
            IconButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                setState(() => isLoggedIn = false);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashPage()),
                );
              },
              icon: const Icon(Icons.logout_outlined),
              color: Colors.white70,
              iconSize: 20,
              padding: const EdgeInsets.only(right: 16),
              tooltip: 'Logout',
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_role != 'admin') ...[
                // "YOUR PRODUCT" button-style
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Text(
                    'YOUR PRODUCT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // list produk
                if (isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  ...products.map((product) => Column(
                        children: [
                          _ProductTile(product: product),
                          const SizedBox(height: 16),
                        ],
                      )),
                // tombol VIEW ALL below second product, aligned right
                if (!isLoading && products.length >= 2)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 150,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProductPage(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: const Text(
                          'VIEW ALL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;

  const _ProductTile({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPrice =
        NumberFormat.currency(locale: 'id_ID', symbol: 'RP.', decimalDigits: 0)
            .format(product.price);
    final quantity = '${product.stock}x';

    return Row(
      children: [
        // gambar produk
        Container(
          width: 80,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            image: DecorationImage(
              image: NetworkImage(product.imgUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // nama & harga
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedPrice,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        // qty di kanan
        Text(
          quantity,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
