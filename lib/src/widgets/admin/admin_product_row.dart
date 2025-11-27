// lib/widgets/admin_product_row.dart
import 'package:flutter/material.dart';
import 'package:ecommerce_sabi/src/models/product.dart';

class AdminProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminProductRow({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  String _rupiah(double value) {
    final str = value.toInt().toString();
    return str.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IMAGE
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: isWide ? 150 : 120,
            height: isWide ? 90 : 75,
            child: product.imgUrl.isNotEmpty
                ? Image.network(
                    product.imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white12,
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.white54),
                    ),
                  )
                : Container(
                    color: Colors.white12,
                    child: const Icon(Icons.image, color: Colors.white54),
                  ),
          ),
        ),

        const SizedBox(width: 12),

        // NAME + PRICE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'RP.${_rupiah(product.price)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // STOCK + EDIT BUTTON
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'STOCK = ${product.stock}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: isWide ? 90 : 70,
              child: ElevatedButton(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'EDIT',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: isWide ? 90 : 70,
              child: ElevatedButton(
                onPressed: onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'DELETE',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
