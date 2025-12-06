import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ecommerce_sabi/src/models/product.dart';
import 'package:ecommerce_sabi/src/services/product_repository.dart';
import 'package:ecommerce_sabi/src/services/product_image_service.dart';
import 'package:ecommerce_sabi/src/widgets/common/custom_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductDetailPage extends ConsumerStatefulWidget {
  final Product? product; // null = create mode

  const EditProductDetailPage({
    super.key,
    this.product,
  });

  bool get isNew => product == null;

  @override
  ConsumerState<EditProductDetailPage> createState() =>
      _EditProductDetailPageState();
}

class _EditProductDetailPageState extends ConsumerState<EditProductDetailPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _stockCtrl;
  bool _isActive = true;
  bool _saving = false;
  bool _uploadingImage = false;
  List<String> _allImages = []; // All product images (max 10)
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  late final ProductImageService _imageService;

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
    _isActive = p?.isActive ?? true;
    _imageService = ProductImageService(Supabase.instance.client);

    // Load existing images if editing
    if (!widget.isNew && p != null) {
      _loadExistingImages(p.id);
    } else if (p != null && p.imgUrl.isNotEmpty) {
      _allImages.add(p.imgUrl);
    }
  }

  Future<void> _loadExistingImages(String productId) async {
    final images = await _imageService.fetchProductImages(productId);
    if (mounted) {
      setState(() {
        // Combine main image with additional images
        _allImages = [
          if (widget.product!.imgUrl.isNotEmpty) widget.product!.imgUrl,
          ...images,
        ];
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _stockCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (!widget.isNew && widget.product != null) {
      await _loadExistingImages(widget.product!.id);
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final desc = _descCtrl.text.trim();
    final imgUrl = _allImages.isNotEmpty ? _allImages.first : '';
    final additionalImages =
        _allImages.length > 1 ? _allImages.sublist(1) : <String>[];

    if (name.isEmpty) {
      debugPrint('Name is required');
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(productRepositoryProvider);
      if (widget.isNew) {
        final created = await repo.createProduct(
          name: name,
          price: price,
          description: desc,
          stock: stock,
          isActive: _isActive,
          imgUrl: imgUrl,
        );
        if (created != null) {
          // Save additional images (all except first)
          await _imageService.saveProductImages(created.id, additionalImages);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      } else {
        final old = widget.product!;
        final updated = await repo.updateProduct(
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
        if (updated != null) {
          // Save additional images (all except first)
          await _imageService.saveProductImages(updated.id, additionalImages);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
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

  Future<void> _pickImages() async {
    if (_uploadingImage || _allImages.length >= 10) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();

      if (picked.isEmpty) return;

      setState(() => _uploadingImage = true);

      // Upload each image
      for (var pickedFile in picked) {
        if (_allImages.length >= 10) break;

        final file = File(pickedFile.path);
        final url =
            await ref.read(productRepositoryProvider).uploadProductImage(file);

        if (url != null && mounted) {
          setState(() {
            _allImages.add(url);
          });
        }
      }
    } catch (e) {
      debugPrint('pick images error: $e');
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _allImages.removeAt(index);
      if (_currentImageIndex >= _allImages.length && _allImages.isNotEmpty) {
        _currentImageIndex = _allImages.length - 1;
        _pageController.jumpToPage(_currentImageIndex);
      }
    });
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

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                    _imageCarousel(constraints),
                    const SizedBox(height: 28),
                    CustomTextField(
                      label: 'NAME',
                      controller: _nameCtrl,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'PRICE',
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'DESCRIPTION',
                      controller: _descCtrl,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'STOCK',
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

  Widget _imageCarousel(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final isWide = maxWidth > 600;
    final height = isWide ? 260.0 : 220.0;

    return Column(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: _uploadingImage
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                )
              : _allImages.isEmpty
                  ? GestureDetector(
                      onTap: _pickImages,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              size: 48,
                              color: Colors.black54,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add images',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemCount: _allImages.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                _allImages[index],
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
                              );
                            },
                          ),
                          // Delete button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeImage(_currentImageIndex),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
        const SizedBox(height: 12),
        // Page indicators and controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Page indicators
            if (_allImages.isNotEmpty)
              Row(
                children: List.generate(
                  _allImages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white38,
                    ),
                  ),
                ),
              ),
            if (_allImages.isEmpty) const SizedBox(),
            // Add button and counter
            Row(
              children: [
                Text(
                  '${_allImages.length}/10',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                if (_allImages.length < 10)
                  ElevatedButton.icon(
                    onPressed: _uploadingImage ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate, size: 16),
                    label: const Text('ADD'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
