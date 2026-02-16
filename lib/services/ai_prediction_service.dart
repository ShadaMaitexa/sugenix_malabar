import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIPredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Predict hypoglycemia risk (dummy implementation)
  Future<Map<String, dynamic>> predictHypoglycemiaRisk() async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      // Get recent glucose readings
      QuerySnapshot snapshot =
          await _firestore.collection('glucose_readings').get();

      List<double> values = snapshot.docs
          .map((doc) =>
              ((doc.data() as Map<String, dynamic>)['value'] as num?)
                  ?.toDouble() ??
              0.0)
          .toList();

      if (values.isEmpty) {
        return {
          'risk': 'unknown',
          'probability': 0.0,
          'message': 'Insufficient data for prediction',
          'recommendations': [
            'Log more glucose readings to enable accurate predictions',
          ],
        };
      }

      // Dummy prediction logic
      double average = values.reduce((a, b) => a + b) / values.length;
      int lowReadings = values.where((v) => v < 70).length;
      double riskProbability = 0.0;
      String risk = 'low';

      if (average < 100 && lowReadings > 2) {
        riskProbability = 0.8;
        risk = 'high';
      } else if (average < 120 && lowReadings > 0) {
        riskProbability = 0.5;
        risk = 'medium';
      } else {
        riskProbability = 0.2;
        risk = 'low';
      }

      List<String> recommendations = [];
      if (risk == 'high') {
        recommendations.add('Monitor glucose levels more frequently');
        recommendations.add('Keep fast-acting glucose sources nearby');
        recommendations.add('Consider adjusting medication timing');
        recommendations.add('Consult your doctor immediately');
      } else if (risk == 'medium') {
        recommendations.add('Monitor glucose levels regularly');
        recommendations.add('Maintain regular meal times');
        recommendations.add('Stay hydrated');
      } else {
        recommendations.add('Continue current management routine');
        recommendations.add('Maintain regular monitoring');
      }

      return {
        'risk': risk,
        'probability': riskProbability,
        'message': _getRiskMessage(risk, riskProbability),
        'recommendations': recommendations,
        'basedOnReadings': values.length,
        'averageGlucose': average,
      };
    } catch (e) {
      throw Exception('Failed to predict hypoglycemia risk: ${e.toString()}');
    }
  }

  // Predict hyperglycemia risk (dummy implementation)
  Future<Map<String, dynamic>> predictHyperglycemiaRisk() async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      // Get recent glucose readings
      QuerySnapshot snapshot =
          await _firestore.collection('glucose_readings').get();

      List<double> values = snapshot.docs
          .map((doc) =>
              ((doc.data() as Map<String, dynamic>)['value'] as num?)
                  ?.toDouble() ??
              0.0)
          .toList();

      if (values.isEmpty) {
        return {
          'risk': 'unknown',
          'probability': 0.0,
          'message': 'Insufficient data for prediction',
          'recommendations': [
            'Log more glucose readings to enable accurate predictions',
          ],
        };
      }

      // Dummy prediction logic
      double average = values.reduce((a, b) => a + b) / values.length;
      int highReadings = values.where((v) => v > 180).length;
      double riskProbability = 0.0;
      String risk = 'low';

      if (average > 200 && highReadings > 3) {
        riskProbability = 0.85;
        risk = 'high';
      } else if (average > 160 && highReadings > 1) {
        riskProbability = 0.6;
        risk = 'medium';
      } else {
        riskProbability = 0.2;
        risk = 'low';
      }

      List<String> recommendations = [];
      if (risk == 'high') {
        recommendations.add('Monitor glucose levels closely');
        recommendations.add('Review your diet and meal timing');
        recommendations.add('Consider increasing physical activity');
        recommendations.add('Consult your doctor about medication adjustment');
      } else if (risk == 'medium') {
        recommendations.add('Monitor glucose levels regularly');
        recommendations.add('Maintain portion control');
        recommendations.add('Stay active throughout the day');
      } else {
        recommendations.add('Continue current management routine');
        recommendations.add('Maintain regular monitoring');
      }

      return {
        'risk': risk,
        'probability': riskProbability,
        'message': _getRiskMessage(risk, riskProbability),
        'recommendations': recommendations,
        'basedOnReadings': values.length,
        'averageGlucose': average,
      };
    } catch (e) {
      throw Exception('Failed to predict hyperglycemia risk: ${e.toString()}');
    }
  }

  // Get overall health prediction (dummy implementation)
  Future<Map<String, dynamic>> getOverallHealthPrediction() async {
    try {
      final hypoRisk = await predictHypoglycemiaRisk();
      final hyperRisk = await predictHyperglycemiaRisk();

      String overallStatus = 'stable';
      if (hypoRisk['risk'] == 'high' || hyperRisk['risk'] == 'high') {
        overallStatus = 'needs_attention';
      } else if (hypoRisk['risk'] == 'medium' ||
          hyperRisk['risk'] == 'medium') {
        overallStatus = 'monitor';
      }

      return {
        'status': overallStatus,
        'hypoglycemiaRisk': hypoRisk,
        'hyperglycemiaRisk': hyperRisk,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      throw Exception(
          'Failed to get overall health prediction: ${e.toString()}');
    }
  }

  String _getRiskMessage(String risk, double probability) {
    switch (risk) {
      case 'high':
        return 'High risk detected. Please take immediate action and consult your healthcare provider.';
      case 'medium':
        return 'Moderate risk detected. Monitor your glucose levels closely and follow recommendations.';
      case 'low':
        return 'Low risk. Continue your current management routine.';
      default:
        return 'Unable to determine risk level.';
    }
  }

  // Predict glucose trend (dummy implementation)
  Future<Map<String, dynamic>> predictGlucoseTrend() async {
    try {
      if (_auth.currentUser == null) throw Exception('No user logged in');

      QuerySnapshot snapshot =
          await _firestore.collection('glucose_readings').get();

      List<double> values = snapshot.docs
          .map((doc) =>
              ((doc.data() as Map<String, dynamic>)['value'] as num?)
                  ?.toDouble() ??
              0.0)
          .toList();

      if (values.length < 5) {
        return {
          'trend': 'insufficient_data',
          'message': 'Need at least 5 readings to predict trend',
        };
      }

      // Simple trend calculation
      double firstHalf =
          values.sublist(0, values.length ~/ 2).reduce((a, b) => a + b) /
              (values.length ~/ 2);
      double secondHalf =
          values.sublist(values.length ~/ 2).reduce((a, b) => a + b) /
              (values.length - values.length ~/ 2);

      String trend = 'stable';
      if (secondHalf > firstHalf + 20) {
        trend = 'increasing';
      } else if (secondHalf < firstHalf - 20) {
        trend = 'decreasing';
      }

      return {
        'trend': trend,
        'message': _getTrendMessage(trend),
        'averageFirstHalf': firstHalf,
        'averageSecondHalf': secondHalf,
      };
    } catch (e) {
      throw Exception('Failed to predict glucose trend: ${e.toString()}');
    }
  }

  String _getTrendMessage(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Your glucose levels are trending upward. Consider reviewing your diet and medication.';
      case 'decreasing':
        return 'Your glucose levels are trending downward. Monitor for hypoglycemia symptoms.';
      case 'stable':
        return 'Your glucose levels are relatively stable. Continue your current management routine.';
      default:
        return 'Unable to determine trend.';
    }
  }
}
