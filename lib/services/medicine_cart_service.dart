import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sugenix/services/platform_settings_service.dart';
import 'package:sugenix/services/revenue_service.dart';
import 'dart:convert';

class MedicineCartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PlatformSettingsService _platformSettings = PlatformSettingsService();
  final RevenueService _revenueService = RevenueService();
  static const String _guestCartKey = 'guest_cart_items';

  String? get _uid => _auth.currentUser?.uid;

  // Get cart collection - supports both authenticated and guest users
  CollectionReference<Map<String, dynamic>>? get _cartCol {
    final uid = _uid;
    if (uid != null) {
      return _db.collection('users').doc(uid).collection('cart');
    }
    return null; // Guest user - use local storage
  }

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _db.collection('orders');

  Stream<List<Map<String, dynamic>>> streamCartItems() {
    final cartCol = _cartCol;
    if (cartCol != null) {
      // Authenticated user - stream from Firestore
      return cartCol.snapshots().map(
            (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
          );
    } else {
      // Guest user - stream from local storage
      return Stream.periodic(const Duration(milliseconds: 500), (_) async {
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString(_guestCartKey);
        if (cartJson == null) return <Map<String, dynamic>>[];
        // Parse JSON and return list
        try {
          // Simple implementation - store as JSON string
          // For now, return empty and use getCartItems() for guest
          return <Map<String, dynamic>>[];
        } catch (e) {
          return <Map<String, dynamic>>[];
        }
      }).asyncMap((future) => future);
    }
  }

  // Get cart items (works for both authenticated and guest users)
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final cartCol = _cartCol;
    if (cartCol != null) {
      // Authenticated user
      final snap = await cartCol.get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } else {
      // Guest user - get from local storage
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_guestCartKey);
      if (cartJson == null) return [];

      // Parse JSON string to list
      try {
        final List<dynamic> decoded = jsonDecode(cartJson);
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        return [];
      }
    }
  }

  Future<void> addToCart({
    required String medicineId,
    required String name,
    required double price,
    int quantity = 1,
    String? manufacturer,
  }) async {
    final cartCol = _cartCol;
    if (cartCol != null) {
      // Authenticated user - store in Firestore
      final doc = cartCol.doc(medicineId);
      final existing = await doc.get();
      if (existing.exists) {
        final q = (existing.data()!['quantity'] as int? ?? 1) + quantity;
        await doc.update({'quantity': q});
      } else {
        await doc.set({
          'medicineId': medicineId,
          'name': name,
          'price': price,
          'quantity': quantity,
          'manufacturer': manufacturer,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      // Guest user - store in local storage
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_guestCartKey);
      List<Map<String, dynamic>> items = [];

      if (cartJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cartJson);
          items =
              decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        } catch (e) {
          items = [];
        }
      }

      // Add or update item
      bool found = false;
      for (var item in items) {
        if (item['medicineId'] == medicineId) {
          item['quantity'] = (item['quantity'] as int? ?? 1) + quantity;
          found = true;
          break;
        }
      }

      if (!found) {
        items.add({
          'medicineId': medicineId,
          'name': name,
          'price': price,
          'quantity': quantity,
          'manufacturer': manufacturer,
          'id': medicineId,
        });
      }

      // Save to local storage as JSON
      await prefs.setString(_guestCartKey, jsonEncode(items));
    }
  }

  Future<void> updateQuantity(String medicineId, int quantity) async {
    final cartCol = _cartCol;
    if (cartCol != null) {
      // Authenticated user
      if (quantity <= 0) {
        await removeFromCart(medicineId);
      } else {
        await cartCol.doc(medicineId).update({'quantity': quantity});
      }
    } else {
      // Guest user - update in local storage
      if (quantity <= 0) {
        await removeFromCart(medicineId);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString(_guestCartKey);
        if (cartJson == null) return;

        try {
          final List<dynamic> decoded = jsonDecode(cartJson);
          List<Map<String, dynamic>> items =
              decoded.map((item) => Map<String, dynamic>.from(item)).toList();

          for (var item in items) {
            if (item['medicineId'] == medicineId) {
              item['quantity'] = quantity;
              break;
            }
          }

          await prefs.setString(_guestCartKey, jsonEncode(items));
        } catch (e) {
          // Handle error
        }
      }
    }
  }

  Future<void> removeFromCart(String medicineId) async {
    final cartCol = _cartCol;
    if (cartCol != null) {
      // Authenticated user
      await cartCol.doc(medicineId).delete();
    } else {
      // Guest user - remove from local storage
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_guestCartKey);
      if (cartJson == null) return;

      try {
        final List<dynamic> decoded = jsonDecode(cartJson);
        List<Map<String, dynamic>> items =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        items.removeWhere((item) => item['medicineId'] == medicineId);
        await prefs.setString(_guestCartKey, jsonEncode(items));
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> clearCart() async {
    final cartCol = _cartCol;
    if (cartCol != null) {
      // Authenticated user
      final snap = await cartCol.get();
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    } else {
      // Guest user - clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestCartKey);
      await prefs.remove('${_guestCartKey}_count');
    }
  }

  Future<String> checkout({
    required String address,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String paymentMethod = 'COD',
    String? paymentId,
    String? razorpayOrderId,
  }) async {
    // Get cart items (works for both authenticated and guest users)
    final items = await getCartItems();
    if (items.isEmpty) {
      throw Exception('Cart is empty');
    }

    double subtotal = 0.0;
    final processedItems = items.map((data) {
      final qty = (data['quantity'] as int? ?? 1);
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      subtotal += price * qty;
      return {'id': data['id'] ?? data['medicineId'], ...data};
    }).toList();

    // Get pharmacy ID from first item (if available). If not present, try looking up
    // medicine documents for ownership fields like `pharmacyId`, `pharmacy` or `owner`.
    String? pharmacyId;
    if (processedItems.isNotEmpty) {
      final firstItem = processedItems.first;
      if (firstItem.containsKey('pharmacyId')) {
        pharmacyId = firstItem['pharmacyId'] as String?;
      }
    }

    if (pharmacyId == null) {
      for (final item in processedItems) {
        final medId =
            (item['medicineId'] as String?) ?? (item['id'] as String?);
        if (medId == null || medId.isEmpty) continue;
        try {
          final medDoc = await _db.collection('medicines').doc(medId).get();
          if (!medDoc.exists) continue;
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
        } catch (e) {
          // ignore lookup errors
        }
      }
    }

    // Calculate platform fee
    final feeCalculation =
        await _platformSettings.calculatePlatformFee(subtotal);
    final platformFee = feeCalculation['platformFee'] ?? 0.0;
    final pharmacyAmount = feeCalculation['pharmacyAmount'] ?? subtotal;
    final total = feeCalculation['totalAmount'] ?? subtotal;

    final orderData = {
      'userId': _uid, // null for guest users
      'isGuest': _uid == null,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'status': paymentMethod == 'Razorpay' && paymentId != null
          ? 'confirmed'
          : 'placed',
      'subtotal': subtotal,
      'platformFee': platformFee,
      'pharmacyAmount': pharmacyAmount,
      'total': total,
      'items': processedItems, // Store items in main document for easier access
      'shippingAddress': address,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentMethod == 'Razorpay' ? 'paid' : 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      if (paymentId != null) 'paymentId': paymentId,
      if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
      if (pharmacyId != null) 'pharmacyId': pharmacyId,
    };

    final orderRef = await _ordersCol.add(orderData);

    final batch = _db.batch();
    final cartCol = _cartCol;

    for (final item in processedItems) {
      final itemRef =
          orderRef.collection('orderItems').doc(item['id'] as String);
      batch.set(itemRef, item);

      // Remove from cart (if authenticated user)
      if (cartCol != null) {
        batch.delete(cartCol.doc(item['id'] as String));
      }
    }
    await batch.commit();

    // Clear guest cart if guest user
    if (_uid == null) {
      await clearCart();
    }

    // Record revenue transaction
    try {
      await _revenueService.recordMedicineOrderRevenue(
        orderId: orderRef.id,
        pharmacyId: pharmacyId,
        userId: _uid,
        userName: customerName,
        subtotal: subtotal,
        platformFee: platformFee,
        pharmacyAmount: pharmacyAmount,
        total: total,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      // Silently fail - revenue tracking is not critical
    }

    return orderRef.id;
  }
}
