import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../pages/login_page.dart';
import '../pages/checkout_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce_sabi/src/widgets/product/product_rating_section.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final bool isLoggedIn;
  final VoidCallback? onAddToBag;
  final VoidCallback? onBuyNow;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.isLoggedIn = false,
    this.onAddToBag,
    this.onBuyNow,
  });

  String _formatPrice(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatter.format(value);
  }

  List<String> _descriptionLines(String description) {
    if (description.trim().contains('\n')) {
      return description
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (description.contains('•')) {
      return description
          .split('•')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      return description
          .split('.')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceText = _formatPrice(product.price);
    final descLines = _descriptionLines(product.description);

    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    // responsive size setup
    final horizontalPadding = screenWidth * 0.06;
    final imageMaxHeight =
        (screenHeight * 0.28).clamp(180.0, 400.0); // smaller product image
    final productImageWidth = screenWidth * 0.7; // narrower width
    final logoHeight = (screenWidth * 0.09).clamp(20.0, 36.0); // smaller logo
    final buttonHeight = (screenWidth * 0.1).clamp(36.0, 56.0);
    final gapTitleButtons = screenHeight * 0.03;
    final gapButtonsDescription = screenHeight * 0.04;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  12, 16, 12, 20), // tambah jarak atas & bawah
              child: Row(
                children: [
                  // back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20,
                  ),

                  // logo SABI (kecil + lebih ke tengah)
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/sabi_putih.png',
                        height: (screenWidth * 0.1)
                            .clamp(22.0, 38.0), // lebih kecil
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(width: 48), // spacer kanan
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(children: [
                  // PRODUCT IMAGE (smaller & centered)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: productImageWidth,
                          maxHeight: imageMaxHeight,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product.imgUrl.isNotEmpty
                              ? Image.network(
                                  product.imgUrl,
                                  fit: BoxFit.cover,
                                  width: productImageWidth,
                                  height: imageMaxHeight,
                                  errorBuilder: (c, e, st) => Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported,
                                          color: Colors.white24, size: 48),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[900],
                                  height: imageMaxHeight,
                                  child: const Center(
                                    child: Icon(Icons.image,
                                        color: Colors.white24, size: 48),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TITLE + PRICE
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        Text(
                          product.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          priceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: gapTitleButtons),

                  // BUTTONS
                  // BUTTONS
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Row(
                      children: [
                        // BUY NOW / LOGIN TO BUY NOW
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final session =
                                  Supabase.instance.client.auth.currentSession;
                              final loggedIn = session != null;

                              if (!loggedIn) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginPage()),
                                );
                                return;
                              }

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CheckoutPage(
                                      product: product, quantity: 1),
                                ),
                              );
                            },
                            child: Image.asset(
                              isLoggedIn
                                  ? 'assets/images/buy_now.png'
                                  : 'assets/images/login_buy_now.png',
                              height: buttonHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // VERTICAL BAR
                        Container(
                          width: 2,
                          height: buttonHeight * 0.9,
                          margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03),
                          color: Colors.white.withOpacity(0.3),
                        ),

                        // ADD TO BAG
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (onAddToBag != null) {
                                onAddToBag!();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Added to bag (mock)')),
                                );
                              }
                            },
                            child: Image.asset(
                              'assets/images/add_to_bag.png',
                              height: buttonHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: gapButtonsDescription),

                  // DESCRIPTION
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'DESCRIPTION:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: descLines.map((line) {
                        final display = '•  $line';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            display,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  ProductRatingSection(product: product),
                  SizedBox(height: screenHeight * 0.06),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
