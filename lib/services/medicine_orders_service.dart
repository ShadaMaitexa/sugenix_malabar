import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sugenix/services/cloudinary_service.dart';

class MedicineOrdersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add medicine to cart
  Future<void> addToCart({
    required String medicineId,
    required String medicineName,
    required double price,
    required int quantity,
    String? prescriptionId,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Check if item already exists in cart for this user
      // Optimized: Filter by userId and medicineId in query
      QuerySnapshot existingItem = await _firestore
          .collection('cart')
          .where('userId', isEqualTo: userId)
          .where('medicineId', isEqualTo: medicineId)
          .limit(1)
          .get();

      if (existingItem.docs.isNotEmpty) {
        // Update quantity
        String cartItemId = existingItem.docs.first.id;
        await _firestore.collection('cart').doc(cartItemId).update({
          'quantity': FieldValue.increment(quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        await _firestore.collection('cart').add({
          'userId': userId,
          'medicineId': medicineId,
          'medicineName': medicineName,
          'price': price,
          'quantity': quantity,
          'prescriptionId': prescriptionId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add to cart: ${e.toString()}');
    }
  }

  // Get cart items
  Stream<List<Map<String, dynamic>>> getCartItems() {
    if (_auth.currentUser == null) return Stream.value([]);

    final userId = _auth.currentUser!.uid;
    // Optimized: Filter by userId
    return _firestore
        .collection('cart')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      },
    );
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        await _firestore.collection('cart').doc(cartItemId).delete();
      } else {
        await _firestore.collection('cart').doc(cartItemId).update({
          'quantity': quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update cart item: ${e.toString()}');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _firestore.collection('cart').doc(cartItemId).delete();
    } catch (e) {
      throw Exception('Failed to remove from cart: ${e.toString()}');
    }
  }

  // Clear entire cart
  Future<void> clearCart() async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Optimized: Filter by userId
      QuerySnapshot cartItems = await _firestore
          .collection('cart')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in cartItems.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to clear cart: ${e.toString()}');
    }
  }

  // Place order
  Future<String> placeOrder({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    String? prescriptionId,
    String? notes,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Get cart items for this user
      // Optimized: Filter by userId in query
      QuerySnapshot cartItems = await _firestore
          .collection('cart')
          .where('userId', isEqualTo: userId)
          .get();

      if (cartItems.docs.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Calculate total
      double total = 0;
      List<Map<String, dynamic>> orderItems = [];

      for (var doc in cartItems.docs) {
        Map<String, dynamic> item = doc.data() as Map<String, dynamic>;
        double itemTotal = ((item['price'] as num?)?.toDouble() ?? 0.0) *
            (item['quantity'] as int? ?? 0);
        total += itemTotal;

        orderItems.add({
          'medicineId': item['medicineId'],
          'medicineName': item['medicineName'],
          'price': item['price'],
          'quantity': item['quantity'],
        });
      }

      // Try to determine pharmacyId (logic kept from previous version but cleaned up)
      String? pharmacyId;
      for (var item in orderItems) {
        // Try to lookup one medicine to find pharmacy association
        // This is a rough heuristic but kept for consistency with original logic
        try {
          final medId = item['medicineId'] as String?;
          if (medId != null && medId.isNotEmpty) {
            final medDoc =
                await _firestore.collection('medicines').doc(medId).get();
            if (medDoc.exists) {
              final mdata = medDoc.data() as Map<String, dynamic>;
              pharmacyId = mdata['pharmacyId'] as String? ??
                  mdata['pharmacy'] as String? ??
                  mdata['owner'] as String?;
              if (pharmacyId != null) break;
            }
          }
        } catch (e) {
          // ignore lookup errors
        }
      }

      // Create order
      final orderData = {
        'userId': userId,
        'orderNumber': _generateOrderNumber(),
        'items': orderItems,
        'total': total,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'prescriptionId': prescriptionId,
        'notes': notes,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (pharmacyId != null) 'pharmacyId': pharmacyId,
      };

      DocumentReference orderRef =
          await _firestore.collection('orders').add(orderData);

      // Clear cart after successful order
      await clearCart();

      return orderRef.id;
    } catch (e) {
      throw Exception('Failed to place order: ${e.toString()}');
    }
  }

  // Get user orders
  Stream<List<Map<String, dynamic>>> getUserOrders() {
    if (_auth.currentUser == null) return Stream.value([]);

    final userId = _auth.currentUser!.uid;
    // Optimized: Filter by userId
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      },
    );
  }

  // Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      if (orderId.trim().isEmpty) return null;
      DocumentSnapshot doc =
          await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: ${e.toString()}');
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel order: ${e.toString()}');
    }
  }

  Future<String> uploadPrescription(List<XFile> images) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      List<String> imageUrls = await CloudinaryService.uploadImages(images);

      DocumentReference prescriptionRef =
          await _firestore.collection('prescriptions').add({
        'userId': _auth.currentUser!.uid,
        'imageUrls': imageUrls,
        'status': 'pending_verification',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return prescriptionRef.id;
    } catch (e) {
      throw Exception('Failed to upload prescription: ${e.toString()}');
    }
  }

  // Get prescriptions
  Stream<List<Map<String, dynamic>>> getPrescriptions() {
    if (_auth.currentUser == null) return Stream.value([]);

    final userId = _auth.currentUser!.uid;
    // Optimized: Filter by userId
    return _firestore
        .collection('prescriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      },
    );
  }

  // Search medicines
  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final queryLower = query.toLowerCase();

      // Increased limit to 100 to check more potential matches
      // Ideally, implement full text search or an indexed 'name_lower' field
      QuerySnapshot snapshot =
          await _firestore.collection('medicines').limit(100).get();

      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] as String? ?? '').toLowerCase();
        final description =
            (data['description'] as String? ?? '').toLowerCase();

        // Check if query matches name or description
        if (name.contains(queryLower) || description.contains(queryLower)) {
          results.add({
            'id': doc.id,
            'name': data['name'] ?? '',
            'description': data['description'] ?? '',
            'price': (data['price'] as num?)?.toDouble() ?? 0.0,
            'manufacturer': data['manufacturer'] ?? '',
            'available': data['available'] ?? true,
            'image': data['image'] ?? data['imageUrl'],
            ...data,
          });
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to search medicines: ${e.toString()}');
    }
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Optimized: Filter by userId in query
      QuerySnapshot orders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      int totalOrders = orders.docs.length;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double totalSpent = 0;

      for (var doc in orders.docs) {
        Map<String, dynamic> order = doc.data() as Map<String, dynamic>;
        String status = order['status'] as String? ?? 'pending';
        double total = (order['total'] as num?)?.toDouble() ?? 0.0;

        switch (status) {
          case 'pending':
            pendingOrders++;
            break;
          case 'completed':
          case 'delivered': // Assuming delivered is also completed
            completedOrders++;
            totalSpent += total;
            break;
          case 'cancelled':
            cancelledOrders++;
            break;
        }
      }

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: ${e.toString()}');
    }
  }

  // Generate order number
  String _generateOrderNumber() {
    DateTime now = DateTime.now();
    String timestamp = now.millisecondsSinceEpoch.toString();
    return 'SUG${timestamp.substring(timestamp.length - 8)}';
  }
}
