import 'package:cloud_firestore/cloud_firestore.dart';

class RevenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Platform fee percentage (10% of consultation fee)
  static const double platformFeePercentage = 0.10;
  static const double minimumPlatformFee = 10.0; // Minimum ₹10 platform fee

  // Calculate fees for an appointment
  static Map<String, double> calculateFees(double consultationFee) {
    final platformFee = (consultationFee * platformFeePercentage).clamp(
      minimumPlatformFee,
      consultationFee * 0.15, // Max 15%
    );
    final doctorFee = consultationFee - platformFee;
    final totalFee = consultationFee + platformFee; // Total customer pays = consultation fee + platform fee

    return {
      'totalFee': totalFee,
      'consultationFee': consultationFee,
      'platformFee': platformFee,
      'doctorFee': doctorFee,
    };
  }

  // Record revenue transaction
  Future<void> recordRevenue({
    required String appointmentId,
    required String doctorId,
    required String patientId,
    required double consultationFee,
    required double platformFee,
    required double doctorFee,
    String? paymentMethod,
  }) async {
    try {
      final fees = calculateFees(consultationFee);
      
      // Record admin revenue (platform fee)
      await _firestore.collection('revenue').add({
        'type': 'platform_fee',
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'patientId': patientId,
        'amount': fees['platformFee'],
        'consultationFee': consultationFee,
        'platformFee': fees['platformFee'],
        'doctorFee': fees['doctorFee'],
        'paymentMethod': paymentMethod ?? 'online',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Record doctor revenue (consultation fee - platform fee)
      final doctorFeeAmount = fees['doctorFee'] ?? 0.0;
      final platformFeeAmount = fees['platformFee'] ?? 0.0;
      await _firestore.collection('revenue').add({
        'type': 'doctor_fee',
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'patientId': patientId,
        'amount': doctorFeeAmount,
        'consultationFee': consultationFee,
        'platformFee': platformFeeAmount,
        'doctorFee': doctorFeeAmount,
        'paymentMethod': paymentMethod ?? 'online',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update admin total revenue
      await _updateAdminRevenue(platformFeeAmount);
      
      // Update doctor total revenue
      await _updateDoctorRevenue(doctorId, doctorFeeAmount);
    } catch (e) {
      throw Exception('Failed to record revenue: ${e.toString()}');
    }
  }

  // Update admin total revenue
  Future<void> _updateAdminRevenue(double amount) async {
    try {
      final adminRevenueRef = _firestore.collection('admin_revenue').doc('total');
      final doc = await adminRevenueRef.get();
      
      if (doc.exists) {
        await adminRevenueRef.update({
          'totalRevenue': FieldValue.increment(amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await adminRevenueRef.set({
          'totalRevenue': amount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silently fail - revenue tracking is not critical
    }
  }

  // Update doctor total revenue
  Future<void> _updateDoctorRevenue(String doctorId, double amount) async {
    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'totalRevenue': FieldValue.increment(amount),
        'lastRevenueUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  // Get admin total revenue
  Future<double> getAdminRevenue() async {
    try {
      final doc = await _firestore.collection('admin_revenue').doc('total').get();
      if (doc.exists) {
        return (doc.data()?['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Get admin revenue stream
  Stream<double> getAdminRevenueStream() {
    return _firestore
        .collection('admin_revenue')
        .doc('total')
        .snapshots()
        .map((doc) => (doc.data()?['totalRevenue'] as num?)?.toDouble() ?? 0.0);
  }

  // Get revenue transactions
  Stream<List<Map<String, dynamic>>> getRevenueTransactions({
    int limit = 50,
  }) {
    return _firestore
        .collection('revenue')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Get revenue statistics
  Future<Map<String, dynamic>> getRevenueStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final snapshot = await _firestore.collection('revenue').get();
      
      double totalRevenue = 0.0;
      int transactionCount = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          totalRevenue += amount;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'transactionCount': transactionCount,
        'averageTransaction': transactionCount > 0 ? totalRevenue / transactionCount : 0.0,
      };
    } catch (e) {
      return {
        'totalRevenue': 0.0,
        'transactionCount': 0,
        'averageTransaction': 0.0,
      };
    }
  }

  // Record medicine order revenue
  Future<void> recordMedicineOrderRevenue({
    required String orderId,
    required String? pharmacyId,
    required String? userId,
    required double subtotal,
    required double platformFee,
    required double pharmacyAmount,
    required double total,
    String? paymentMethod,
  }) async {
    try {
      // Record admin revenue (platform fee from medicine orders)
      await _firestore.collection('revenue').add({
        'type': 'platform_fee_medicine',
        'orderId': orderId,
        'pharmacyId': pharmacyId,
        'userId': userId,
        'amount': platformFee,
        'subtotal': subtotal,
        'platformFee': platformFee,
        'pharmacyAmount': pharmacyAmount,
        'total': total,
        'paymentMethod': paymentMethod ?? 'cod',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update admin total revenue
      await _updateAdminRevenue(platformFee);

      // Update pharmacy revenue if pharmacyId exists
      if (pharmacyId != null) {
        await _updatePharmacyRevenue(pharmacyId, pharmacyAmount);
      }
    } catch (e) {
      // Silently fail - revenue tracking is not critical
    }
  }

  // Update pharmacy revenue
  Future<void> _updatePharmacyRevenue(String pharmacyId, double amount) async {
    try {
      await _firestore.collection('pharmacies').doc(pharmacyId).update({
        'totalRevenue': FieldValue.increment(amount),
        'lastRevenueUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail
    }
  }
}

