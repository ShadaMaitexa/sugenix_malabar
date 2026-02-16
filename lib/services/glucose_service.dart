import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GlucoseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add glucose reading
  Future<void> addGlucoseReading({
    required double value,
    required String type,
    String? notes,
    DateTime? timestamp,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      await _firestore.collection('glucose_readings').add({
        'userId': _auth.currentUser!.uid,
        'value': value,
        'type': type, // 'fasting', 'post_meal', 'random', 'bedtime'
        'notes': notes,
        'timestamp': timestamp ?? FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isAIFlagged': _shouldFlagReading(value, type),
        'aiAnalysis': _generateAIAnalysis(value, type),
      });
    } catch (e) {
      throw Exception('Failed to add glucose reading: ${e.toString()}');
    }
  }

  // Get glucose readings for current user
  Stream<List<Map<String, dynamic>>> getGlucoseReadings() {
    if (_auth.currentUser == null) return Stream.value([]);
    final userId = _auth.currentUser!.uid;

    // Optimized: Filter by userId in query
    return _firestore
        .collection('glucose_readings')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          // Handle potential null/missing timestamp
          if (data['timestamp'] == null) {
            data['timestamp'] = Timestamp.fromDate(DateTime.now());
          }
          return data;
        }).toList();
      },
    );
  }

  // Get glucose readings for date range
  Future<List<Map<String, dynamic>>> getGlucoseReadingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Optimized: Filter by userId first
      QuerySnapshot snapshot = await _firestore
          .collection('glucose_readings')
          .where('userId', isEqualTo: userId)
          .get();

      final allReadings = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter by date range client-side (to avoid composite index requirement)
      // Ideally, use a composite index for userId + timestamp
      final filtered = allReadings.where((r) {
        final timestamp = r['timestamp'];
        if (timestamp == null) return false;
        final date = timestamp is Timestamp
            ? timestamp.toDate()
            : (timestamp is DateTime ? timestamp : null);
        if (date == null) return false;
        return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      filtered.sort((a, b) {
        final aTime = a['timestamp'];
        final bTime = b['timestamp'];
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
    } catch (e) {
      throw Exception('Failed to get glucose readings: ${e.toString()}');
    }
  }

  // Update glucose reading
  Future<void> updateGlucoseReading({
    required String readingId,
    double? value,
    String? type,
    String? notes,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      if (value != null) {
        updateData['value'] = value;
        updateData['isAIFlagged'] = _shouldFlagReading(value, type ?? 'random');
        updateData['aiAnalysis'] = _generateAIAnalysis(value, type ?? 'random');
      }
      if (type != null) updateData['type'] = type;
      if (notes != null) updateData['notes'] = notes;

      await _firestore
          .collection('glucose_readings')
          .doc(readingId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update glucose reading: ${e.toString()}');
    }
  }

  // Delete glucose reading
  Future<void> deleteGlucoseReading(String readingId) async {
    try {
      await _firestore.collection('glucose_readings').doc(readingId).delete();
    } catch (e) {
      throw Exception('Failed to delete glucose reading: ${e.toString()}');
    }
  }

  // Get glucose statistics
  Future<Map<String, dynamic>> getGlucoseStatistics({int days = 30}) async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');
      final userId = _auth.currentUser!.uid;

      // Optimized: Filter by userId in query
      QuerySnapshot snapshot = await _firestore
          .collection('glucose_readings')
          .where('userId', isEqualTo: userId)
          .get();

      // Filter by date range client-side
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'];
        if (timestamp == null) return false;
        final date = timestamp is Timestamp
            ? timestamp.toDate()
            : (timestamp is DateTime ? timestamp : null);
        if (date == null) return false;

        return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      List<double> values = filteredDocs
          .map((doc) =>
              ((doc.data() as Map<String, dynamic>)['value'] as num?)
                  ?.toDouble() ??
              0.0)
          .toList();

      if (values.isEmpty) {
        return {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'totalReadings': 0,
          'normalReadings': 0,
          'highReadings': 0,
          'lowReadings': 0,
        };
      }

      double average = values.reduce((a, b) => a + b) / values.length;
      double min = values.reduce((a, b) => a < b ? a : b);
      double max = values.reduce((a, b) => a > b ? a : b);

      int normalReadings = values.where((v) => v >= 70 && v <= 180).length;
      int highReadings = values.where((v) => v > 180).length;
      int lowReadings = values.where((v) => v < 70).length;

      return {
        'average': average,
        'min': min,
        'max': max,
        'totalReadings': values.length,
        'normalReadings': normalReadings,
        'highReadings': highReadings,
        'lowReadings': lowReadings,
      };
    } catch (e) {
      throw Exception('Failed to get glucose statistics: ${e.toString()}');
    }
  }

  // Check if reading should be flagged by AI
  bool _shouldFlagReading(double value, String type) {
    switch (type) {
      case 'fasting':
        // Normal: 70-99, Prediabetes: 100-125, Diabetes: 126+
        return value < 70 || value >= 100;
      case 'post_meal':
        // Normal: <140, Prediabetes: 140-199, Diabetes: 200+
        return value >= 140;
      case 'random':
        // Normal: 80-140, Diabetes: 200+ with symptoms
        return value < 80 || value >= 200;
      case 'bedtime':
        // Normal: 90-150
        return value < 90 || value > 150;
      default:
        return value < 70 || value > 180;
    }
  }

  // Generate AI analysis for glucose reading
  String _generateAIAnalysis(double value, String type) {
    if (value < 70) {
      return "Low glucose detected. Consider immediate action: eat fast-acting carbohydrates like glucose tablets or fruit juice.";
    } else if (value > 180) {
      return "High glucose detected. Monitor closely and consider consulting your healthcare provider if this pattern continues.";
    } else {
      return "Glucose level is within normal range. Continue your current management routine.";
    }
  }

  // Get AI recommendations based on glucose patterns
  Future<List<String>> getAIRecommendations() async {
    try {
      // Get recent readings for pattern analysis
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(days: 7));

      List<Map<String, dynamic>> readings = await getGlucoseReadingsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );

      if (readings.isEmpty) {
        return [
          "Start monitoring your glucose levels regularly for better insights.",
        ];
      }

      List<String> recommendations = [];

      // Analyze patterns
      double average = readings
              .map((r) => ((r['value'] as num?)?.toDouble() ?? 0.0))
              .reduce((a, b) => a + b) /
          readings.length;

      if (average > 150) {
        recommendations.add(
          "Consider adjusting your diet and medication timing.",
        );
        recommendations.add(
          "Increase physical activity to help manage glucose levels.",
        );
      } else if (average < 100) {
        recommendations.add("Monitor for hypoglycemia symptoms.");
        recommendations.add(
          "Consider adjusting medication dosage with your doctor.",
        );
      }

      // Add general recommendations
      recommendations.add("Maintain regular meal times and portion control.");
      recommendations.add("Stay hydrated throughout the day.");
      recommendations.add("Get adequate sleep for better glucose control.");

      return recommendations;
    } catch (e) {
      return ["Unable to generate recommendations at this time."];
    }
  }

  Map<String, dynamic> classifyReading(double value) {
    if (value < 70) {
      return {
        'label': 'Low',
        'color': Colors.red,
      };
    }
    if (value > 180) {
      return {
        'label': 'High',
        'color': Colors.orange,
      };
    }
    return {
      'label': 'In Range',
      'color': Colors.green,
    };
  }
}
