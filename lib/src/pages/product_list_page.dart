// lib/pages/product_list_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/product/card.dart';
import '../widgets/common/grid.dart';
import '../services/products_service.dart';
import '../pages/login_page.dart';
import '../pages/product_detail_page.dart';
import '../models/product.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    // Cek session Supabase saat halaman dibuka
    final session = Supabase.instance.client.auth.currentSession;
    isLoggedIn = session != null;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    // Listen perubahan auth (login/logout)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        setState(() => isLoggedIn = true);
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() => isLoggedIn = false);
      }
    });
  }

  String _getName(dynamic item) {
    if (item == null) return '';
    if (item is Map)
      return item['name']?.toString() ?? item['title']?.toString() ?? '';
    try {
      return item.name?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  double _getPrice(dynamic item) {
    if (item == null) return 0.0;
    if (item is Map) {
      final p = item['price'] ?? item['harga'] ?? item['amount'];
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p) ?? 0.0;
      return 0.0;
    }
    try {
      final p = item.price;
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p) ?? 0.0;
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  String _getImageUrl(dynamic item) {
    if (item == null) return '';
    if (item is Map)
      return (item['imgUrl'] ?? item['img_url'] ?? item['image'] ?? '')
          .toString();
    try {
      return item.imgUrl?.toString() ?? item.image?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  Product _toProduct(dynamic item) {
    if (item == null)
      return Product(
          id: '0',
          name: '',
          price: 0,
          description: '',
          stock: 0,
          rating: 0,
          isActive: false,
          imgUrl: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now());

    if (item is Product) return item;

    if (item is Map<String, dynamic>) {
      final map = Map<String, dynamic>.from(item);
      return Product.fromJson(map);
    }

    // fallback minimal
    return Product(
      id: '0',
      name: _getName(item),
      price: _getPrice(item),
      description: '',
      stock: 0,
      rating: 0,
      isActive: false,
      imgUrl: _getImageUrl(item),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

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
        flexibleSpace: Container(color: Colors.black),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Image.asset(
            'assets/images/sabi_catalog.png',
            width: screenWidth * 0.38,
            height: screenWidth * 0.14,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: false,
        actions: [
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                  if (result == true) {
                    setState(() => isLoggedIn = true);
                  }
                },
                child: Text(
                  'LOGIN/SIGNUP',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (isLoggedIn) ...[
            IconButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                setState(() => isLoggedIn = false);
              },
              icon: const Icon(Icons.logout_outlined),
              color: Colors.white70,
              iconSize: 20,
              padding: const EdgeInsets.only(right: 16),
              tooltip: 'Logout',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.person_outline),
              color: Colors.white70,
              iconSize: 20,
              padding: const EdgeInsets.only(right: 16),
              tooltip: 'Profile',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_outlined),
              color: Colors.white70,
              iconSize: 20,
              padding: const EdgeInsets.only(right: 16),
              tooltip: 'Cart',
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<List<dynamic>>(
            future: loadProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No products found"));
              }

              final products = snapshot.data!;
              return GenericGrid<dynamic>(
                items: products,
                responsive: false,
                columns: 2,
                spacing: 24,
                childAspectRatio: 0.6,
                padding: EdgeInsets.zero,
                itemBuilder: (context, item, index) {
                  final name = _getName(item);
                  final price = _getPrice(item);
                  final imgUrl = _getImageUrl(item);

                  return GestureDetector(
                    onTap: () {
                      final productModel = _toProduct(item);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(
                            product: productModel,
                            isLoggedIn: isLoggedIn,
                          ),
                        ),
                      );
                    },
                    child: ProductCard(
                      imgUrl: imgUrl,
                      name: name,
                      price: price,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
