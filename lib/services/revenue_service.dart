import 'package:cloud_firestore/cloud_firestore.dart';

class RevenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Platform fee is fixed at ₹30
  static const double fixedPlatformFee = 30.0;

  // Calculate fees for an appointment
  static Map<String, double> calculateFees(double consultationFee) {
    if (consultationFee <= 0) {
      return {
        'totalFee': 0.0,
        'consultationFee': 0.0,
        'platformFee': 0.0,
        'doctorFee': 0.0,
      };
    }

    final platformFee = fixedPlatformFee;
    final doctorFee = consultationFee; // Doctor gets their full fee
    final totalFee = consultationFee +
        platformFee; // Total customer pays = consultation fee + platform fee

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
    required String patientName,
    required double consultationFee,
    required double platformFee,
    required double doctorFee,
    String? paymentMethod,
  }) async {
    try {
      // Record admin revenue (platform fee)
      await _firestore.collection('revenue').add({
        'type': 'platform_fee',
        'revenueType': 'Appointment',
        'appointmentId': appointmentId,
        'doctorId': doctorId,
        'userId': patientId,
        'userName': patientName,
        'amount': platformFee,
        'consultationFee': consultationFee,
        'platformFee': platformFee,
        'doctorFee': doctorFee,
        'paymentMethod': paymentMethod ?? 'online',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update admin total revenue
      await _updateAdminRevenue(platformFee);

      // Update doctor total revenue
      await _updateDoctorRevenue(doctorId, doctorFee);
    } catch (e) {
      throw Exception('Failed to record revenue: ${e.toString()}');
    }
  }

  // Update admin total revenue
  Future<void> _updateAdminRevenue(double amount) async {
    try {
      final adminRevenueRef =
          _firestore.collection('admin_revenue').doc('total');
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
      final doc =
          await _firestore.collection('admin_revenue').doc('total').get();
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
        .where('type', whereIn: ['platform_fee', 'platform_fee_medicine'])
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final txns = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();

          // Sort client-side by createdAt descending
          txns.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return txns;
        });
  }

  // Get revenue statistics
  Future<Map<String, dynamic>> getRevenueStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final snapshot = await _firestore.collection('revenue').where('type',
          whereIn: ['platform_fee', 'platform_fee_medicine']).get();

      double totalRevenue = 0.0;
      int transactionCount = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amount;
      }

      return {
        'totalRevenue': totalRevenue,
        'transactionCount': transactionCount,
        'averageTransaction':
            transactionCount > 0 ? totalRevenue / transactionCount : 0.0,
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
    required String? userName,
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
        'revenueType': 'Medicine Purchase',
        'orderId': orderId,
        'pharmacyId': pharmacyId,
        'userId': userId,
        'userName': userName ?? 'Guest Customer',
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
