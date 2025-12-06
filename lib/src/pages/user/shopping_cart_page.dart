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

  Future<void> _deleteItem(String cartId) async {
    try {
      await _client.from('carts').delete().eq('id', cartId);

      setState(() {
        _cartItems.removeWhere((item) => item['id'].toString() == cartId);
        _selectedItemIds.remove(cartId);
      });
    } catch (e) {
      debugPrint('Error deleting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(String cartId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      await _client.from('carts').update({
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', cartId);

      // Update local state
      setState(() {
        final index =
            _cartItems.indexWhere((item) => item['id'].toString() == cartId);
        if (index != -1) {
          _cartItems[index]['quantity'] = newQuantity;
        }
      });
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quantity: $e')),
        );
      }
    }
  }

  Future<void> _incrementQuantity(
      String cartId, int currentQty, int stock) async {
    if (currentQty < stock) {
      await _updateQuantity(cartId, currentQty + 1);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock hanya tersisa: $stock')),
        );
      }
    }
  }

  void _decrementQuantity(String cartId, int currentQty) {
    if (currentQty > 1) {
      _updateQuantity(cartId, currentQty - 1);
    } else {
      // Logic delete item jika quantity 1 dan dipencet minus
      _deleteItem(cartId);
    }
  }

  Future<void> _checkout() async {
    if (_selectedItemIds.isEmpty) return;

    final selectedItems = _cartItems
        .where((item) => _selectedItemIds.contains(item['id'].toString()))
        .toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
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

                          return Dismissible(
                            key: Key(id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _deleteItem(id);
                            },
                            background: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD32F2F),
                                    Color(0xFFB71C1C),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'DELETE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete_outline,
                                      color: Colors.white),
                                ],
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _toggleItem(id),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black,
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
                                          const SizedBox(height: 6),
                                          // Quantity controls
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () =>
                                                    _decrementQuantity(
                                                        id, quantity),
                                                icon: const Icon(Icons
                                                    .remove_circle_outline),
                                                color: Colors.white70,
                                                iconSize: 18,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                                child: Text(
                                                  '$quantity',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  final stock =
                                                      product['stock'] ?? 0;
                                                  _incrementQuantity(
                                                      id, quantity, stock);
                                                },
                                                icon: const Icon(
                                                    Icons.add_circle_outline),
                                                color: Colors.white70,
                                                iconSize: 18,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
