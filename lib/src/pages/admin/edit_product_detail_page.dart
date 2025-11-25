import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _uploadingImage = false;

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
      debugPrint('Name is required');
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
      debugPrint('save product error: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_uploadingImage) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      setState(() => _uploadingImage = true);

      final file = File(picked.path);
      final url = await ProductService.uploadProductImage(file);

      if (url != null && mounted) {
        setState(() {
          _imgUrlCtrl.text = url;
        });
      }
    } catch (e) {
      debugPrint('pick image error: $e');
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isNew ? 'Add Product' : 'Edit Product';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final horizontalPadding =
                isWide ? constraints.maxWidth * 0.15 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(context, title),
                  const SizedBox(height: 12),
                  const Divider(
                    color: Colors.white70,
                    thickness: 1,
                  ),
                  const SizedBox(height: 12),
                  _imagePlaceholder(constraints),
                  const SizedBox(height: 28),
                  _fieldRow(
                    label: 'NAME',
                    controller: _nameCtrl,
                  ),
                  const SizedBox(height: 12),
                  _fieldRow(
                    label: 'PRICE',
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _fieldRow(
                    label: 'DESCRIPTION',
                    controller: _descCtrl,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  _fieldRow(
                    label: 'STOCK',
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : SizedBox(
                            width: 110,
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                widget.isNew ? 'SAVE' : 'SAVE',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  fontSize: 12,
                                ),
                              ),
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

  Widget _topBar(BuildContext context, String title) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/sabi_login.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(width: 48), // spacer to balance back button
      ],
    );
  }

  Widget _imagePlaceholder(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final isWide = maxWidth > 600;
    final height = isWide ? 260.0 : 220.0;

    final hasImage = _imgUrlCtrl.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: _uploadingImage
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black),
              )
            : hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      _imgUrlCtrl.text.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 48,
                      color: Colors.black54,
                    ),
                  ),
      ),
    );
  }

  Widget _fieldRow({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.6),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: label,
              hintStyle: const TextStyle(
                color: Colors.white54,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
