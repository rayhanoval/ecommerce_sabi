import 'package:supabase_flutter/supabase_flutter.dart';

class ProductImageService {
  final SupabaseClient _client;

  ProductImageService(this._client);

  /// Fetch all images for a product, ordered by order_index
  Future<List<String>> fetchProductImages(String productId) async {
    try {
      final res = await _client
          .from('product_images')
          .select('image_url')
          .eq('product_id', productId)
          .order('order_index', ascending: true);

      return (res as List).map((e) => e['image_url'].toString()).toList();
    } catch (e) {
      print('Error fetching product images: $e');
      return [];
    }
  }

  /// Save multiple images for a product
  Future<bool> saveProductImages(
      String productId, List<String> imageUrls) async {
    try {
      // Delete existing images first
      await _client.from('product_images').delete().eq('product_id', productId);

      // Insert new images with order
      if (imageUrls.isEmpty) return true;

      final data = imageUrls
          .asMap()
          .entries
          .map((entry) => {
                'product_id': productId,
                'image_url': entry.value,
                'order_index': entry.key,
              })
          .toList();

      await _client.from('product_images').insert(data);
      return true;
    } catch (e) {
      print('Error saving product images: $e');
      return false;
    }
  }

  /// Delete a specific image by URL
  Future<bool> deleteProductImage(String productId, String imageUrl) async {
    try {
      await _client
          .from('product_images')
          .delete()
          .eq('product_id', productId)
          .eq('image_url', imageUrl);
      return true;
    } catch (e) {
      print('Error deleting product image: $e');
      return false;
    }
  }
}
