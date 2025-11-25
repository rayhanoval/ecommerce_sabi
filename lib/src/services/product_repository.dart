import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SupabaseProductRepository(Supabase.instance.client);
});

abstract class ProductRepository {
  Future<List<Product>> fetchAllProducts();
  Future<List<Product>> fetchAll();
  Future<Product?> createProduct({
    required String name,
    required double price,
    required String description,
    required int stock,
    required bool isActive,
    required String imgUrl,
  });
  Future<Product?> updateProduct(Product product);
  Future<String?> uploadProductImage(File file);
}

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _client;

  SupabaseProductRepository(this._client);

  @override
  Future<List<Product>> fetchAllProducts() async {
    try {
      final res = await _client
          .from('products')
          .select('*')
          .match({'is_active': true}).order('created_at');

      return (res as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('fetchAllProducts error: $e');
      return [];
    }
  }

  @override
  Future<List<Product>> fetchAll() async {
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

  @override
  Future<Product?> createProduct({
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

  @override
  Future<Product?> updateProduct(Product product) async {
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
          .match({'id': product.id})
          .select()
          .maybeSingle();

      if (res == null) return null;

      return Product.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      print('updateProduct error: $e');
      return null;
    }
  }

  @override
  Future<String?> uploadProductImage(File file) async {
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
