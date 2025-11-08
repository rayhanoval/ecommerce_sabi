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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      description: json['description'],
      stock: json['stock'],
      rating: json['rating'].toDouble(),
      isActive: json['is_active'],
      imgUrl: json['img_url'],
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(int.parse(json['created_at'])),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(int.parse(json['updated_at'])),
    );
  }
}
