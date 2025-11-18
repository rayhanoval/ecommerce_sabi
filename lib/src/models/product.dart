class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final int stock;
  final double rating;
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      description: json['description'] ?? '',
      stock: json['stock'] ?? 0,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      isActive: json['is_active'] ?? false,
      imgUrl: json['img_url'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      ratingCount: json['rating_count'] ?? 0,
      ratingAvg: double.tryParse(json['rating_avg'].toString()) ?? 0.0,
    );
  }
}
