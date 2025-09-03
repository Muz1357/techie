import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? order;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    try {
      final data = await ApiService.getOrder(widget.orderId);
      setState(() {
        order = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Error fetching order: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (order == null) {
      return const Scaffold(body: Center(child: Text("Order not found")));
    }

    final items = order!['items'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text("Order #${order!['id']}")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final product = item['product'];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: Image.network(
                product['image_url'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(product['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Price: Rs ${item['price']}"),
                  Text("Quantity: ${item['quantity']}"),
                ],
              ),
              trailing: Text(
                "Rs ${item['price'] * item['quantity']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
