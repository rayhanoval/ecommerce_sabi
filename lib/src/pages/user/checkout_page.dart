import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';
import 'edit_address_page.dart';

class CheckoutPage extends StatefulWidget {
  final Product product;
  final int quantity;

  const CheckoutPage({
    super.key,
    required this.product,
    this.quantity = 1,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _shippingMethod = "Regular";
  final String _paymentMethod = "Cash On Delivery";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final resp = await supabase
          .from('users')
          .select('display_name, address')
          .eq('id', user.id)
          .maybeSingle();

      if (resp != null && mounted) {
        _nameController.text = (resp['display_name'] ?? '').toString();
        final defaultAddr = (resp['address'] ?? '').toString();
        _addressController.text = defaultAddr;
        // if you want to preload a selectedAddressRow, you could query addresses table here
        setState(() {});
      }
    } catch (e) {
      debugPrint('loadProfile error: $e');
    }
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(price);
  }

  Map<String, dynamic>? _normalizeFirstRow(dynamic resp) {
    if (resp == null) return null;
    if (resp is Map<String, dynamic>) return resp;
    if (resp is List && resp.isNotEmpty && resp[0] is Map) {
      return Map<String, dynamic>.from(resp[0]);
    }
    return null;
  }

  Future<void> _placeOrder() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login terlebih dahulu')),
      );
      return;
    }

    final qty = widget.quantity;
    final basePrice = widget.product.price * qty;
    final shippingFee = _shippingMethod == "Regular" ? 10000 : 20000;
    final totalPrice = basePrice + shippingFee;

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan alamat tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ambil stock & harga terbaru
      final productResp = await supabase
          .from('products')
          .select('stock, price')
          .eq('id', widget.product.id)
          .maybeSingle();

      if (productResp == null) throw Exception('Produk tidak ditemukan');

      final prod = Map<String, dynamic>.from(productResp);
      final currentStock = (prod['stock'] is int)
          ? prod['stock'] as int
          : int.tryParse((prod['stock'] ?? '0').toString()) ?? 0;
      final productPrice = (prod['price'] is num)
          ? (prod['price'] as num).toDouble()
          : double.tryParse((prod['price'] ?? '0').toString()) ?? 0.0;

      if (currentStock < qty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stok tidak cukup (tersisa $currentStock)')),
          );
        }
        return;
      }

      // insert order
      final orderPayload = {
        'user_id': user.id,
        'total_price': totalPrice,
        'shipping_address': address,
        'payment_method': _paymentMethod,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final insertOrder =
          await supabase.from('orders').insert(orderPayload).select();
      final orderMap = _normalizeFirstRow(insertOrder);
      if (orderMap == null || orderMap['id'] == null) {
        throw Exception('Gagal membuat order');
      }
      final orderId = orderMap['id'].toString();

      // insert order item
      await supabase.from('order_items').insert({
        'order_id': orderId,
        'product_id': widget.product.id,
        'quantity': qty,
        'price': productPrice,
        'subtotal': productPrice * qty,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // update stock
      await supabase.from('products').update({
        'stock': currentStock - qty,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('id', widget.product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order berhasil dibuat')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      final msg = e is PostgrestException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuat order: $msg')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    // navigate to EditAddressPage and await selected address map
    final selected = await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(builder: (_) => const EditAddressPage()),
    );

    if (selected != null && mounted) {
      setState(() {
        _addressController.text = (selected['address'] ?? '').toString();
        _nameController.text =
            (selected['name'] ?? _nameController.text).toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;

    // responsive sizes
    final horizontalPad = (w * 0.06).clamp(14.0, 28.0);
    final logoHeight = (w * 0.16).clamp(36.0, 64.0);
    final placeBtnHeight = (w * 0.12).clamp(44.0, 64.0);

    final basePrice = widget.product.price * widget.quantity;
    final shippingFee = _shippingMethod == "Regular" ? 10000 : 20000;
    final totalPrice = basePrice + shippingFee;

    Widget sectionBox({required Widget child}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      );
    }

    Widget labelChip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPad),
          child: Column(
            children: [
              // header
              Padding(
                padding: EdgeInsets.only(top: h * 0.01, bottom: h * 0.01),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/sabi_checkout.png',
                          height: logoHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // spacer to balance
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // NAME (read-only)
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelChip('NAME'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              readOnly: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Your name',
                                hintStyle:
                                    const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.white10,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: h * 0.02),

                      // ADDRESS = button to edit addresses
                      GestureDetector(
                        onTap: _pickAddress,
                        child: sectionBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              labelChip('ADDRESS'),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _addressController,
                                      readOnly: true,
                                      maxLines: 3,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Choose shipping address',
                                        hintStyle: const TextStyle(
                                            color: Colors.white54),
                                        filled: true,
                                        fillColor: Colors.white10,
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: const [
                                      Icon(Icons.chevron_right,
                                          color: Colors.white70),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.02),

                      // SHIPPING METHOD
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelChip('SHIPPING METHOD'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white10,
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                          borderRadius: BorderRadius.zero),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _shippingMethod,
                                        dropdownColor: Colors.black,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'Regular',
                                              child: Text('Regular',
                                                  style: TextStyle(
                                                      color: Colors.white))),
                                          DropdownMenuItem(
                                              value: 'Express',
                                              child: Text('Express',
                                                  style: TextStyle(
                                                      color: Colors.white))),
                                        ],
                                        onChanged: (v) => setState(() =>
                                            _shippingMethod = v ?? 'Regular'),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(_formatPrice(shippingFee.toDouble()),
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: h * 0.02),

                      // PAYMENT
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelChip('PAYMENT'),
                            const SizedBox(height: 8),
                            Text(_paymentMethod,
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),

                      SizedBox(height: h * 0.02),

                      // PRODUCT SUMMARY
                      sectionBox(
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: (w * 0.26).clamp(70.0, 110.0),
                                height: (w * 0.18).clamp(56.0, 90.0),
                                color: Colors.grey[900],
                                child: widget.product.imgUrl.isNotEmpty
                                    ? Image.network(widget.product.imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white24))
                                    : const Icon(Icons.image,
                                        color: Colors.white24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.product.name.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text('${widget.quantity}x',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  Text(_formatPrice(widget.product.price),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: h * 0.03),

                      // TOTAL BREAKDOWN
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('ITEM TOTAL',
                                      style: TextStyle(color: Colors.white70)),
                                  Text(_formatPrice(basePrice),
                                      style:
                                          const TextStyle(color: Colors.white))
                                ]),
                            const SizedBox(height: 8),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('SHIPPING',
                                      style: TextStyle(color: Colors.white70)),
                                  Text(_formatPrice(shippingFee.toDouble()),
                                      style:
                                          const TextStyle(color: Colors.white))
                                ]),
                            const Divider(color: Colors.white12, height: 18),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL PRICE',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold)),
                                  Text(_formatPrice(totalPrice),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold))
                                ]),
                          ],
                        ),
                      ),

                      SizedBox(height: h * 0.035),

                      // PLACE ORDER
                      SizedBox(
                        width: double.infinity,
                        height: placeBtnHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2))
                              : Text(
                                  'PLACE ORDER • ${_formatPrice(totalPrice)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),

                      SizedBox(height: h * 0.06),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
