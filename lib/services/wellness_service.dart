import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugenix/services/glucose_service.dart';
import 'package:sugenix/services/auth_service.dart';

class WellnessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlucoseService _glucoseService = GlucoseService();
  final AuthService _authService = AuthService();

  // Get wellness recommendations based on category and user data
  Future<List<Map<String, dynamic>>> getRecommendations({
    required String category,
  }) async {
    try {
      // Get user profile for personalization
      final userProfile = await _authService.getUserProfile();
      final glucoseStats = await _glucoseService.getGlucoseStatistics(days: 7);

      // Fetch recommendations from Firestore
      QuerySnapshot snapshot = await _firestore
          .collection('wellness_recommendations')
          .limit(10)
          .get();

      List<Map<String, dynamic>> recommendations = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Personalize based on user data
        final glucoseLevel =
            (glucoseStats['average'] as num?)?.toDouble() ?? 100.0;
        final diabetesType =
            userProfile?['diabetesType'] as String? ?? 'Type 1';

        // Check if recommendation applies to user's condition
        final applicableTo = data['applicableTo'] as List<dynamic>? ?? [];
        if (applicableTo.isEmpty ||
            applicableTo.contains(diabetesType) ||
            applicableTo.contains('all')) {
          // Adjust priority based on glucose level for medication recommendations
          if (category == 'medication' && glucoseLevel > 180) {
            data['priority'] = (data['priority'] as int? ?? 5) -
                1; // Higher priority for high glucose
          }

          recommendations.add({
            'id': doc.id,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'icon': data['icon'] ?? 'info',
            'color': data['color'] ?? '#0C4556',
            'priority': data['priority'] ?? 5,
          });
        }
      }

      // If no Firestore recommendations, return default recommendations
      if (recommendations.isEmpty) {
        return _getDefaultRecommendations(category);
      }

      // Sort by priority
      recommendations.sort(
          (a, b) => (a['priority'] as int).compareTo(b['priority'] as int));

      return recommendations;
    } catch (e) {
      // Return default recommendations on error
      return _getDefaultRecommendations(category);
    }
  }

  // Default recommendations (fallback)
  List<Map<String, dynamic>> _getDefaultRecommendations(String category) {
    switch (category) {
      case 'diet':
        return [
          {
            'id': 'diet_1',
            'title': 'Eat Balanced Meals',
            'description':
                'Include whole grains, lean proteins, and plenty of vegetables. Aim for 3 main meals and 2-3 snacks daily.',
            'icon': 'restaurant',
            'color': '#FF9800',
            'priority': 1,
          },
          {
            'id': 'diet_2',
            'title': 'Control Portion Sizes',
            'description':
                'Use smaller plates and measure your portions. Follow the plate method: 50% vegetables, 25% protein, 25% whole grains.',
            'icon': 'shopping_basket',
            'color': '#4CAF50',
            'priority': 2,
          },
        ];
      case 'exercise':
        return [
          {
            'id': 'exercise_1',
            'title': 'Regular Physical Activity',
            'description':
                'Aim for at least 150 minutes of moderate exercise per week. This can include brisk walking, cycling, or swimming.',
            'icon': 'directions_walk',
            'color': '#2196F3',
            'priority': 1,
          },
        ];
      case 'medication':
        return [
          {
            'id': 'medication_1',
            'title': 'Take Medications on Time',
            'description':
                'Set reminders for your medications and never skip doses. Consistency is key to managing diabetes effectively.',
            'icon': 'alarm',
            'color': '#9C27B0',
            'priority': 1,
          },
        ];
      case 'lifestyle':
        return [
          {
            'id': 'lifestyle_1',
            'title': 'Get Enough Sleep',
            'description':
                'Aim for 7-9 hours of quality sleep each night. Poor sleep can affect blood sugar control.',
            'icon': 'bedtime',
            'color': '#3F51B5',
            'priority': 1,
          },
        ];
      default:
        return [];
    }
  }
}
