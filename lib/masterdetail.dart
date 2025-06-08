import 'package:flutter/material.dart';

class MasterDetailScreen extends StatelessWidget {
  const MasterDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: colorScheme.primary,
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
                child: Image.asset(
                  'assets/images/phone.png',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Product Title
            Text(
              'Samsung A53',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            // Product Price
            Text(
              '\$499.00',
              style: TextStyle(fontSize: 20, color: colorScheme.secondary),
            ),
            const SizedBox(height: 16),

            // Product Description
            const Text(
              'This is the Samsung Galaxy A53, featuring a stunning Super AMOLED display, long-lasting battery life, and a high-quality camera setup. Great for performance and style.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Added to cart!"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
