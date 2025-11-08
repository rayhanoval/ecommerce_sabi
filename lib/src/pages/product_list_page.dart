import 'package:flutter/material.dart';
import '../widgets/product/card.dart';
import '../widgets/common/grid.dart';
import '../services/products_service.dart';
import '../pages/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class ProductListPage extends StatefulWidget {
  final bool isLoggedIn;

  const ProductListPage({super.key, this.isLoggedIn = false});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late bool isLoggedIn;

  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.isLoggedIn;

    // Pastikan status bar hitam dan ikon terang
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  String _getName(dynamic item) {
    if (item == null) return '';
    if (item is Map) return item['name']?.toString() ?? '';
    try {
      return item.name?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  double _getPrice(dynamic item) {
    if (item == null) return 0.0;
    if (item is Map) {
      final p = item['price'];
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
    if (item is Map) return item['imgUrl'] ?? '';
    try {
      return item.imgUrl?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: false, // supaya body tidak overlay status bar
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),
        toolbarHeight: 80,
        flexibleSpace: Container(
          color: Colors.black, // pastikan hitam solid
        ),
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
              onPressed: () {
                // navigasi ke profile page
              },
              icon: const Icon(Icons.person_outline),
              color: Colors.white70,
              iconSize: 20,
              padding: const EdgeInsets.only(right: 16),
              tooltip: 'Profile',
            ),
            IconButton(
              onPressed: () {
                // navigasi ke cart page
              },
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

                  return ProductCard(
                    imgUrl: imgUrl,
                    name: name,
                    price: price,
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
