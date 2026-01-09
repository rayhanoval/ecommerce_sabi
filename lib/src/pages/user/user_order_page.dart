import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce_sabi/src/models/product.dart';
import 'package:ecommerce_sabi/src/pages/user/submit_review_page.dart';

class UserOrderPage extends StatefulWidget {
  const UserOrderPage({super.key});

  @override
  State<UserOrderPage> createState() => _UserOrderPageState();
}

class _UserOrderPageState extends State<UserOrderPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserOrders();
  }

  Future<void> _fetchUserOrders() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch all orders including completed
      final res = await _client
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> allOrders = [];
      final Set<String> productIdsToCheck = {};

      for (var r in res) {
        final order = Map<String, dynamic>.from(r);
        allOrders.add(order);

        // Collect product IDs to check for reviews
        final items = (order['order_items'] as List?) ?? [];
        if (items.isNotEmpty) {
          final firstItem = items.first;
          final product = firstItem['products'];
          if (product != null && product['id'] != null) {
            productIdsToCheck.add(product['id'].toString());
          }
        }
      }

      // Fetch reviews for these products by this user
      Set<String> reviewedOrderItemIds = {};
      if (productIdsToCheck.isNotEmpty) {
        final reviewsRes = await _client
            .from('product_ratings')
            .select('order_item_id')
            .eq('user_id', user.id)
            .inFilter('product_id', productIdsToCheck.toList());

        for (var r in reviewsRes) {
          if (r['order_item_id'] != null) {
            reviewedOrderItemIds.add(r['order_item_id'].toString());
          }
        }
      }

      // Filter orders:
      // Keep if status != 'completed'
      // OR if status == 'completed' AND product NOT reviewed
      final List<Map<String, dynamic>> filteredOrders = [];
      for (var order in allOrders) {
        final status = order['status']?.toString() ?? '';
        if (status != 'completed') {
          filteredOrders.add(order);
        } else {
          // Check if reviewed
          final items = (order['order_items'] as List?) ?? [];
          if (items.isNotEmpty) {
            final firstItem = items.first;
            final product = firstItem['products'];
            final orderItemId = firstItem['id']?.toString();

            if (orderItemId != null &&
                !reviewedOrderItemIds.contains(orderItemId)) {
              filteredOrders.add(order);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _orders = filteredOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user orders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'processing':
        return 'PROCESSING';
      case 'shipped':
        return 'FINISH ORDER';
      case 'completed':
        return 'REVIEW';
      default:
        return status.toUpperCase();
    }
  }

  bool _isStatusEnabled(String status) {
    return status == 'shipped' || status == 'completed';
  }

  Future<void> _handleStatusTap(Map<String, dynamic> order) async {
    final status = order['status']?.toString() ?? '';

    if (status == 'shipped') {
      // Update order to completed
      try {
        final orderId = order['id']?.toString() ?? '';
        await _client
            .from('orders')
            .update({'status': 'completed'}).eq('id', orderId);

        // Navigate to review
        _navigateToReview(order);
      } catch (e) {
        debugPrint('Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else if (status == 'completed') {
      _navigateToReview(order);
    }
  }

  Future<void> _navigateToReview(Map<String, dynamic> order) async {
    final items = (order['order_items'] as List?) ?? [];
    if (items.isEmpty) {
      _fetchUserOrders();
      return;
    }

    // Get first product for review
    final firstItem = items.first;
    final productData = firstItem['products'];
    if (productData == null) {
      _fetchUserOrders();
      return;
    }

    // Convert to Product model
    final product = Product.fromJson(Map<String, dynamic>.from(productData));

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubmitReviewPage(
            product: product,
            orderItemId: firstItem['id'].toString(),
          ),
        ),
      );
      // Refresh orders after review
      _fetchUserOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/sabi_login.png',
          height: 24,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'YOUR ORDERS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _orders.isEmpty
                    ? const Center(
                        child: Text(
                          'No orders yet',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _OrderItem(
                            order: order,
                            onStatusTap: () => _handleStatusTap(order),
                            getStatusText: _getStatusText,
                            isStatusEnabled: _isStatusEnabled,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onStatusTap;
  final String Function(String) getStatusText;
  final bool Function(String) isStatusEnabled;

  const _OrderItem({
    required this.order,
    required this.onStatusTap,
    required this.getStatusText,
    required this.isStatusEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final items = (order['order_items'] as List?) ?? [];
    final status = order['status']?.toString() ?? '';

    // Get first product for display
    final firstItem = items.isNotEmpty ? items.first : null;
    final product = firstItem != null ? firstItem['products'] : null;
    final productName =
        product != null ? (product['name'] ?? '') : 'Unknown Product';
    final imgUrl = product != null ? (product['img_url'] ?? '') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
              image: imgUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imgUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Product Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName.toString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (items.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${items.length - 1} other items',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Status Button
          OutlinedButton(
            onPressed: isStatusEnabled(status) ? onStatusTap : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isStatusEnabled(status) ? Colors.white : Colors.white,
                width: isStatusEnabled(status) ? 1 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              backgroundColor:
                  isStatusEnabled(status) ? Colors.white : Colors.transparent,
            ),
            child: Text(
              getStatusText(status),
              style: TextStyle(
                color: isStatusEnabled(status) ? Colors.black : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
