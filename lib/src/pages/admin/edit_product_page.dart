import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../services/product_repository.dart';
import '../../services/auth_repository.dart';
import 'package:ecommerce_sabi/src/widgets/admin/admin_product_row.dart';
import 'package:ecommerce_sabi/src/pages/admin/edit_product_detail_page.dart';

class EditProductPage extends ConsumerStatefulWidget {
  const EditProductPage({super.key});

  @override
  ConsumerState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends ConsumerState<EditProductPage> {
  bool _loading = true;
  List<Product> _products = [];
  String _role = '';
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final profile = await ref.read(authRepositoryProvider).getCurrentProfile();
    final role = profile?['role']?.toString().toLowerCase() ?? '';
    final list = await ref.read(productRepositoryProvider).fetchAllProducts();

    if (!mounted) return;
    setState(() {
      _role = role;
      _products = list;
      _loading = false;
    });
  }

  Future<void> _loadProducts() async {
    final list = await ref.read(productRepositoryProvider).fetchAllProducts();
    if (!mounted) return;
    setState(() {
      _products = list;
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success =
          await ref.read(productRepositoryProvider).deleteProduct(product.id);
      if (success) {
        await _loadProducts();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete product')),
          );
        }
      }
    }
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
                  const SizedBox(height: 8),
                  if (_role != 'admin') ...[
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
                                      itemCount: _showAll
                                          ? _products.length
                                          : (_products.length > 5
                                              ? 5
                                              : _products.length),
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 24),
                                      itemBuilder: (context, index) {
                                        final p = _products[index];
                                        return AdminProductRow(
                                          product: p,
                                          onEdit: () => _openEdit(p),
                                          onDelete: () => _deleteProduct(p),
                                        );
                                      },
                                    ),
                            ),
                    ),
                    if (!_showAll && _products.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: TextButton(
                            onPressed: () => setState(() => _showAll = true),
                            child: Text(
                              'VIEW ALL',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _topBarAndButtons(BuildContext context, BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final isWide = maxWidth > 600;

    final logoHeight = isWide ? 65.0 : 50.0;

    // Product button diperkecil sedikit dari versi sebelumnya
    final productButtonWidth = isWide ? 120.0 : 105.0;
    final productButtonHeight = isWide ? 34.0 : 30.0;

    final addButtonSize = isWide ? 30.0 : 26.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // LOGO
        Image.asset(
          'assets/images/sabi_login.png',
          height: logoHeight,
          fit: BoxFit.contain,
        ),

        // SPACE antara LOGO dan PRODUCT (ditambah sedikit)
        SizedBox(height: isWide ? 38 : 50),

        // PRODUCT BUTTON (lebih kecil)
        SizedBox(
          width: productButtonWidth,
          height: productButtonHeight,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 1.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'PRODUCT',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 1.7,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ),

        // PRODUCT → ADD NEW PRODUCT (rapat)
        SizedBox(height: isWide ? 10 : 8),

        // ADD NEW PRODUCT icon button
        IconButton(
          onPressed: () => _openEdit(null),
          iconSize: addButtonSize,
          padding: EdgeInsets.zero,
          splashRadius: addButtonSize * 0.7,
          icon: Image.asset(
            'assets/images/add_new_product_button.png',
            height: addButtonSize,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
