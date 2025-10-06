import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:techie/provider/UserProvider.dart';
import '../services/api_service.dart';

class ProductsPageWrapper extends StatelessWidget {
  const ProductsPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const ProductsPage();
  }
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with RouteAware {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("cart");
  late Future<List<dynamic>> _productsFuture;
  int _selectedIndex = 0;
  final Map<int, bool> _addingToCartMap = {}; // Track loading state per product

  static const double shakeThreshold = 15.0;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();

    accelerometerEvents.listen((event) {
      double gX = event.x / 9.81;
      double gY = event.y / 9.81;
      double gZ = event.z / 9.81;

      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > shakeThreshold / 10) {
        final now = DateTime.now();
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!).inMilliseconds > 1000) {
          _lastShakeTime = now;
          _onShake();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndexFromRoute();
  }

  // Ensure bottom nav index resets after returning from another page
  @override
  void didPopNext() {
    _updateSelectedIndexFromRoute();
  }

  void _updateSelectedIndexFromRoute() {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    switch (currentRoute) {
      case '/dashboard':
        setState(() => _selectedIndex = 0);
        break;
      case '/cart':
        setState(() => _selectedIndex = 1);
        break;
      case '/orders':
        setState(() => _selectedIndex = 2);
        break;
      case '/setting':
        setState(() => _selectedIndex = 3);
        break;
      default:
        setState(() => _selectedIndex = 0);
    }
  }

  Future<List<dynamic>> _fetchProducts() async {
    try {
      final products = await ApiService.getProducts();
      return products;
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return [];
    }
  }

  void _onShake() {
    setState(() {
      _productsFuture = _fetchProducts();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Products refreshed by shake!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addToCart(dynamic product) async {
    final int productId = product['id'];

    // Check if this product is already being added
    if (_addingToCartMap[productId] == true) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to add items to cart")),
      );
      return;
    }

    // Set loading state for this specific product
    setState(() {
      _addingToCartMap[productId] = true;
    });

    try {
      final firebaseKey = productId.toString();
      final snapshot =
          await _dbRef
              .child(userId.toString())
              .child("items")
              .child(firebaseKey)
              .get();

      if (snapshot.exists) {
        final existing = Map<String, dynamic>.from(snapshot.value as Map);
        final currentQty = _parseQuantity(existing['quantity']);
        await _dbRef
            .child(userId.toString())
            .child("items")
            .child(firebaseKey)
            .update({
              'quantity': currentQty + 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });
      } else {
        final newItem = {
          "id": null,
          "cart_id": null,
          "product_id": product['id'],
          "quantity": 1,
          "price": product['price']?.toString() ?? '0.0',
          "name": product['name'],
          "image_url": product['image_url'] ?? '',
          "is_pending": true,
          "created_at": DateTime.now().millisecondsSinceEpoch,
          "updated_at": DateTime.now().millisecondsSinceEpoch,
        };

        await _dbRef
            .child(userId.toString())
            .child("items")
            .child(firebaseKey)
            .set(newItem);

        try {
          final res = await ApiService.addToCart(product['id']);
          final mysqlItem = res['item'];
          await _dbRef
              .child(userId.toString())
              .child("items")
              .child(firebaseKey)
              .update({
                'id': mysqlItem['id'],
                'cart_id': mysqlItem['cart_id'],
                'is_pending': false,
              });
        } catch (e) {
          debugPrint("MySQL sync failed: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${product['name']} added to cart!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Add to cart error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to add to cart"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Clear loading state for this specific product
      setState(() {
        _addingToCartMap[productId] = false;
      });
    }
  }

  int _parseQuantity(dynamic q) {
    if (q == null) return 1;
    if (q is int) return q;
    if (q is String) return int.tryParse(q) ?? 1;
    if (q is double) return q.toInt();
    return 1;
  }

  void _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
        break;
      case 1:
        await Navigator.pushNamed(context, '/cart');
        _updateSelectedIndexFromRoute();
        break;
      case 2:
        await Navigator.pushNamed(context, '/orders');
        _updateSelectedIndexFromRoute();
        break;
      case 3:
        await Navigator.pushNamed(context, '/setting');
        _updateSelectedIndexFromRoute();
        break;
    }
  }

  Future<void> _logout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      userProvider.clearUser();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Orientation orientation = MediaQuery.of(context).orientation;
    final int crossAxisCount = orientation == Orientation.landscape ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: colorScheme.primary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No products available"));
          }

          final products = snapshot.data!;
          return GridView.builder(
            itemCount: products.length,
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              final int productId = product['id'];
              final bool isAdding = _addingToCartMap[productId] == true;

              return InkWell(
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/masterdetail',
                      arguments: product,
                    ),
                borderRadius: BorderRadius.circular(16),
                splashColor: colorScheme.primary.withOpacity(0.2),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.network(
                          product['image_url'] ?? '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                        ),
                        Text(
                          product['name'] ?? "No Name",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text("Rs.${product['price'] ?? "0"}"),
                        ElevatedButton.icon(
                          onPressed:
                              isAdding ? null : () => _addToCart(product),
                          icon:
                              isAdding
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.add_shopping_cart,
                                    size: 16,
                                  ),
                          label: Text(
                            isAdding ? "Adding..." : "Add to Cart",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            minimumSize: const Size.fromHeight(35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
