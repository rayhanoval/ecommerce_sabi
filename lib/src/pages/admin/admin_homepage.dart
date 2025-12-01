import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ecommerce_sabi/src/pages/edit_profile_page.dart';
import 'package:ecommerce_sabi/src/pages/splash_page.dart';
import 'package:ecommerce_sabi/src/pages/admin/edit_product_page.dart';
import 'package:ecommerce_sabi/src/pages/admin/process_order_page.dart';
import 'package:ecommerce_sabi/src/pages/admin/admin_review_page.dart';
import 'package:ecommerce_sabi/src/widgets/admin/admin_review_card.dart';
import 'package:ecommerce_sabi/src/widgets/common/logout_dialog.dart';
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
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  String _role = '';
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final session = Supabase.instance.client.auth.currentSession;
    final profile = await ref.read(authRepositoryProvider).getCurrentProfile();
    final role = profile?['role']?.toString().toLowerCase() ?? '';
    final repo = ref.read(productRepositoryProvider);

    // Fetch products
    final fetchedProducts = await repo.fetchLimitedProduct();

    // Fetch orders (limit 2, pending)
    List<Map<String, dynamic>> fetchedOrders = [];
    try {
      final res = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(2);

      for (var r in res) {
        fetchedOrders.add(Map<String, dynamic>.from(r));
      }
    } catch (e) {
      debugPrint('Error fetching dashboard orders: $e');
    }

    // Fetch reviews (limit 2)
    List<Map<String, dynamic>> fetchedReviews = [];
    try {
      final res = await Supabase.instance.client
          .from('product_ratings')
          .select('*, products(*), users(display_name, username)')
          .filter('reply', 'is', null)
          .order('created_at', ascending: false)
          .limit(2);

      for (var r in res) {
        fetchedReviews.add(Map<String, dynamic>.from(r));
      }
    } catch (e) {
      debugPrint('Error fetching dashboard reviews: $e');
    }

    if (mounted) {
      setState(() {
        isLoggedIn = session != null;
        _role = role;
        products = fetchedProducts;
        orders = fetchedOrders;
        reviews = fetchedReviews;
        isLoading = false;
      });
    }
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
        leadingWidth: screenWidth * 0.35,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/images/sabi_catalog.png',
            fit: BoxFit.contain,
          ),
        ),
        titleSpacing: 0,
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
                final confirm = await showLogoutDialog(context);
                if (confirm) {
                  await Supabase.instance.client.auth.signOut();
                  setState(() => isLoggedIn = false);
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashPage()),
                    );
                  }
                }
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
          child: RefreshIndicator(
            onRefresh: _fetchDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_role == 'owner') ...[
                    // Product Container
                    _DashboardSection(
                      title: 'YOUR PRODUCT',
                      isLoading: isLoading,
                      children: products
                          .map((p) => _ProductTile(product: p))
                          .toList(),
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProductPage(),
                          ),
                        );
                      },
                      showViewAll: !isLoading && products.length >= 2,
                    ),

                    const SizedBox(height: 32),
                  ],

                  // Order Container
                  _DashboardSection(
                    title: 'NEW ORDER',
                    isLoading: isLoading,
                    children: orders.map((o) => _OrderTile(order: o)).toList(),
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProcessOrderPage(),
                        ),
                      );
                    },
                    showViewAll: !isLoading && orders.isNotEmpty,
                  ),

                  const SizedBox(height: 32),

                  // Review Container
                  _DashboardSection(
                    title: 'REPLY REVIEW',
                    isLoading: isLoading,
                    children: reviews
                        .map((r) => AdminReviewCard(
                              review: r,
                              onReplySuccess: _fetchDashboardData,
                            ))
                        .toList(),
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminReviewPage(),
                        ),
                      );
                    },
                    showViewAll: !isLoading && reviews.isNotEmpty,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final bool isLoading;
  final List<Widget> children;
  final VoidCallback onViewAll;
  final bool showViewAll;

  const _DashboardSection({
    required this.title,
    required this.isLoading,
    required this.children,
    required this.onViewAll,
    required this.showViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (isLoading)
          const CircularProgressIndicator(color: Colors.white)
        else if (children.isEmpty)
          const Text('No items', style: TextStyle(color: Colors.white54))
        else
          ...children.map((child) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: child,
              )),
        if (showViewAll)
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 150,
              child: OutlinedButton(
                onPressed: onViewAll,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = (order['order_items'] as List?) ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;
    final product = firstItem != null ? firstItem['products'] : null;

    final productName =
        product != null ? (product['name'] ?? 'Unknown') : 'Unknown';
    final price = firstItem != null ? (firstItem['price'] ?? 0) : 0;
    final quantity = firstItem != null ? (firstItem['quantity'] ?? 0) : 0;
    final imgUrl = product != null ? (product['img_url'] ?? '') : '';

    final formattedPrice =
        NumberFormat.currency(locale: 'id_ID', symbol: 'RP.', decimalDigits: 0)
            .format(price);
    final qtyStr = '${quantity}x';

    return Row(
      children: [
        Container(
          width: 80,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white10,
            image: imgUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imgUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName.toString().toUpperCase(),
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
        Text(
          qtyStr,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
