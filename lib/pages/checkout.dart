import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../provider/UserProvider.dart';

class CheckoutPage extends StatefulWidget {
  final double subtotal;
  final double tax;
  final double total;
  final List<Map<String, dynamic>> cartItems;

  const CheckoutPage({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.cartItems,
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
      // Check if cart is empty
      if (widget.cartItems.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Your cart is empty")));
        setState(() => isLoading = false);
        return;
      }

      debugPrint("=== CHECKOUT PROCESS STARTED ===");
      debugPrint("Cart items count: ${widget.cartItems.length}");
      debugPrint("Address: $address");
      debugPrint("Subtotal: ${widget.subtotal}");
      debugPrint("Total: ${widget.total}");

      // Log cart items for debugging
      for (var item in widget.cartItems) {
        debugPrint(
          "Cart Item: ${item['name']}, Qty: ${item['quantity']}, Price: ${item['price']}, MySQL ID: ${item['id']}",
        );
      }

      // Perform checkout with MySQL
      debugPrint("Calling checkout API...");
      final response = await ApiService.checkout(address);
      debugPrint("Checkout API response received: $response");

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? "Order placed successfully!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      debugPrint("=== CHECKOUT PROCESS COMPLETED SUCCESSFULLY ===");

      // Return true to indicate successful checkout
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("=== CHECKOUT FAILED ===");
      debugPrint("Error type: ${e.runtimeType}");
      debugPrint("Error message: $e");

      String errorMessage = "Checkout failed. Please try again.";

      if (e.toString().contains("Network error") ||
          e.toString().contains("No internet") ||
          e.toString().contains("SocketException")) {
        errorMessage = "Network error. Please check your internet connection.";
      } else if (e.toString().contains("Timeout")) {
        errorMessage = "Request timeout. Please try again.";
      } else if (e.toString().contains("Authentication")) {
        errorMessage = "Session expired. Please login again.";
      } else if (e.toString().contains("empty") ||
          e.toString().contains("Empty")) {
        errorMessage = "Your cart is empty. Please add items before checkout.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Section
            const Text(
              "Delivery Address",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: "Enter your complete delivery address",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Order Summary
            const Text(
              "Order Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    "Subtotal:",
                    "Rs ${widget.subtotal.toStringAsFixed(2)}",
                  ),
                  _buildSummaryRow(
                    "Tax (10%):",
                    "Rs ${widget.tax.toStringAsFixed(2)}",
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    "Total:",
                    "Rs ${widget.total.toStringAsFixed(2)}",
                    isBold: true,
                    textColor: colorScheme.primary,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Checkout Button
            SizedBox(
              width: double.infinity,
              child:
                  isLoading
                      ? _buildLoadingIndicator()
                      : ElevatedButton(
                        onPressed: _performCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Confirm Order",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          "Processing your order...",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
