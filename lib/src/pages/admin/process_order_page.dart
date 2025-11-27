import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ecommerce_sabi/src/pages/admin/process_order_detail_page.dart';

class ProcessOrderPage extends StatefulWidget {
  const ProcessOrderPage({super.key});

  @override
  State<ProcessOrderPage> createState() => _ProcessOrderPageState();
}

class _ProcessOrderPageState extends State<ProcessOrderPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  Set<String> _selectedOrderIds = {};
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      // Fetch orders with status 'pending'
      // Join with order_items and products to get details
      // Note: Supabase join syntax might vary based on FK setup.
      // Assuming we can fetch orders and then fetch items for them, or use deep select.

      final res = await _client
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> loaded = [];
      for (var r in res) {
        loaded.add(Map<String, dynamic>.from(r));
      }

      if (mounted) {
        setState(() {
          _orders = loaded;
          _isLoading = false;
          _selectedOrderIds.clear();
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedOrderIds.length == _orders.length) {
        _selectedOrderIds.clear();
      } else {
        _selectedOrderIds = _orders.map((o) => o['id'].toString()).toSet();
      }
    });
  }

  Future<void> _processOrders() async {
    if (_selectedOrderIds.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      // Update status to 'processing'
      await _client.from('orders').update({'status': 'processing'}).filter(
          'id', 'in', _selectedOrderIds.toList());

      if (mounted) {
        // Navigate to detail page
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProcessOrderDetailPage(
              orderIds: _selectedOrderIds.toList(),
            ),
          ),
        );

        // Refresh list if orders were marked as shipped
        if (result == true) {
          _fetchOrders();
        }
      }
    } catch (e) {
      debugPrint('Error processing orders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process orders: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _orders.isNotEmpty && _selectedOrderIds.length == _orders.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Image.asset(
              'assets/images/sabi_login.png', // Logo requested
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab('NEW ORDER', true),
                const SizedBox(width: 16),
                _buildTab('TO SHIP', false),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _orders.isEmpty
                    ? const Center(
                        child: Text('No pending orders',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final id = order['id'].toString();
                          final items = (order['order_items'] as List?) ?? [];
                          // Display first item details for the preview
                          final firstItem =
                              items.isNotEmpty ? items.first : null;
                          final product =
                              firstItem != null ? firstItem['products'] : null;

                          final productName = product != null
                              ? (product['name'] ?? 'Unknown Product')
                              : 'Unknown Product';
                          final price =
                              firstItem != null ? (firstItem['price'] ?? 0) : 0;
                          final quantity = firstItem != null
                              ? (firstItem['quantity'] ?? 0)
                              : 0;
                          final imgUrl =
                              product != null ? (product['img_url'] ?? '') : '';

                          // If multiple items, maybe show "+ X more"
                          final moreCount =
                              items.length > 1 ? items.length - 1 : 0;

                          final isSelected = _selectedOrderIds.contains(id);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedOrderIds.remove(id);
                                } else {
                                  _selectedOrderIds.add(id);
                                }
                              });
                            },
                            child: Row(
                              children: [
                                // Checkbox (Custom look)
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
                                    image: imgUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(imgUrl),
                                            fit: BoxFit.cover)
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
                                        productName.toString().toUpperCase(),
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
                                        NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'RP.',
                                                decimalDigits: 0)
                                            .format(price),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      if (moreCount > 0)
                                        Text(
                                          '+ $moreCount other items',
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),

                                // Quantity
                                Text(
                                  '${quantity}X',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24)),
            ),
            child: Row(
              children: [
                // Select All Button
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
                const Spacer(),
                // Process Order Button
                ElevatedButton(
                  onPressed: (_selectedOrderIds.isEmpty || _isProcessing)
                      ? null
                      : _processOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors
                        .white, // Inverted for emphasis? Or maybe transparent with border?
                    // Design shows "PROCESS ORDER" button. Let's make it outlined to match style or filled white.
                    // The screenshot shows "PROCESS ORDER" button looking similar to "SELECT ALL" but maybe filled?
                    // Let's stick to Outlined for consistency with "SELECT ALL" in the screenshot if they look same.
                    // Actually screenshot shows both look like outlined buttons.
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    foregroundColor: Colors.black, // Text color if filled
                  ).copyWith(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.transparent),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'PROCESS ORDER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: isActive
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            )
          : BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(4),
            ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
