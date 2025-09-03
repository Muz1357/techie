import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CheckoutPage extends StatefulWidget {
  final double subtotal;
  final double tax;
  final double total;

  const CheckoutPage({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _addressController = TextEditingController();
  bool isLoading = false;

  Future<void> _performCheckout() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your address")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiService.checkout(address);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? "Order placed successfully!"),
        ),
      );

      Navigator.pop(context, true); // Go back to Cart
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Checkout failed")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Delivery Address",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal:"),
                Text("Rs ${widget.subtotal.toStringAsFixed(2)}"),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tax:"),
                Text("Rs ${widget.tax.toStringAsFixed(2)}"),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rs ${widget.total.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Spacer(),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _performCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text(
                    "Confirm Order",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
