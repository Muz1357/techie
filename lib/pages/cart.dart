// lib/pages/cart.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../provider/UserProvider.dart';
import '../services/api_service.dart';
import 'checkout.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("cart");
  bool _isLoading = true;
  bool _isOnline = true;
  List<Map<String, dynamic>> _cartItems = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline =
          results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
    });

    // If we just came back online, sync pending items
    if (_isOnline) {
      _syncPendingItems();
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final wasOffline = !_isOnline;
      setState(() {
        _isOnline =
            results.isNotEmpty &&
            results.any((r) => r != ConnectivityResult.none);
      });

      // If we just came back online, sync pending items
      if (wasOffline && _isOnline) {
        _syncPendingItems();
      }
    });
  }

  Future<void> _syncPendingItems() async {
    if (!_isOnline) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) return;

    try {
      debugPrint('Syncing pending items...');
      // You can implement specific sync logic here for pending items
      // For now, we'll just reload the cart to ensure consistency
      await _loadCart();
    } catch (e) {
      debugPrint('Error syncing pending items: $e');
    }
  }

  Future<void> _loadCart() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot =
          await _dbRef.child(userId.toString()).child("items").get();

      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final items = <Map<String, dynamic>>[];

        data.forEach((key, value) {
          try {
            if (value != null) {
              final item = Map<String, dynamic>.from(value);
              if (item['is_pending_deletion'] != true) {
                item['firebase_key'] = key.toString();
                items.add(item);
              }
            }
          } catch (e) {
            debugPrint("Error parsing cart item $key: $e");
          }
        });

        setState(() {
          _cartItems = items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _cartItems = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading cart: $e");
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(String firebaseKey, int newQuantity) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) return;

    // Update local UI immediately
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item['firebase_key'] == firebaseKey,
      );
      if (index != -1) {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });

    try {
      // Update Firebase
      await _dbRef
          .child(userId.toString())
          .child("items")
          .child(firebaseKey)
          .update({
            'quantity': newQuantity,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });

      // If online and item has MySQL ID, update MySQL too
      final item = _cartItems.firstWhere(
        (item) => item['firebase_key'] == firebaseKey,
      );
      if (_isOnline && item['id'] != null) {
        await ApiService.updateCartItem(item['id'], newQuantity);
      }
    } catch (e) {
      debugPrint("Error updating quantity: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating quantity'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromCart(String firebaseKey) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) return;

    final itemIndex = _cartItems.indexWhere(
      (item) => item['firebase_key'] == firebaseKey,
    );
    if (itemIndex == -1) return;

    final item = Map<String, dynamic>.from(_cartItems[itemIndex]);

    // Store item data before removing from UI
    final itemId = item['id'];
    final itemName = item['name']?.toString() ?? 'Unknown item';

    // Remove from UI immediately
    setState(() {
      _cartItems.removeAt(itemIndex);
    });

    try {
      if (_isOnline && itemId != null) {
        // Try to remove from MySQL first when online
        try {
          await ApiService.removeCartItem(itemId);
          debugPrint('Successfully removed item $itemId from MySQL');
        } catch (mysqlError) {
          debugPrint('Error removing from MySQL: $mysqlError');
          // Even if MySQL fails, we should still remove from Firebase
          // to maintain consistency in the UI
        }
      }

      // Always remove from Firebase (single source of truth for UI)
      await _dbRef
          .child(userId.toString())
          .child("items")
          .child(firebaseKey)
          .remove();

      debugPrint('Successfully removed item from Firebase');
    } catch (e) {
      debugPrint("Error removing from cart: $e");

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove "$itemName" from cart'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Reload cart to restore UI consistency
      await _loadCart();
    }
  }

  Future<void> _clearCart() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) return;

    setState(() {
      _cartItems.clear();
    });

    try {
      await _dbRef.child(userId.toString()).remove();
      debugPrint('Successfully cleared cart from Firebase');
    } catch (e) {
      debugPrint("Error clearing cart: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error clearing cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Reload cart to restore UI consistency
      await _loadCart();
    }
  }

  PreferredSizeWidget _buildAppBar(ColorScheme scheme) {
    return AppBar(
      title: const Text('Shopping Cart'),
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      actions: [
        if (!_isOnline)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.offline_bolt, color: Colors.orange, size: 20),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.userId;

    if (userId == null) {
      return _buildLoginRequired();
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(scheme),
      body: Stack(
        children: [
          if (_cartItems.isEmpty && !_isLoading) _buildEmptyCart(),
          if (_cartItems.isNotEmpty) _buildCartWithItems(scheme),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please log in to view your cart',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Add some products to get started!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems(ColorScheme scheme) {
    final subtotal = _cartItems.fold(0.0, (sum, item) {
      final price = _parsePrice(item['price']);
      final quantity = _parseQuantity(item['quantity']);
      return sum + (price * quantity);
    });
    final tax = subtotal * 0.10;
    final total = subtotal * 1.10;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (!_isOnline) _offlineBanner(),
          Expanded(child: _buildCartItems()),
          _buildTotalSection(subtotal, tax, total, scheme),
        ],
      ),
    );
  }

  Widget _offlineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 20, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline Mode - Changes will sync when back online',
              style: TextStyle(color: Colors.orange[800], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        final price = _parsePrice(item['price']);
        final quantity = _parseQuantity(item['quantity']);
        final firebaseKey = item['firebase_key']?.toString() ?? '';
        final isPending = item['is_pending'] == true || item['id'] == null;

        return CartItemWidget(
          key: ValueKey(firebaseKey),
          item: item,
          price: price,
          quantity: quantity,
          itemTotal: price * quantity,
          isPending: isPending,
          onRemove:
              () => _showDeleteConfirmation(
                context,
                item['name']?.toString() ?? 'item',
                () => _removeFromCart(firebaseKey),
              ),
          onUpdateQuantity: (newQty) => _updateQuantity(firebaseKey, newQty),
        );
      },
    );
  }

  Widget _buildTotalSection(
    double subtotal,
    double tax,
    double total,
    ColorScheme scheme,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildTotalRow('Subtotal:', 'Rs ${subtotal.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildTotalRow('Tax (10%):', 'Rs ${tax.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildTotalRow(
                'Total:',
                'Rs ${total.toStringAsFixed(2)}',
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CheckoutPage(
                        subtotal: subtotal,
                        tax: tax,
                        total: total,
                        cartItems: _cartItems,
                      ),
                ),
              );
              if (result == true && mounted) {
                await _clearCart();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order placed successfully!')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Proceed to Checkout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String itemName,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Item'),
            content: Text(
              'Are you sure you want to remove "$itemName" from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  int _parseQuantity(dynamic q) {
    if (q == null) return 1;
    if (q is int) return q;
    if (q is String) return int.tryParse(q) ?? 1;
    if (q is double) return q.toInt();
    return 1;
  }

  double _parsePrice(dynamic p) {
    if (p == null) return 0.0;
    if (p is double) return p;
    if (p is int) return p.toDouble();
    if (p is String) return double.tryParse(p) ?? 0.0;
    return 0.0;
  }
}

// Item tile widget
class CartItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final double price;
  final int quantity;
  final double itemTotal;
  final bool isPending;
  final VoidCallback onRemove;
  final Function(int) onUpdateQuantity;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.price,
    required this.quantity,
    required this.itemTotal,
    required this.isPending,
    required this.onRemove,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1.5,
      child: ListTile(
        leading: _buildItemImage(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['name']?.toString() ?? 'Unknown Product',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (isPending)
              const Icon(Icons.sync, size: 16, color: Colors.orange),
          ],
        ),
        subtitle: _buildItemDetails(),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
          onPressed: onRemove,
        ),
      ),
    );
  }

  Widget _buildItemImage() {
    final url = item['image_url']?.toString() ?? '';
    if (url.isEmpty) return _placeholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: 120,
        cacheHeight: 120,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder:
            (context, child, progress) =>
                progress == null ? child : _loadingBox(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 30, color: Colors.grey),
    );
  }

  Widget _loadingBox() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildItemDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'Price: Rs ${price.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Total: Rs ${itemTotal.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (isPending) _buildPendingSyncIndicator(),
        const SizedBox(height: 8),
        _buildQuantityControls(),
      ],
    );
  }

  Widget _buildPendingSyncIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync, size: 12, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            'Pending sync',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          onPressed: quantity > 1 ? () => onUpdateQuantity(quantity - 1) : null,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: () => onUpdateQuantity(quantity + 1),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
