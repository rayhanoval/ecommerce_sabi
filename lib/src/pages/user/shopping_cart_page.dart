import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'checkout_page.dart';
import '../../models/product.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _cartItems = [];
  Set<String> _selectedItemIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch cart items with product details
      final res = await _client
          .from('carts')
          .select('*, products(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> loaded = [];
      for (var r in res) {
        loaded.add(Map<String, dynamic>.from(r));
      }

      if (mounted) {
        setState(() {
          _cartItems = loaded;
          _isLoading = false;
          // Optional: Select all by default? Or none? Let's keep none selected initially.
        });
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedItemIds.length == _cartItems.length) {
        _selectedItemIds.clear();
      } else {
        _selectedItemIds = _cartItems.map((e) => e['id'].toString()).toSet();
      }
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      if (_selectedItemIds.contains(item['id'].toString())) {
        final product = item['products'];
        final price = product != null ? (product['price'] ?? 0) : 0;
        final quantity = item['quantity'] ?? 1;
        total += (price * quantity);
      }
    }
    return total;
  }

  Future<void> _checkout() async {
    if (_selectedItemIds.isEmpty) return;

    final selectedItems = _cartItems
        .where((item) => _selectedItemIds.contains(item['id'].toString()))
        .toList();

    // Navigate to checkout with selected items
    // We need to update CheckoutPage to accept a list of items
    // For now, we'll assume CheckoutPage will be updated shortly.
    // Passing the first item as a placeholder if strictly needed by current signature,
    // but ideally we pass the list.

    // Since we are in the middle of refactoring, let's try to pass what we can.
    // The plan says we will update CheckoutPage.
    // So here I will assume the new signature or pass data that the new signature will use.

    // For this step, I'll just navigate. The CheckoutPage update is next.
    // I'll pass the list as an argument if possible, or use a new constructor.

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          // We will modify CheckoutPage to accept this list.
          // For now, I'll pass the first product to satisfy the current required param
          // and pass the list as a new param (which I'll add in the next step).
          product: Product.fromJson(selectedItems.first['products']),
          cartItems: selectedItems,
        ),
      ),
    );

    _fetchCartItems(); // Refresh after returning
  }

  String _formatPrice(num price) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(price);
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _cartItems.isNotEmpty && _selectedItemIds.length == _cartItems.length;
    final total = _calculateTotal();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
              'MY CART',
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
                : _cartItems.isEmpty
                    ? const Center(
                        child: Text(
                          'Your cart is empty',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final id = item['id'].toString();
                          final product = item['products'] ?? {};
                          final name = product['name'] ?? 'Unknown';
                          final price = product['price'] ?? 0;
                          final imgUrl = product['img_url'] ?? '';
                          final quantity = item['quantity'] ?? 1;
                          final isSelected = _selectedItemIds.contains(id);

                          return InkWell(
                            onTap: () => _toggleItem(id),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 14, color: Colors.black)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  // Image
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(4),
                                      image: imgUrl.toString().isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(imgUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.toString().toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            letterSpacing: 1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatPrice(price),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${quantity}x',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _formatPrice(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _toggleSelectAll,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text(
                        allSelected ? 'DESELECT ALL' : 'SELECT ALL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedItemIds.isEmpty ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text(
                          'CHECKOUT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
