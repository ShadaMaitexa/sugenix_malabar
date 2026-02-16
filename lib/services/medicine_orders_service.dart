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

      // Check if item already exists in cart
      QuerySnapshot existingItem = await _firestore.collection('cart').get();
      final userId = _auth.currentUser!.uid;

      // Filter by userId and medicineId
      final matchingItems = existingItem.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['userId'] == userId && data['medicineId'] == medicineId;
      }).toList();

      if (matchingItems.isNotEmpty) {
        // Update quantity
        String cartItemId = matchingItems.first.id;
        await _firestore.collection('cart').doc(cartItemId).update({
          'quantity': FieldValue.increment(quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        await _firestore.collection('cart').add({
          'userId': _auth.currentUser!.uid,
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
    return _firestore.collection('cart').snapshots().map(
      (snapshot) {
        final allItems = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Filter by userId
        return allItems.where((item) => item['userId'] == userId).toList();
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

      QuerySnapshot cartItems = await _firestore.collection('cart').get();
      final userId = _auth.currentUser!.uid;

      // Filter by userId
      final filteredItems = cartItems.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['userId'] == userId;
      }).toList();

      for (var doc in filteredItems) {
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

      // Get cart items
      QuerySnapshot cartItems = await _firestore.collection('cart').get();

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

      // Try to determine pharmacyId for the order from items or medicine docs
      String? pharmacyId;
      for (var item in orderItems) {
        if (item.containsKey('pharmacyId') && item['pharmacyId'] != null) {
          pharmacyId = item['pharmacyId'] as String?;
          break;
        }
        // Attempt to lookup medicine document for pharmacy ownership
        try {
          final medId = item['medicineId'] as String?;
          if (medId != null && medId.isNotEmpty) {
            final medDoc = await _firestore.collection('medicines').doc(medId).get();
            if (medDoc.exists) {
              final mdata = medDoc.data() as Map<String, dynamic>;
              if (mdata.containsKey('pharmacyId') && mdata['pharmacyId'] != null) {
                pharmacyId = mdata['pharmacyId'] as String?;
                break;
              }
              if (mdata.containsKey('pharmacy') && mdata['pharmacy'] != null) {
                pharmacyId = mdata['pharmacy'] as String?;
                break;
              }
              if (mdata.containsKey('owner') && mdata['owner'] != null) {
                pharmacyId = mdata['owner'] as String?;
                break;
              }
            }
          }
        } catch (e) {
          // ignore lookup errors and continue
        }
      }

      // Create order (include pharmacyId when available)
      final orderData = {
        'userId': _auth.currentUser!.uid,
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

      DocumentReference orderRef = await _firestore.collection('orders').add(orderData);

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
    return _firestore.collection('orders').snapshots().map(
      (snapshot) {
        final allOrders = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Filter by userId and sort by createdAt
        final filtered = allOrders.where((o) => o['userId'] == userId).toList();
        filtered.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime == null || bTime == null) return 0;
          final aDate = aTime is Timestamp
              ? aTime.toDate()
              : (aTime is DateTime ? aTime : DateTime.now());
          final bDate = bTime is Timestamp
              ? bTime.toDate()
              : (bTime is DateTime ? bTime : DateTime.now());
          return bDate.compareTo(aDate); // Descending
        });
        return filtered;
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
    return _firestore.collection('prescriptions').snapshots().map(
      (snapshot) {
        final allPrescriptions = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Filter by userId and sort by createdAt
        final filtered =
            allPrescriptions.where((p) => p['userId'] == userId).toList();
        filtered.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime == null || bTime == null) return 0;
          final aDate = aTime is Timestamp
              ? aTime.toDate()
              : (aTime is DateTime ? aTime : DateTime.now());
          final bDate = bTime is Timestamp
              ? bTime.toDate()
              : (bTime is DateTime ? bTime : DateTime.now());
          return bDate.compareTo(aDate); // Descending
        });
        return filtered;
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

      // Search in medicines collection
      QuerySnapshot snapshot =
          await _firestore.collection('medicines').limit(20).get();

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
            ...data,
          });
        }
      }

      // Also try searching by description if no results
      if (results.isEmpty) {
        final descSnapshot =
            await _firestore.collection('medicines').limit(20).get();

        for (var doc in descSnapshot.docs) {
          final data = doc.data();
          final price = data['price'];
          results.add({
            'id': doc.id,
            'name': data['name'] ?? '',
            'description': data['description'] ?? '',
            'price': price is num ? price.toDouble() : 0.0,
            'manufacturer': data['manufacturer'] ?? '',
            'available': data['available'] ?? true,
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

      QuerySnapshot orders = await _firestore.collection('orders').get();
      final userId = _auth.currentUser!.uid;

      // Filter by userId
      final filteredOrders = orders.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['userId'] == userId;
      }).toList();

      int totalOrders = filteredOrders.length;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double totalSpent = 0;

      for (var doc in filteredOrders) {
        Map<String, dynamic> order = doc.data() as Map<String, dynamic>;
        String status = order['status'] as String;
        double total = (order['total'] as num?)?.toDouble() ?? 0.0;

        switch (status) {
          case 'pending':
            pendingOrders++;
            break;
          case 'completed':
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
