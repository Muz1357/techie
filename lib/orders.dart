import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Dummy order list
    final List<Map<String, dynamic>> orders = [
      {
        'id': 'ORD001',
        'date': '2025-06-01',
        'status': 'Delivered',
        'total': 499.00,
      },
      {
        'id': 'ORD002',
        'date': '2025-06-04',
        'status': 'Processing',
        'total': 899.00,
      },
      {
        'id': 'ORD003',
        'date': '2025-06-06',
        'status': 'Cancelled',
        'total': 349.50,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
        backgroundColor: colorScheme.primary,
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final order = orders[index];
          final statusColor = _getStatusColor(order['status'], colorScheme);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: colorScheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID: ${order['id']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${order['date']}',
                  style: TextStyle(color: Colors.black),
                ),
                Text(
                  'Total: \$${order['total'].toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order['status'],
                        style: TextStyle(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme scheme) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'processing':
        return scheme.primary;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
