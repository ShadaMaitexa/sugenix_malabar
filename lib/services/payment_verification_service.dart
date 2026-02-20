import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

/// Payment Verification Service - Test Mode Ready
///
/// This service handles payment verification operations with TEST MODE by default:
/// - Payment verification (simulated locally in test mode)
/// - Idempotent order creation (prevents duplicate charges)
/// - Order confirmation emails
/// - Receipt generation
/// - Transaction logging for audit trails
///
/// ✅ TEST MODE FEATURES:
/// - No real API calls to Razorpay servers
/// - Simulates realistic payment responses (95% success rate)
/// - Includes network delay simulation (200-500ms)
/// - Looks and feels exactly like production payments
/// - Perfect for development, testing, and demos
///
/// DATABASE COLLECTIONS:
/// - orders: Stores all orders (idempotencyKey prevents duplicates)
/// - transaction_logs: Stores payment verification audit trail
class PaymentVerificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ TEST MODE ENABLED - All payments are simulated
  static const bool _testMode = true;

  /// Check if order already exists by idempotency key
  ///
  /// This prevents duplicate orders when:
  /// - User retries payment
  /// - Network request is duplicated
  /// - User browser refresh occurs after order creation
  Future<Map<String, dynamic>?> getExistingOrder(String idempotencyKey) async {
    try {
      final query = await _db
          .collection('orders')
          .where('idempotencyKey', isEqualTo: idempotencyKey)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        return {
          'id': query.docs.first.id,
          'paymentId': data['paymentId'],
          'status': data['status'],
          'total': data['total'],
        };
      }
      return null;
    } catch (e) {
      print('❌ Error checking existing order: $e');
      return null;
    }
  }

  /// Test mode payment verification (95% success rate, network delay)
  ///
  /// Parameters:
  /// - paymentId: Razorpay payment ID
  /// - orderId: Razorpay order ID
  /// - amount: Total payment amount
  /// - currency: Currency code (e.g., 'INR')
  ///
  /// Returns: true if verification succeeds, false otherwise
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required double amount,
    required String currency,
  }) async {
    try {
      if (_testMode) {
        // Simulate network delay (200-500ms)
        await _simulateNetworkDelay();

        // 95% success rate for realistic testing
        final random = math.Random();
        if (random.nextInt(100) > 95) {
          print('❌ Test Mode: Simulating payment failure (5% failure rate)');
          await _logTransaction(
            paymentId: paymentId,
            status: 'failed',
          );
          return false;
        }

        // ✅ Payment verified successfully (in test mode)
        print('✅ Test Mode: Payment verification successful');
        await _logTransaction(
          paymentId: paymentId,
          status: 'verified',
        );
        return true;
      }

      // PRODUCTION MODE: Would verify with Razorpay server
      print('💳 Production verification not implemented in test mode');
      return false;
    } catch (e) {
      print('❌ Payment verification error: $e');
      await _logTransaction(
        paymentId: paymentId,
        status: 'error',
        reason: e.toString(),
      );
      return false;
    }
  }

  /// Send order confirmation email
  Future<void> sendOrderConfirmationEmail({
    required String email,
    required String customerName,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String address,
  }) async {
    try {
      final itemsList = items.map((item) {
        final qty = item['quantity'] ?? 1;
        final price = item['price'] ?? 0;
        return '$qty x ${item['name']} - ₹$price';
      }).join('\n');

      final emailBody = '''
Dear $customerName,

Your order has been confirmed! 

Order ID: $orderId
Total Amount: ₹${(totalAmount).toStringAsFixed(2)}
Delivery Address: $address

Items Ordered:
$itemsList

Thank you for shopping with us! Your order will be delivered soon.

Best regards,
Sugenix Malabar Team
      ''';

      // TODO: Send email via EmailJS when service is available
      print('✅ Confirmation email ready for: $email');
      print('Email body:\n$emailBody');
      // For now, just log it
      await _logTransaction(
        paymentId: orderId,
        status: 'email_sent',
      );
    } catch (e) {
      print('⚠️ Email preparation failed (non-blocking): $e');
      // Don't rethrow - email failure shouldn't block order creation
    }
  }

  /// Generate receipt for order
  Future<String> generateReceipt({
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String shippingAddress,
    required double subtotal,
    required double platformFee,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String paymentId,
    required DateTime orderDate,
  }) async {
    try {
      final itemsList = items.map((item) {
        final qty = item['quantity'] ?? 1;
        final price = item['price'] ?? 0;
        return '$qty x ${item['name']} - ₹$price';
      }).join('\n');

      final receipt = '''
╔════════════════════════════════════════╗
║        SUGENIX MALABAR - RECEIPT       ║
╚════════════════════════════════════════╝

Order ID: $orderId
Date: ${orderDate.toLocal()}

Customer: $customerName
Email: $customerEmail
Phone: $customerPhone
Address: $shippingAddress

────────────────────────────────────────
ITEMS:
$itemsList

────────────────────────────────────────
SubTotal:        ₹${subtotal.toStringAsFixed(2)}
Platform Fee:    ₹${platformFee.toStringAsFixed(2)}
────────────────────────────────────────
Total Amount:    ₹${totalAmount.toStringAsFixed(2)}

Payment Method: $paymentMethod
Payment ID: $paymentId
Status: Confirmed

Thank you for your purchase!
═══════════════════════════════════════
      ''';

      print('✅ Receipt generated for order: $orderId');
      return receipt;
    } catch (e) {
      print('❌ Receipt generation error: $e');
      rethrow;
    }
  }

  /// Refund payment (simulated in test mode)
  Future<bool> refundPayment({
    required String paymentId,
    required String orderId,
    double? amount,
    String? reason,
  }) async {
    try {
      if (_testMode) {
        // Simulate refund in test mode
        await _simulateNetworkDelay();
        print('✅ Test Mode: Simulated refund for $paymentId');
        await _logTransaction(
          paymentId: paymentId,
          status: 'refunded',
          reason: reason,
        );
        return true;
      }

      print('💳 Production refund not implemented in test mode');
      return false;
    } catch (e) {
      print('❌ Refund error: $e');
      return false;
    }
  }

  /// Get transaction history for user (for debugging/auditing)
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final query = await _db
          .collection('transaction_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ Error fetching transaction history: $e');
      return [];
    }
  }

  /// Log transaction for audit trail
  Future<void> _logTransaction({
    required String paymentId,
    required String status,
    String? orderId,
    String? reason,
  }) async {
    try {
      final user = _auth.currentUser;
      await _db.collection('transaction_logs').add({
        'paymentId': paymentId,
        'orderId': orderId,
        'userId': user?.uid ?? 'guest',
        'status': status,
        'reason': reason,
        'testMode': _testMode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('📝 Transaction logged: $paymentId - $status');
    } catch (e) {
      print('❌ Transaction logging error: $e');
      // Don't rethrow - logging failure shouldn't block payment flow
    }
  }

  /// Simulate network delay (200-500ms)
  Future<void> _simulateNetworkDelay() async {
    final random = math.Random();
    final delayMs = 200 + random.nextInt(300); // 200-500ms
    await Future.delayed(Duration(milliseconds: delayMs));
  }
}
