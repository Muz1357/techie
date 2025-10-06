import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/api_service.dart';
import '../provider/UserProvider.dart';

class MasterDetailScreen extends StatefulWidget {
  const MasterDetailScreen({super.key});

  @override
  State<MasterDetailScreen> createState() => _MasterDetailScreenState();
}

class _MasterDetailScreenState extends State<MasterDetailScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("cart");
  bool _isAddingToCart = false;
  int _currentQuantityInCart = 0;
  dynamic _product;
  bool _isInitialized = false;
  Map<String, dynamic>? _cartItem;

  @override
  void initState() {
    super.initState();
    // Don't access context here at all
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      // Get product from route arguments
      _product = ModalRoute.of(context)!.settings.arguments as dynamic;
      _checkCurrentQuantity();
      _isInitialized = true;
    }
  }

  Future<void> _checkCurrentQuantity() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null || _product == null) return;

    try {
      final snapshot =
          await _dbRef
              .child(userId.toString())
              .child("items")
              .child(_product['id'].toString())
              .get();

      if (snapshot.exists && mounted) {
        final item = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _cartItem = item;
          _currentQuantityInCart = _parseQuantity(item['quantity']);
        });
      } else if (mounted) {
        setState(() {
          _cartItem = null;
          _currentQuantityInCart = 0;
        });
      }
    } catch (e) {
      debugPrint("Error checking cart quantity: $e");
      if (mounted) {
        setState(() {
          _cartItem = null;
          _currentQuantityInCart = 0;
        });
      }
    }
  }

  // Helper method to safely parse price
  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      // Remove any non-numeric characters except decimal point
      final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to parse quantity
  int _parseQuantity(dynamic q) {
    if (q == null) return 1;
    if (q is int) return q;
    if (q is String) return int.tryParse(q) ?? 1;
    if (q is double) return q.toInt();
    return 1;
  }

  // Helper method to format price for display
  String _formatPrice(dynamic price) {
    final parsedPrice = _parsePrice(price);
    return parsedPrice.toStringAsFixed(2);
  }

  Future<void> _addToCart() async {
    if (_isAddingToCart) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to add items to cart")),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isAddingToCart = true;
      });
    }

    try {
      final firebaseKey = _product['id'].toString();

      // Create new item data matching MySQL structure
      final newItem = {
        "id": null,
        "cart_id": null,
        "product_id": _product['id'],
        "quantity": 1,
        "price": _product['price']?.toString() ?? '0.0',
        "name": _product['name'],
        "image_url": _product['image_url'] ?? '',
        "is_pending": true,
        "created_at": DateTime.now().millisecondsSinceEpoch,
        "updated_at": DateTime.now().millisecondsSinceEpoch,
      };

      // Save to Firebase
      await _dbRef
          .child(userId.toString())
          .child("items")
          .child(firebaseKey)
          .set(newItem);

      // Update local state
      if (mounted) {
        setState(() {
          _cartItem = newItem;
          _currentQuantityInCart = 1;
        });
      }

      // Try to sync with MySQL if online
      try {
        final res = await ApiService.addToCart(_product['id']);
        final mysqlItem = res['item'];

        // Update Firebase with MySQL data
        await _dbRef
            .child(userId.toString())
            .child("items")
            .child(firebaseKey)
            .update({
              'id': mysqlItem['id'],
              'cart_id': mysqlItem['cart_id'],
              'is_pending': false,
            });

        // Update local state
        if (mounted) {
          setState(() {
            _cartItem?['id'] = mysqlItem['id'];
            _cartItem?['cart_id'] = mysqlItem['cart_id'];
            _cartItem?['is_pending'] = false;
          });
        }
      } catch (mysqlError) {
        debugPrint("MySQL sync failed: $mysqlError");
        // Item remains as pending, will sync later
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${_product['name']} added to cart!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Add to cart error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to add item to cart"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Future<void> _updateQuantity(int newQuantity) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null || _cartItem == null) return;

    if (mounted) {
      setState(() {
        _isAddingToCart = true;
      });
    }

    try {
      final firebaseKey = _product['id'].toString();

      if (newQuantity == 0) {
        // Remove item if quantity is 0
        if (_cartItem?['id'] != null) {
          // If has MySQL ID, try to remove from MySQL
          try {
            await ApiService.removeCartItem(_cartItem!['id']);
            await _dbRef
                .child(userId.toString())
                .child("items")
                .child(firebaseKey)
                .remove();
          } catch (e) {
            // If MySQL fails, mark for deletion
            await _dbRef
                .child(userId.toString())
                .child("items")
                .child(firebaseKey)
                .update({'is_pending_deletion': true});
          }
        } else {
          // No MySQL ID, just mark for deletion
          await _dbRef
              .child(userId.toString())
              .child("items")
              .child(firebaseKey)
              .update({'is_pending_deletion': true});
        }

        if (mounted) {
          setState(() {
            _cartItem = null;
            _currentQuantityInCart = 0;
          });
        }
      } else {
        // Update quantity
        await _dbRef
            .child(userId.toString())
            .child("items")
            .child(firebaseKey)
            .update({
              'quantity': newQuantity,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            });

        // If online and item has MySQL ID, update MySQL too
        if (_cartItem?['id'] != null) {
          try {
            await ApiService.updateCartItem(_cartItem!['id'], newQuantity);
          } catch (e) {
            debugPrint("MySQL update failed: $e");
          }
        }

        if (mounted) {
          setState(() {
            _currentQuantityInCart = newQuantity;
            _cartItem?['quantity'] = newQuantity;
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newQuantity == 0
                  ? "Item removed from cart"
                  : "Quantity updated to $newQuantity",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Update quantity error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to update quantity"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized yet, show loading
    if (!_isInitialized || _product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Details'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_product['name'] ?? 'Product Details'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child:
                    (_product['image_url'] != null &&
                            _product['image_url'].toString().isNotEmpty)
                        ? Image.network(
                          _product['image_url'],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                          errorBuilder:
                              (context, error, stackTrace) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),

            // Product Name
            Text(
              _product['name'] ?? 'No Name',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            // Product Price - FIXED
            Text(
              "Rs. ${_formatPrice(_product['price'])}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // Current Quantity in Cart
            if (_currentQuantityInCart > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "In cart: $_currentQuantityInCart",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_cartItem?['is_pending'] == true)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.sync, size: 14, color: Colors.orange),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Product Description
            Text(
              _product['description'] ??
                  "No description available for this product.",
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Add to Cart / Quantity Controls
            if (_currentQuantityInCart == 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isAddingToCart ? null : _addToCart,
                  child:
                      _isAddingToCart
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Add to Cart',
                            style: TextStyle(fontSize: 18),
                          ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Update Quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Decrease Quantity
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                          iconSize: 30,
                          onPressed:
                              _isAddingToCart
                                  ? null
                                  : () => _updateQuantity(
                                    _currentQuantityInCart - 1,
                                  ),
                        ),

                        // Current Quantity
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_currentQuantityInCart',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),

                        // Increase Quantity
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.green,
                          iconSize: 30,
                          onPressed:
                              _isAddingToCart
                                  ? null
                                  : () => _updateQuantity(
                                    _currentQuantityInCart + 1,
                                  ),
                        ),
                      ],
                    ),

                    // Remove from Cart Button
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed:
                            _isAddingToCart ? null : () => _updateQuantity(0),
                        child: const Text('Remove from Cart'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
