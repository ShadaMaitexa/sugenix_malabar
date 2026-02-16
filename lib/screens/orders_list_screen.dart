import 'package:flutter/material.dart';
import 'package:sugenix/services/medicine_orders_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_details_screen.dart';

class OrdersListScreen extends StatelessWidget {
  OrdersListScreen({super.key});

  final MedicineOrdersService _ordersService = MedicineOrdersService();

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'placed':
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFF0C4556);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5F6F8),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ordersService.getUserOrders(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final createdAt = order['createdAt'];
              DateTime? created;
              if (createdAt is Timestamp) {
                created = createdAt.toDate();
              } else if (createdAt is DateTime) {
                created = createdAt;
              } else if (createdAt is String) {
                created = DateTime.tryParse(createdAt);
              }
              final status = (order['status'] as String?) ?? 'pending';
              final total = (order['total'] as num?)?.toDouble() ?? 0.0;
              final orderNumber = (order['orderNumber'] as String?) ?? order['id'] as String? ?? '';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(orderId: (order['id'] ?? '').toString()),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C4556).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment, color: Color(0xFF0C4556)),
                    ),
                    title: Text(
                      'Order $orderNumber',
                      style: const TextStyle(
                        color: Color(0xFF0C4556),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      created != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(created) : '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 56),
                      child: FittedBox(
                        alignment: Alignment.center,
                        fit: BoxFit.scaleDown,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF0C4556),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ),)
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0C4556).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment, size: 56, color: Color(0xFF0C4556)),
            ),
            const SizedBox(height: 16),
            const Text(
              "No orders yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C4556),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Place your first order from Medicine section",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


