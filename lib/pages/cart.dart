import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'checkout.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  List<dynamic> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.getCart();
      setState(() {
        cartItems = response['items'] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load cart")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _removeItem(int itemId) async {
    final success = await ApiService.removeCartItem(itemId);
    if (success) {
      setState(() {
        cartItems.removeWhere((item) => item['id'] == itemId);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to remove item")));
    }
  }

  Future<void> _updateQuantity(int itemId, int newQty) async {
    try {
      await ApiService.updateCartItem(itemId, newQty);
      setState(() {
        final index = cartItems.indexWhere((item) => item['id'] == itemId);
        if (index != -1) {
          cartItems[index]['quantity'] = newQty;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update quantity")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var item in cartItems) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final qty =
          (item['quantity'] is int)
              ? item['quantity'] as int
              : int.tryParse(item['quantity'].toString()) ?? 1;

      subtotal += price * qty;
    }
    double tax = subtotal * 0.10;
    double total = subtotal + tax;

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: colorScheme.primary,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child:
                          cartItems.isEmpty
                              ? const Center(child: Text("Your cart is empty."))
                              : ListView.builder(
                                itemCount: cartItems.length,
                                itemBuilder: (context, index) {
                                  var item = cartItems[index];
                                  var product = item['product'] ?? {};

                                  final price =
                                      double.tryParse(
                                        item['price'].toString(),
                                      ) ??
                                      0.0;
                                  final qty =
                                      (item['quantity'] is int)
                                          ? item['quantity'] as int
                                          : int.tryParse(
                                                item['quantity'].toString(),
                                              ) ??
                                              1;
                                  double itemTotal = price * qty;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      leading:
                                          (product['image_url'] != null)
                                              ? Image.network(
                                                product['image_url'],
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              )
                                              : const Icon(
                                                Icons.image,
                                                size: 60,
                                              ),
                                      title: Text(product['name'] ?? 'Unknown'),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed:
                                                    qty > 1
                                                        ? () => _updateQuantity(
                                                          item['id'],
                                                          qty - 1,
                                                        )
                                                        : null,
                                              ),
                                              Text("$qty"),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed:
                                                    () => _updateQuantity(
                                                      item['id'],
                                                      qty + 1,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Total: Rs ${itemTotal.toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _removeItem(item['id']),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),

                    const Divider(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('Rs ${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax (10%):'),
                        Text('Rs ${tax.toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rs ${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed:
                          cartItems.isEmpty
                              ? null
                              : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CheckoutPage(
                                          subtotal: subtotal,
                                          tax: tax,
                                          total: total,
                                        ),
                                  ),
                                );

                                if (result == true) {
                                  setState(() {
                                    cartItems
                                        .clear(); // clear cart after checkout
                                  });
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
