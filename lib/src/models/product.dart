class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final int stock;
  final double rating; // bisa dihapus kalau mau pakai ratingAvg
  final bool isActive;
  final String imgUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int ratingCount;
  final double ratingAvg;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.stock,
    required this.rating,
    required this.isActive,
    required this.imgUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.ratingCount,
    required this.ratingAvg,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] ?? '',
      stock: json['stock'] as int,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      imgUrl: json['img_url'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      ratingCount: (json['rating_count'] as int?) ?? 0,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
