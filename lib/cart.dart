import 'package:flutter/material.dart';

class Cart extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems = [
    {
      'name': 'Samsung A53',
      'price': 10000.00,
      'quantity': 2,
      'image': 'assets/images/phone.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var item in cartItems) {
      subtotal += item['price'] * item['quantity'];
    }
    double tax = subtotal * 0.05;
    double total = subtotal + tax;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  var item = cartItems[index];
                  double itemTotal = item['price'] * item['quantity'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Image.asset(
                        'assets/images/phone.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      title: Text(item['name']),
                      subtitle: Text('Qty: ${item['quantity']}'),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('\$${item['price'].toStringAsFixed(2)}'),
                          Text(
                            'Total: \$${itemTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Divider(height: 32),

            // Checkout info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text('\$${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax (5%):'),
                Text('\$${tax.toStringAsFixed(2)}'),
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
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(
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
