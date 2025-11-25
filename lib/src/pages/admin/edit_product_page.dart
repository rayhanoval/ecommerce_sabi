import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import 'package:ecommerce_sabi/src/widgets/admin/admin_product_row.dart';
import 'package:ecommerce_sabi/src/pages/admin/edit_product_detail_page.dart';

class EditProductPage extends StatefulWidget {
  const EditProductPage({super.key});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  bool _loading = true;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final list = await ProductService.fetchAllProducts();
    if (!mounted) return;
    setState(() {
      _products = list;
      _loading = false;
    });
  }

  Future<void> _openEdit(Product? product) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProductDetailPage(product: product),
      ),
    );

    if (changed == true) {
      // reload list kalau ada perubahan
      await _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final horizontalPadding =
                isWide ? constraints.maxWidth * 0.15 : 16.0;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBarAndButtons(context, constraints),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white70, thickness: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
                            color: Colors.white,
                            backgroundColor: Colors.black,
                            child: _products.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No products yet',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: _products.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 24),
                                    itemBuilder: (context, index) {
                                      final p = _products[index];
                                      return AdminProductRow(
                                        product: p,
                                        onEdit: () => _openEdit(p),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // COMBINED TOP BAR & BUTTONS (logo, product button and add new product image button)
  Widget _topBarAndButtons(BuildContext context, BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final isWide = maxWidth > 600;

    final logoHeight = isWide ? 56.0 : 40.0;
    final buttonMaxWidth = isWide ? maxWidth * 0.4 : maxWidth * 0.7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo Sabi – di tengah
        Center(
          child: Image.asset(
            'assets/images/sabi_login.png',
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: isWide ? 24 : 16),

        // PRODUCT button – box putih outline, di tengah
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 140,
            maxWidth: buttonMaxWidth,
          ),
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text(
              'PRODUCT',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        SizedBox(height: isWide ? 16 : 12),

        // ADD NEW PRODUCT – image button, juga di tengah, lebarnya mirip PRODUCT
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 140,
            maxWidth: buttonMaxWidth,
          ),
          child: InkWell(
            onTap: () => _openEdit(null),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Image.asset(
                'assets/images/add_new_product_button.png',
                height: logoHeight * 0.7,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
