import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsService {
  static final _supabase = Supabase.instance.client;

  /// Fetch products (active only)
  /// Returns a List<dynamic> (each item usually Map<String, dynamic>)
  static Future<List<dynamic>> fetchProducts({int limit = 100}) async {
    try {
      final data = await _supabase
          .from('products')
          .select('*') // jangan pakai generic di .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);

      // normalize: Supabase biasanya mengembalikan List for select(*)
      if (data is List) {
        return data;
      } else {
        // unexpected shape (null or Map) -> return empty list
        return <dynamic>[];
      }
    } catch (e, st) {
      // log error untuk debugging
      print('Products fetch exception: $e\n$st');
      return <dynamic>[];
    }
  }
}

/// backward-compatible shortcut (jika banyak file lain memanggil loadProducts)
Future<List<dynamic>> loadProducts() => ProductsService.fetchProducts();
