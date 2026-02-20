import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Production-Ready Order History Service
/// 
/// This service handles:
/// - Order tracking and status updates
/// - Order history retrieval
/// - Order search and filtering
/// - Order cancellation with refunds
/// - Order notifications
class OrderHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Get all orders for current user
  Stream<List<Map<String, dynamic>>> streamUserOrders({
    String? filterStatus,
    int limit = 50,
  }) {
    Query query = _db
        .collection('orders')
        .where('userId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus);
    }

    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList(),
    );
  }

  /// Get order details by ID
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final snap = await _db.collection('orders').doc(orderId).get();
      if (snap.exists) {
        return {'id': snap.id, ...snap.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('Failed to get order details: $e');
      return null;
    }
  }

  /// Get order items
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final snap = await _db
          .collection('orders')
          .doc(orderId)
          .collection('orderItems')
          .get();

      return snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Failed to get order items: $e');
      return [];
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': newStatus,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]),
      });
      return true;
    } catch (e) {
      print('Failed to update order status: $e');
      return false;
    }
  }

  /// Cancel order and initiate refund (only for pending orders)
  Future<bool> cancelOrder(
    String orderId,
    String reason,
  ) async {
    try {
      // Get order details
      final order = await getOrderDetails(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // Only allow cancellation of pending or confirmed orders
      final status = order['status'] as String?;
      if (status != 'placed' && status != 'confirmed') {
        throw Exception('Can only cancel pending or confirmed orders');
      }

      // Check if payment needs refund
      if (order['paymentMethod'] == 'Razorpay' &&
          (order['paymentStatus'] == 'paid' || order['paymentStatus'] == 'pending')) {
        // Initiate refund (would be processed by backend)
        await _db.collection('orders').doc(orderId).update({
          'status': 'cancelled',
          'cancelledReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
          'refundStatus': 'initiated',
          'paymentStatus': 'refund_pending',
        });
      } else {
        // COD order - just cancel
        await _db.collection('orders').doc(orderId).update({
          'status': 'cancelled',
          'cancelledReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Failed to cancel order: $e');
      return false;
    }
  }

  /// Track order status
  Future<List<Map<String, dynamic>>> trackOrder(String orderId) async {
    try {
      final order = await getOrderDetails(orderId);
      if (order == null) return [];

      // Return status history
      final statusHistory = order['statusHistory'] as List? ?? [];
      return List<Map<String, dynamic>>.from(statusHistory);
    } catch (e) {
      print('Failed to track order: $e');
      return [];
    }
  }

  /// Search orders
  Future<List<Map<String, dynamic>>> searchOrders(String query) async {
    try {
      // Search by order ID
      final snap1 = await _db
          .collection('orders')
          .where('userId', isEqualTo: _uid)
          .where('id', isGreaterThanOrEqualTo: query)
          .where('id', isLessThan: '${query}z')
          .get();

      // Search by customer name
      final snap2 = await _db
          .collection('orders')
          .where('userId', isEqualTo: _uid)
          .where('customerName', isGreaterThanOrEqualTo: query)
          .where('customerName', isLessThan: '${query}z')
          .get();

      // Combine and deduplicate
      final results = <String, Map<String, dynamic>>{};
      for (final doc in snap1.docs) {
        final data = doc.data();
        results[doc.id] = {'id': doc.id, ...data};
      }
      for (final doc in snap2.docs) {
        final data = doc.data() ;
        results[doc.id] = {'id': doc.id, ...data};
      }

      return results.values.toList();
    } catch (e) {
      print('Failed to search orders: $e');
      return [];
    }
  }

  /// Get order summary
  Future<Map<String, dynamic>?> getOrderSummary(String orderId) async {
    try {
      final order = await getOrderDetails(orderId);
      if (order == null) return null;

      final items = await getOrderItems(orderId);

      return {
        'orderId': orderId,
        'status': order['status'],
        'paymentMethod': order['paymentMethod'],
        'paymentStatus': order['paymentStatus'],
        'customerName': order['customerName'],
        'customerEmail': order['customerEmail'],
        'customerPhone': order['customerPhone'],
        'shippingAddress': order['shippingAddress'],
        'subtotal': order['subtotal'],
        'platformFee': order['platformFee'],
        'total': order['total'],
        'itemCount': items.length,
        'items': items,
        'createdAt': order['createdAt'],
        'estDeliveryDate': order['estDeliveryDate'],
        'paymentId': order['paymentId'],
      };
    } catch (e) {
      print('Failed to get order summary: $e');
      return null;
    }
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      // Total orders
      final totalSnap = await _db
          .collection('orders')
          .where('userId', isEqualTo: _uid)
          .count()
          .get();

      // Pending orders
      final pendingSnap = await _db
          .collection('orders')
          .where('userId', isEqualTo: _uid)
          .where('status', isEqualTo: 'placed')
          .count()
          .get();

      // Confirmed orders
      final confirmedSnap = await _db
          .collection('orders')
          .where('userId', isEqualTo: _uid)
          .where('status', isEqualTo: 'confirmed')
          .count()
          .get();

      // Get total spending
      final ordersSnap = await _db
          .collection('orders')
          .where('userId', isEqualTo: _uid)
          .get();

      double totalSpent = 0;
      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        totalSpent += (data['total'] as num?)?.toDouble() ?? 0;
      }

      return {
        'totalOrders': totalSnap.count,
        'pendingOrders': pendingSnap.count,
        'confirmedOrders': confirmedSnap.count,
        'totalSpent': totalSpent,
        'averageOrderValue':
            totalSnap.count! > 0 ? totalSpent / totalSnap.count! : 0,
      };
    } catch (e) {
      print('Failed to get order statistics: $e');
      return {
        'totalOrders': 0,
        'pendingOrders': 0,
        'confirmedOrders': 0,
        'totalSpent': 0,
        'averageOrderValue': 0,
      };
    }
  }

  /// Export order receipt as text
  Future<String> exportOrderAsText(String orderId) async {
    try {
      final summary = await getOrderSummary(orderId);
      if (summary == null) throw Exception('Order not found');

      final buffer = StringBuffer();
      buffer.writeln('=== SUGENIX ORDER RECEIPT ===');
      buffer.writeln('Order ID: ${summary['orderId']}');
      buffer.writeln('Date: ${summary['createdAt']}');
      buffer.writeln('');
      buffer.writeln('CUSTOMER DETAILS:');
      buffer.writeln('Name: ${summary['customerName']}');
      buffer.writeln('Email: ${summary['customerEmail']}');
      buffer.writeln('Phone: ${summary['customerPhone']}');
      buffer.writeln('');
      buffer.writeln('SHIPPING ADDRESS:');
      buffer.writeln(summary['shippingAddress']);
      buffer.writeln('');
      buffer.writeln('ORDER ITEMS:');
      for (final item in summary['items'] as List) {
        buffer.writeln(
            '- ${item['name']} x${item['quantity']} @ ₹${item['price']}');
      }
      buffer.writeln('');
      buffer.writeln('ORDER SUMMARY:');
      buffer.writeln('Subtotal: ₹${summary['subtotal']}');
      buffer.writeln('Platform Fee: ₹${summary['platformFee']}');
      buffer.writeln('Total: ₹${summary['total']}');
      buffer.writeln('');
      buffer.writeln('PAYMENT:');
      buffer.writeln('Method: ${summary['paymentMethod']}');
      buffer.writeln('Status: ${summary['paymentStatus']}');
      if (summary['paymentId'] != null) {
        buffer.writeln('Payment ID: ${summary['paymentId']}');
      }
      buffer.writeln('');
      buffer.writeln('DELIVERY:');
      buffer.writeln('Est. Delivery: ${summary['estDeliveryDate']}');
      buffer.writeln('');
      buffer.writeln('===== Thank you for your order! =====');

      return buffer.toString();
    } catch (e) {
      print('Failed to export order: $e');
      return '';
    }
  }
}
