import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/services/glucose_service.dart';

class UserContextService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final GlucoseService _glucoseService = GlucoseService();

  /// Get comprehensive user context for AI personalization
  Future<Map<String, dynamic>> getUserContext() async {
    try {
      if (_auth.currentUser == null) {
        return {'error': 'User not logged in'};
      }

      final userId = _auth.currentUser!.uid;
      
      // Get user profile
      final userProfile = await _authService.getUserProfile();
      
      // Get recent glucose readings (last 30 days)
      final recentReadings = await _glucoseService.getGlucoseReadingsByDateRange(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      // Get glucose statistics
      Map<String, dynamic> glucoseStats = {};
      try {
        glucoseStats = await _glucoseService.getGlucoseStatistics(days: 30);
      } catch (e) {
        // If statistics unavailable, calculate from recent readings
        if (recentReadings.isNotEmpty) {
          final values = recentReadings.map((r) => (r['value'] as num?)?.toDouble() ?? 0.0).toList();
          final sum = values.fold(0.0, (a, b) => a + b);
          glucoseStats = {
            'average': sum / values.length,
            'min': values.reduce((a, b) => a < b ? a : b),
            'max': values.reduce((a, b) => a > b ? a : b),
            'count': values.length,
          };
        }
      }

      // Get latest glucose reading
      Map<String, dynamic>? latestReading;
      if (recentReadings.isNotEmpty) {
        latestReading = recentReadings.first;
      }

      // Calculate age from dateOfBirth
      int? age;
      if (userProfile?['dateOfBirth'] != null) {
        final dob = userProfile!['dateOfBirth'];
        DateTime? dobDate;
        if (dob is Timestamp) {
          dobDate = dob.toDate();
        } else if (dob is DateTime) {
          dobDate = dob;
        } else if (dob is String) {
          try {
            dobDate = DateTime.parse(dob);
          } catch (e) {
            // Ignore parse error
          }
        }
        if (dobDate != null) {
          age = DateTime.now().difference(dobDate).inDays ~/ 365;
        }
      }

      // Build comprehensive context
      return {
        'userId': userId,
        'name': userProfile?['name'] ?? 'User',
        'age': age,
        'gender': userProfile?['gender'],
        'diabetesType': userProfile?['diabetesType'] ?? 'Type 2',
        'allergies': userProfile?['allergies'] ?? [],
        'medicalHistory': userProfile?['medicalHistory'] ?? {},
        'glucoseStats': glucoseStats,
        'latestReading': latestReading,
        'recentReadings': recentReadings.take(10).toList(), // Last 10 readings
        'readingCount': recentReadings.length,
      };
    } catch (e) {
      return {'error': 'Failed to get user context: ${e.toString()}'};
    }
  }

  /// Build personalized context string for AI
  Future<String> buildPersonalizedContext() async {
    final context = await getUserContext();
    
    if (context.containsKey('error')) {
      return '';
    }

    final buffer = StringBuffer();
    
    // User basic info
    buffer.writeln('Patient Profile:');
    buffer.writeln('- Name: ${context['name']}');
    if (context['age'] != null) {
      buffer.writeln('- Age: ${context['age']} years');
    }
    if (context['gender'] != null) {
      buffer.writeln('- Gender: ${context['gender']}');
    }
    buffer.writeln('- Diabetes Type: ${context['diabetesType']}');
    
    // Allergies
    final allergies = context['allergies'] as List?;
    if (allergies != null && allergies.isNotEmpty) {
      buffer.writeln('- Allergies: ${allergies.join(', ')}');
    }
    
    // Medical history
    final medicalHistory = context['medicalHistory'] as Map?;
    if (medicalHistory != null && medicalHistory.isNotEmpty) {
      buffer.writeln('- Medical History: ${medicalHistory.toString()}');
    }
    
    // Glucose statistics
    final glucoseStats = context['glucoseStats'] as Map?;
    if (glucoseStats != null && glucoseStats.isNotEmpty) {
      buffer.writeln('\nGlucose Statistics (Last 30 days):');
      if (glucoseStats['average'] != null) {
        buffer.writeln('- Average: ${glucoseStats['average'].toStringAsFixed(1)} mg/dL');
      }
      if (glucoseStats['min'] != null) {
        buffer.writeln('- Minimum: ${glucoseStats['min'].toStringAsFixed(1)} mg/dL');
      }
      if (glucoseStats['max'] != null) {
        buffer.writeln('- Maximum: ${glucoseStats['max'].toStringAsFixed(1)} mg/dL');
      }
      if (glucoseStats['count'] != null) {
        buffer.writeln('- Total Readings: ${glucoseStats['count']}');
      }
    }
    
    // Latest reading
    final latestReading = context['latestReading'] as Map?;
    if (latestReading != null) {
      buffer.writeln('\nLatest Glucose Reading:');
      buffer.writeln('- Value: ${latestReading['value']} mg/dL');
      buffer.writeln('- Type: ${latestReading['type']}');
      if (latestReading['timestamp'] != null) {
        final timestamp = latestReading['timestamp'];
        DateTime? date;
        if (timestamp is Timestamp) {
          date = timestamp.toDate();
        } else if (timestamp is DateTime) {
          date = timestamp;
        }
        if (date != null) {
          buffer.writeln('- Date: ${date.toString().split(' ')[0]}');
        }
      }
    }
    
    // Recent readings summary
    final recentReadings = context['recentReadings'] as List?;
    if (recentReadings != null && recentReadings.isNotEmpty) {
      buffer.writeln('\nRecent Glucose Readings (Last 10):');
      for (var reading in recentReadings.take(5)) {
        final value = reading['value'];
        final type = reading['type'];
        buffer.writeln('- $value mg/dL ($type)');
      }
    }
    
    return buffer.toString();
  }
}

