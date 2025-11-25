import 'package:flutter/material.dart';
import 'package:ecommerce_sabi/src/models/product.dart';
import 'package:ecommerce_sabi/src/services/product_service.dart';

class EditProductDetailPage extends StatefulWidget {
  final Product? product; // null = create mode

  const EditProductDetailPage({
    super.key,
    this.product,
  });

  bool get isNew => product == null;

  @override
  State<EditProductDetailPage> createState() => _EditProductDetailPageState();
}

class _EditProductDetailPageState extends State<EditProductDetailPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _imgUrlCtrl;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? p.price.toStringAsFixed(0) : '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _stockCtrl =
        TextEditingController(text: p != null ? p.stock.toString() : '');
    _imgUrlCtrl = TextEditingController(text: p?.imgUrl ?? '');
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _stockCtrl.dispose();
    _imgUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final desc = _descCtrl.text.trim();
    final imgUrl = _imgUrlCtrl.text.trim();

    if (name.isEmpty) {
      // ignore: avoid_print
      print('Name is required');
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.isNew) {
        final created = await ProductService.createProduct(
          name: name,
          price: price,
          description: desc,
          stock: stock,
          isActive: _isActive,
          imgUrl: imgUrl,
        );
        if (created != null && mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        final old = widget.product!;
        final updated = await ProductService.updateProduct(
          Product(
            id: old.id,
            name: name,
            price: price,
            description: desc,
            stock: stock,
            rating: old.rating,
            isActive: _isActive,
            imgUrl: imgUrl,
            createdAt: old.createdAt,
            updatedAt: DateTime.now(),
            ratingCount: old.ratingCount,
            ratingAvg: old.ratingAvg,
          ),
        );
        if (updated != null && mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('save product error: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isNew ? 'Add Product' : 'Edit Product';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Price (IDR)',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imgUrlCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text(
                  'Active',
                  style: TextStyle(color: Colors.white),
                ),
                activeColor: Colors.white,
              ),
              const SizedBox(height: 20),
              _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(widget.isNew ? 'Create' : 'Save'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
