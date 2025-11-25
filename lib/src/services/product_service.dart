import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // FETCH ALL PRODUCTS (ACTIVE ONLY)
  // ============================================================
  static Future<List<Product>> fetchAllProducts() async {
    try {
      final res = await _client
          .from('products')
          .select('*')
          .match({'is_active': true}) // pengganti eq()
          .order('created_at'); // SDK kamu mendukung order di select()

      return (res as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('fetchAllProducts error: $e');
      return [];
    }
  }

  // ============================================================
  // FETCH ALL (WITHOUT FILTER)
  // ============================================================
  static Future<List<Product>> fetchAll() async {
    try {
      final res = await _client.from('products').select('*');

      return (res as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('fetchAll error: $e');
      return [];
    }
  }

  // ============================================================
  // CREATE PRODUCT
  // ============================================================
  static Future<Product?> createProduct({
    required String name,
    required double price,
    required String description,
    required int stock,
    required bool isActive,
    required String imgUrl,
  }) async {
    try {
      final res = await _client
          .from('products')
          .insert({
            'name': name,
            'price': price,
            'description': description,
            'stock': stock,
            'is_active': isActive,
            'img_url': imgUrl,
          })
          .select()
          .maybeSingle();

      if (res == null) return null;

      return Product.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      print('createProduct error: $e');
      return null;
    }
  }

  // ============================================================
  // UPDATE PRODUCT
  // ============================================================
  static Future<Product?> updateProduct(Product product) async {
    try {
      final res = await _client
          .from('products')
          .update({
            'name': product.name,
            'price': product.price,
            'description': product.description,
            'stock': product.stock,
            'is_active': product.isActive,
            'img_url': product.imgUrl,
            'updated_at': DateTime.now().toIso8601String()
          })
          .match({'id': product.id}) // pengganti eq()
          .select()
          .maybeSingle();

      if (res == null) return null;

      return Product.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      print('updateProduct error: $e');
      return null;
    }
  }

  // ============================================================
  // UPLOAD PRODUCT IMAGE
  // ============================================================
  static Future<String?> uploadProductImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'uploads/$fileName';

      await _client.storage.from('products').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _client.storage.from('products').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print('uploadProductImage error: $e');
      return null;
    }
  }
}

Future<List<dynamic>> loadProducts() => ProductService.fetchAllProducts();
