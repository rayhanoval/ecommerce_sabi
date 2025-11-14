// lib/pages/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

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
  String _name = '';
  String _address = '';
  String _shippingMethod = "Regular";
  String _paymentMethod = "Cash On Delivery";
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profileResp = await supabase
        .from('profiles')
        .select('full_name, default_address')
        .eq('id', user.id)
        .maybeSingle();

    if (profileResp != null) {
      final profile = Map<String, dynamic>.from(profileResp);
      if (!mounted) return;
      setState(() {
        _name = profile['full_name'] ?? '';
        _address = profile['default_address'] ?? '';
      });
    }
  }

  String _formatPrice(double price) {
    final f =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return f.format(price);
  }

  Map<String, dynamic>? _normalizeFirstRow(dynamic resp) {
    if (resp == null) return null;
    if (resp is Map<String, dynamic>) return resp;
    if (resp is List && resp.isNotEmpty && resp[0] is Map) {
      return Map<String, dynamic>.from(resp[0] as Map);
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
    final totalPrice = widget.product.price * qty;

    if (_name.isEmpty || _address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan alamat harus tersedia')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? createdOrderId;

    try {
      // 1) ambil current stock & price
      final prodResp = await supabase
          .from('products')
          .select('stock, price')
          .eq('id', widget.product.id)
          .maybeSingle();

      if (prodResp == null) throw Exception('Produk tidak ditemukan');

      final prodMap =
          Map<String, dynamic>.from(prodResp as Map<String, dynamic>);
      final currentStock = (prodMap['stock'] is int)
          ? prodMap['stock'] as int
          : int.tryParse((prodMap['stock'] ?? '0').toString()) ?? 0;
      final productPrice = (prodMap['price'] is num)
          ? (prodMap['price'] as num).toDouble()
          : double.tryParse((prodMap['price'] ?? '0').toString()) ?? 0.0;

      if (currentStock < qty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok tidak cukup (tersisa $currentStock)')),
        );
        return;
      }

      // 2) insert orders
      final orderPayload = {
        'user_id': user.id,
        'total_price': totalPrice,
        'shipping_address': _address,
        'payment_method': _paymentMethod,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final orderInsertResult =
          await supabase.from('orders').insert(orderPayload).select();

      final orderMap = _normalizeFirstRow(orderInsertResult);
      if (orderMap == null || !(orderMap.containsKey('id'))) {
        throw Exception('Gagal membuat order');
      }

      createdOrderId = orderMap['id'].toString();

      // 3) insert order_items
      final itemPayload = {
        'order_id': createdOrderId,
        'product_id': widget.product.id,
        'quantity': qty,
        'price': productPrice,
        'subtotal': productPrice * qty,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final itemInsertResult =
          await supabase.from('order_items').insert(itemPayload).select();
      final itemMap = _normalizeFirstRow(itemInsertResult);
      if (itemMap == null) {
        await supabase.from('orders').delete().eq('id', createdOrderId);
        throw Exception('Gagal menambahkan order item');
      }

      // 4) update stock
      final newStock = currentStock - qty;
      await supabase
          .from('products')
          .update({
            'stock': newStock,
            'updated_at': DateTime.now().toUtc().toIso8601String()
          })
          .eq('id', widget.product.id)
          .select();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order berhasil dibuat ✅')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      final msg = e is PostgrestException ? e.message : e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuat order: $msg')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;

    final horizontalPad = (w * 0.06).clamp(16.0, 28.0);
    final sectionSpacing = h * 0.028;
    final titleHeight = (w * 0.18).clamp(36.0, 64.0);
    final placeBtnHeight = (w * 0.11).clamp(40.0, 56.0);
    final borderRadius = 8.0;
    final totalPrice = widget.product.price * widget.quantity;

    Widget sectionBox({required Widget child, EdgeInsets? padding}) {
      return Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: child,
      );
    }

    Widget labelBox(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(6)),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: h * 0.015),
                      child: Center(
                        child: Image.asset('assets/images/sabi_checkout.png',
                            height: titleHeight, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              SizedBox(height: sectionSpacing * 0.4),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelBox('NAME/ADDRESS'),
                            const SizedBox(height: 8),
                            Text(_name,
                                style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(_address,
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      SizedBox(height: sectionSpacing * 0.5),
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelBox('SHIPPING METHOD'),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              dropdownColor: Colors.black,
                              value: _shippingMethod,
                              items: const [
                                DropdownMenuItem(
                                    value: 'Regular',
                                    child: Text('Regular',
                                        style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(
                                    value: 'Express',
                                    child: Text('Express',
                                        style: TextStyle(color: Colors.white))),
                              ],
                              onChanged: (v) =>
                                  setState(() => _shippingMethod = v!),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: sectionSpacing * 0.5),
                      sectionBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            labelBox('PAYMENT'),
                            const SizedBox(height: 8),
                            Text(_paymentMethod,
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      SizedBox(height: sectionSpacing * 0.6),
                      sectionBox(
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: (w * 0.22).clamp(64.0, 120.0),
                                height: (w * 0.14).clamp(48.0, 80.0),
                                color: Colors.grey[900],
                                child: widget.product.imgUrl.isNotEmpty
                                    ? Image.network(widget.product.imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, st) => const Icon(
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
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
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL PRICE:',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text(_formatPrice(totalPrice),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _isLoading ? null : _placeOrder,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Image.asset(
                                    'assets/images/place_order_button.png',
                                    height: placeBtnHeight,
                                    fit: BoxFit.contain),
                          ),
                        ],
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
