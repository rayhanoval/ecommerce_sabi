import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../login_page.dart';
import 'checkout_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce_sabi/src/widgets/product/product_rating_preview.dart';
import 'package:ecommerce_sabi/src/services/product_image_service.dart';

class ProductDetailPage extends StatefulWidget {
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

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  List<String> _allImages = [];
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  late final ProductImageService _imageService;

  @override
  void initState() {
    super.initState();
    _imageService = ProductImageService(Supabase.instance.client);
    _loadImages();
  }

  Future<void> _loadImages() async {
    final additionalImages =
        await _imageService.fetchProductImages(widget.product.id);

    setState(() {
      // Start with main image, then add additional images
      _allImages = [
        if (widget.product.imgUrl.isNotEmpty) widget.product.imgUrl,
        ...additionalImages,
      ];
    });
  }

  Future<void> _refreshPage() async {
    await _loadImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
    final priceText = _formatPrice(widget.product.price);
    final descLines = _descriptionLines(widget.product.description);

    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    // responsive size setup
    final horizontalPadding = screenWidth * 0.06;
    final imageMaxHeight =
        (screenHeight * 0.28).clamp(180.0, 400.0); // smaller product image
    final productImageWidth = screenWidth * 0.7; // narrower width

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
              child: RefreshIndicator(
                onRefresh: _refreshPage,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(children: [
                    // PRODUCT IMAGE CAROUSEL
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: productImageWidth,
                            maxHeight: imageMaxHeight,
                          ),
                          child: _allImages.isEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    color: Colors.grey[900],
                                    height: imageMaxHeight,
                                    child: const Center(
                                      child: Icon(Icons.image,
                                          color: Colors.white24, size: 48),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: PageView.builder(
                                          controller: _pageController,
                                          onPageChanged: (index) {
                                            setState(() {
                                              _currentImageIndex = index;
                                            });
                                          },
                                          itemCount: _allImages.length,
                                          itemBuilder: (context, index) {
                                            return Image.network(
                                              _allImages[index],
                                              fit: BoxFit.cover,
                                              width: productImageWidth,
                                              height: imageMaxHeight,
                                              errorBuilder: (c, e, st) =>
                                                  Container(
                                                color: Colors.grey[900],
                                                child: const Center(
                                                  child: Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.white24,
                                                      size: 48),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    if (_allImages.length > 1) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          _allImages.length,
                                          (index) => Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _currentImageIndex == index
                                                  ? Colors.white
                                                  : Colors.white38,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
                            widget.product.name.toUpperCase(),
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
                          if (widget.product.stock > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Stock: ${widget.product.stock}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: gapTitleButtons),

                    // BUTTONS
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: widget.product.stock == 0
                          ? Container(
                              height: buttonHeight,
                              alignment: Alignment.center,
                              child: const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                // BUY NOW / LOGIN TO BUY NOW
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final session = Supabase
                                          .instance.client.auth.currentSession;
                                      final loggedIn = session != null;

                                      if (!loggedIn) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginPage()),
                                        );
                                        return;
                                      }

                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CheckoutPage(
                                              product: widget.product,
                                              quantity: 1),
                                        ),
                                      );
                                    },
                                    child: Image.asset(
                                      widget.isLoggedIn
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
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),

                                // ADD TO BAG
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (widget.onAddToBag != null) {
                                        widget.onAddToBag!();
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Added to bag (mock)')),
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
                            color: Colors.white.withValues(alpha: 0.9),
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
                    ProductRatingPreview(product: widget.product),
                    SizedBox(height: screenHeight * 0.06),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
