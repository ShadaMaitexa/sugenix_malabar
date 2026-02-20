import 'package:cloud_firestore/cloud_firestore.dart';

class PlatformSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _settingsDocId = 'platform_settings';

  // Get platform fee settings
  Future<Map<String, dynamic>> getPlatformFeeSettings() async {
    try {
      final doc = await _firestore
          .collection('platform_settings')
          .doc(_settingsDocId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'feeType': data['feeType'] ?? 'percentage', // 'percentage' or 'fixed'
          'feeValue': (data['feeValue'] as num?)?.toDouble() ?? 5.0, // 5% or ₹5
          'minimumFee': (data['minimumFee'] as num?)?.toDouble() ?? 0.0,
          'maximumFee': (data['maximumFee'] as num?)?.toDouble(),
        };
      } else {
        // Default settings
        return {
          'feeType': 'percentage',
          'feeValue': 5.0, // 5%
          'minimumFee': 0.0,
          'maximumFee': null,
        };
      }
    } catch (e) {
      // Return defaults on error
      return {
        'feeType': 'percentage',
        'feeValue': 5.0,
        'minimumFee': 0.0,
        'maximumFee': null,
      };
    }
  }

  // Stream platform fee settings
  Stream<Map<String, dynamic>> streamPlatformFeeSettings() {
    return _firestore
        .collection('platform_settings')
        .doc(_settingsDocId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'feeType': data['feeType'] ?? 'percentage',
          'feeValue': (data['feeValue'] as num?)?.toDouble() ?? 5.0,
          'minimumFee': (data['minimumFee'] as num?)?.toDouble() ?? 0.0,
          'maximumFee': (data['maximumFee'] as num?)?.toDouble(),
        };
      } else {
        return {
          'feeType': 'percentage',
          'feeValue': 5.0,
          'minimumFee': 0.0,
          'maximumFee': null,
        };
      }
    });
  }

  // Update platform fee settings (admin only)
  Future<void> updatePlatformFeeSettings({
    required String feeType, // 'percentage' or 'fixed'
    required double feeValue,
    double? minimumFee,
    double? maximumFee,
  }) async {
    try {
      await _firestore.collection('platform_settings').doc(_settingsDocId).set({
        'feeType': feeType,
        'feeValue': feeValue,
        'minimumFee': minimumFee ?? 0.0,
        'maximumFee': maximumFee,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin', // In production, get from auth
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update platform settings: ${e.toString()}');
    }
  }

  // Calculate platform fee for a medicine order
  Future<Map<String, double>> calculatePlatformFee(double orderTotal) async {
    try {
      // Platform fee is now a fixed ₹30
      const platformFee = 30.0;
      final pharmacyAmount = orderTotal; // Pharmacy gets their full subtotal
      final totalAmount = orderTotal +
          platformFee; // Total customer pays = subtotal + platform fee

      return {
        'orderTotal': orderTotal,
        'platformFee': platformFee,
        'pharmacyAmount': pharmacyAmount,
        'totalAmount': totalAmount,
      };
    } catch (e) {
      // Fallback
      return {
        'orderTotal': orderTotal,
        'platformFee': 30.0,
        'pharmacyAmount': orderTotal,
        'totalAmount': orderTotal + 30.0,
      };
    }
  }
}
