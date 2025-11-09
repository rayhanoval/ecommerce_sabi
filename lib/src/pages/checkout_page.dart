import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';

class CheckoutPage extends StatelessWidget {
  final Product product;
  final int quantity;

  const CheckoutPage({
    super.key,
    required this.product,
    this.quantity = 1,
  });

  String _formatPrice(double price) {
    final f =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return f.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;

    // responsive paddings and sizes
    final horizontalPad = (w * 0.06).clamp(16.0, 28.0);
    final sectionSpacing = h * 0.028;
    final titleHeight = (w * 0.18).clamp(36.0, 64.0);
    final placeBtnHeight = (w * 0.11).clamp(40.0, 56.0);
    final borderRadius = 8.0;

    final totalPrice = product.price * quantity;

    Widget sectionBox({required Widget child, EdgeInsets? padding}) {
      return Container(
        width: double.infinity,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: child,
      );
    }

    final namePlaceholder = Row(
      children: const [
        Text('Name/Address',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPad),
          child: Column(
            children: [
              // header
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: h * 0.015), // padding atas & bawah
                      child: Center(
                        child: Image.asset(
                          'assets/images/sabi_checkout.png',
                          height: titleHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              SizedBox(height: sectionSpacing * 0.4),

              // scrollable form
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // NAME / ADDRESS box
                      sectionBox(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // small pill label like design
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NAME/ADDRESS',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // multi-line input (fake, you can replace with TextFormField)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.black,
                              ),
                              child: Text(
                                '---------------------------------------',
                                style: TextStyle(
                                    color: Colors.white54, letterSpacing: 2),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sectionSpacing * 0.5),

                      // SHIPPING METHOD box
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Text(
                                'SHIPPING METHOD',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              child: Text(
                                '------------------------------',
                                style: TextStyle(
                                    color: Colors.white54, letterSpacing: 2),
                              ),
                            )
                          ],
                        ),
                      ),

                      SizedBox(height: sectionSpacing * 0.5),

                      // PAYMENT box
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Text(
                                'PAYMENT',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              child: const Text(
                                'CASH ON DELIVERY',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          ],
                        ),
                      ),

                      SizedBox(height: sectionSpacing * 0.6),

                      // ITEM box (image + info)
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Text(
                                'ITEM',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: (w * 0.22).clamp(64.0, 120.0),
                                    height: (w * 0.14).clamp(48.0, 80.0),
                                    color: Colors.grey[900],
                                    child: product.imgUrl.isNotEmpty
                                        ? Image.network(product.imgUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, st) {
                                            return const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white24);
                                          })
                                        : const Icon(Icons.image,
                                            color: Colors.white24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name.toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      Text('1x',
                                          style: const TextStyle(
                                              color: Colors.white70)),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatPrice(product.price),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // total + place order button row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL PRICE:',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text(_formatPrice(totalPrice),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          // place order button asset
                          GestureDetector(
                            onTap: () {
                              // implement actual place order logic here
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Order placed (mock)')));
                            },
                            child: Image.asset(
                              'assets/images/place_order_button.png',
                              height: placeBtnHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: h * 0.06),
                    ],
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
