// lib/widgets/product/card.dart
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String imgUrl;
  final String name;
  final double price;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.imgUrl,
    required this.name,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // font lebih proporsional
    final nameStyle = TextStyle(
      color: Colors.white,
      fontSize: 14, // name lebih besar
      height: 1.2,
      fontWeight: FontWeight.w600,
    );
    final priceStyle = TextStyle(
      color: Colors.white,
      fontSize: 11, // price lebih kecil
      fontWeight: FontWeight.bold,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  imgUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, st) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: nameStyle,
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
              style: priceStyle,
            ),
          ],
        ),
      ),
    );
  }
}
