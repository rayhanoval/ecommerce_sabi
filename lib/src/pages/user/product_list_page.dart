import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecommerce_sabi/src/pages/edit_profile_page.dart';
import '../../widgets/product/card.dart';
import '../../widgets/common/grid.dart';
import '../../services/product_repository.dart';
import '../login_page.dart';
import 'product_detail_page.dart';
import '../../models/product.dart';
import '../../widgets/common/logout_dialog.dart';
import 'user_order_page.dart';
import 'shopping_cart_page.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  bool isLoggedIn = false;
  bool _hasOrderNotification = false;

  @override
  void initState() {
    super.initState();

    // cek session Supabase saat halaman dibuka
    final session = Supabase.instance.client.auth.currentSession;
    isLoggedIn = session != null;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    // listen perubahan auth (login/logout)
    // onAuthStateChange returns Stream<AuthState> where data.event indicates change
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        setState(() => isLoggedIn = true);
        _checkOrderNotifications();
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          isLoggedIn = false;
          _hasOrderNotification = false;
        });
      }
    });

    if (isLoggedIn) {
      _checkOrderNotifications();
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {});
    if (isLoggedIn) {
      _checkOrderNotifications();
    }
  }

  Future<void> _checkOrderNotifications() async {
    if (!isLoggedIn) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch orders that are shipped or completed
      final res = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('user_id', user.id)
          .inFilter('status', ['shipped', 'completed']);

      bool hasNotif = false;
      final List<Map<String, dynamic>> completedOrders = [];
      final Set<String> productIdsToCheck = {};

      for (var r in res) {
        final order = Map<String, dynamic>.from(r);
        final status = order['status']?.toString();

        if (status == 'shipped') {
          hasNotif = true;
          break; // Found a shipped order, show notification
        } else if (status == 'completed') {
          completedOrders.add(order);
          final items = (order['order_items'] as List?) ?? [];
          if (items.isNotEmpty) {
            final firstItem = items.first;
            final product = firstItem['products'];
            if (product != null && product['id'] != null) {
              productIdsToCheck.add(product['id'].toString());
            }
          }
        }
      }

      if (!hasNotif &&
          completedOrders.isNotEmpty &&
          productIdsToCheck.isNotEmpty) {
        // Check reviews
        final reviewsRes = await Supabase.instance.client
            .from('product_ratings')
            .select('order_item_id')
            .eq('user_id', user.id)
            .inFilter('product_id', productIdsToCheck.toList());

        final Set<String> reviewedOrderItemIds = {};
        for (var r in reviewsRes) {
          if (r['order_item_id'] != null) {
            reviewedOrderItemIds.add(r['order_item_id'].toString());
          }
        }

        for (var order in completedOrders) {
          final items = (order['order_items'] as List?) ?? [];
          if (items.isNotEmpty) {
            final firstItem = items.first;
            final orderItemId = firstItem['id']?.toString();
            if (orderItemId != null &&
                !reviewedOrderItemIds.contains(orderItemId)) {
              hasNotif = true;
              break;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _hasOrderNotification = hasNotif;
        });
      }
    } catch (e) {
      debugPrint('Error checking notifications: $e');
    }
  }

  String _getName(dynamic item) {
    if (item == null) return '';
    if (item is Map)
      return item['name']?.toString() ?? item['title']?.toString() ?? '';
    try {
      return item.name?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  double _getPrice(dynamic item) {
    if (item == null) return 0.0;
    if (item is Map) {
      final p = item['price'] ?? item['harga'] ?? item['amount'];
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p) ?? 0.0;
      return 0.0;
    }
    try {
      final p = item.price;
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p) ?? 0.0;
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  String _getImageUrl(dynamic item) {
    if (item == null) return '';
    if (item is Map)
      return (item['img_url'] ?? item['imgUrl'] ?? item['image'] ?? '')
          .toString();
    try {
      return item.imgUrl?.toString() ?? item.image?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  int _getStock(dynamic item) {
    if (item == null) return 0;
    if (item is Map) {
      final s = item['stock'];
      if (s is int) return s;
      if (s is String) return int.tryParse(s) ?? 0;
      return 0;
    }
    try {
      final s = item.stock;
      if (s is int) return s;
      if (s is String) return int.tryParse(s) ?? 0;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Product _toProduct(dynamic item) {
    if (item == null) {
      return Product(
        id: '0',
        name: '',
        price: 0,
        description: '',
        stock: 0,
        rating: 0,
        isActive: false,
        imgUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ratingCount: 0,
        ratingAvg: 0.0,
      );
    }

    if (item is Product) return item;

    if (item is Map<String, dynamic>) {
      try {
        return Product.fromJson(item);
      } catch (e) {
        // fallback mapping if Product.fromJson incompatible
        final map = Map<String, dynamic>.from(item);
        return Product(
          id: map['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: map['name']?.toString() ?? map['title']?.toString() ?? '',
          price: (map['price'] is num)
              ? (map['price'] as num).toDouble()
              : double.tryParse(map['price']?.toString() ?? '') ?? 0.0,
          description: map['description']?.toString() ?? '',
          stock: (map['stock'] is int)
              ? map['stock'] as int
              : int.tryParse(map['stock']?.toString() ?? '') ?? 0,
          rating: (map['rating'] is num)
              ? (map['rating'] as num).toDouble()
              : double.tryParse(map['rating']?.toString() ?? '') ?? 0.0,
          isActive: map['is_active'] ?? map['isActive'] ?? false,
          imgUrl: (map['img_url'] ?? map['imgUrl'] ?? map['image'] ?? '')
              .toString(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          ratingCount: (map['rating_count'] is int)
              ? map['rating_count'] as int
              : int.tryParse(map['rating_count']?.toString() ?? '') ?? 0,
          ratingAvg: (map['rating_avg'] is num)
              ? (map['rating_avg'] as num).toDouble()
              : double.tryParse(map['rating_avg']?.toString() ?? '') ?? 0.0,
        );
      }
    }

    // unknown type fallback
    return Product(
      id: '0',
      name: _getName(item),
      price: _getPrice(item),
      description: '',
      stock: 0,
      rating: 0,
      isActive: false,
      imgUrl: _getImageUrl(item),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      ratingCount: 0,
      ratingAvg: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 80,
          flexibleSpace: Container(color: Colors.black),
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Image.asset(
              'assets/images/sabi_catalog.png',
              width: screenWidth * 0.38,
              height: screenWidth * 0.14,
              fit: BoxFit.contain,
            ),
          ),
          centerTitle: false,
          actions: [
            if (!isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                    if (result == true) {
                      setState(() => isLoggedIn = true);
                    }
                  },
                  child: Text(
                    'LOGIN/SIGNUP',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            if (isLoggedIn) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserOrderPage()),
                      );
                      _checkOrderNotifications();
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    color: Colors.white70,
                    iconSize: 20,
                    padding: const EdgeInsets.only(right: 16),
                    tooltip: 'Order',
                  ),
                  if (_hasOrderNotification)
                    Positioned(
                      right: 12,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShoppingCartPage()),
                  );
                },
                icon: const Icon(Icons.shopping_bag_outlined),
                color: Colors.white70,
                iconSize: 20,
                padding: const EdgeInsets.only(right: 16),
                tooltip: 'Cart',
              ),
              IconButton(
                onPressed: () async {
                  final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfilePage()));
                  if (res == true) {
                    // optionally refresh UI
                  }
                },
                icon: const Icon(Icons.person_outline),
                color: Colors.white70,
                iconSize: 20,
                padding: const EdgeInsets.only(right: 16),
                tooltip: 'Profile',
              ),
              IconButton(
                onPressed: () async {
                  final confirm = await showLogoutDialog(context);
                  if (confirm) {
                    await Supabase.instance.client.auth.signOut();
                    setState(() => isLoggedIn = false);
                  }
                },
                icon: const Icon(Icons.logout_outlined),
                color: Colors.white70,
                iconSize: 20,
                padding: const EdgeInsets.only(right: 16),
                tooltip: 'Logout',
              ),
            ],
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshProducts,
          child: FutureBuilder<List<dynamic>>(
            future: ref.read(productRepositoryProvider).fetchAllProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No products found"));
              }

              final allProducts = snapshot.data!;
              final inStockProducts =
                  allProducts.where((item) => _getStock(item) > 0).toList();
              final soldOutProducts =
                  allProducts.where((item) => _getStock(item) == 0).toList();

              return SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // In-stock products
                        GenericGrid<dynamic>(
                          items: inStockProducts,
                          responsive: false,
                          columns: 2,
                          spacing: 24,
                          childAspectRatio: 0.6,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, item, index) {
                            final name = _getName(item);
                            final price = _getPrice(item);
                            final imgUrl = _getImageUrl(item);

                            return GestureDetector(
                              onTap: () {
                                final productModel = _toProduct(item);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailPage(
                                      product: productModel,
                                      isLoggedIn: isLoggedIn,
                                    ),
                                  ),
                                );
                              },
                              child: ProductCard(
                                imgUrl: imgUrl,
                                name: name,
                                price: price,
                              ),
                            );
                          },
                        ),
                        // Sold-out section
                        if (soldOutProducts.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          const Divider(color: Colors.white24, thickness: 1),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'SOLD OUT',
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          GenericGrid<dynamic>(
                            items: soldOutProducts,
                            responsive: false,
                            columns: 2,
                            spacing: 24,
                            childAspectRatio: 0.6,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, item, index) {
                              final name = _getName(item);
                              final imgUrl = _getImageUrl(item);

                              return GestureDetector(
                                onTap: () {
                                  final productModel = _toProduct(item);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailPage(
                                        product: productModel,
                                        isLoggedIn: isLoggedIn,
                                      ),
                                    ),
                                  );
                                },
                                child: ProductCard(
                                  imgUrl: imgUrl,
                                  name: name,
                                  price: 0,
                                  isSoldOut: true,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ));
  }
}
