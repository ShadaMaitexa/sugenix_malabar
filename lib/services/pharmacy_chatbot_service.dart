import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugenix/services/gemini_service.dart';

class PharmacyChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all pharmacy data from Firebase
  Future<List<Map<String, dynamic>>> getPharmacyData() async {
    try {
      final snapshot = await _firestore.collection('medicines').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['medicineName'] ?? data['name'] ?? '',
          'dosage': data['dosage'] ?? '',
          'price': data['price'] ?? 0,
          'category': data['category'] ?? '',
          'description': data['description'] ?? '',
          'sideEffects': data['sideEffects'] ?? [],
          'uses': data['uses'] ?? [],
          'availability': data['availability'] ?? true,
          'stock': data['stock'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error fetching pharmacy data: $e');
      return [];
    }
  }

  /// Generate pharmacy context string from Firebase data
  Future<String> generatePharmacyContext() async {
    try {
      final medicines = await getPharmacyData();

      if (medicines.isEmpty) {
        return 'No pharmacy data available.';
      }

      StringBuffer context = StringBuffer();
      context.write('PHARMACY DATABASE:\n');
      context.write('==================\n');

      for (var medicine in medicines) {
        context.write('\nMedicine: ${medicine['name']}\n');
        context.write('Dosage: ${medicine['dosage']}\n');
        context.write('Price: Rs. ${medicine['price']}\n');
        context.write('Category: ${medicine['category']}\n');
        context.write('Stock: ${medicine['stock']} units\n');
        context
            .write('Available: ${medicine['availability'] ? 'Yes' : 'No'}\n');

        if ((medicine['uses'] as List).isNotEmpty) {
          context.write('Uses: ${(medicine['uses'] as List).join(', ')}\n');
        }

        if ((medicine['sideEffects'] as List).isNotEmpty) {
          context.write(
              'Side Effects: ${(medicine['sideEffects'] as List).join(', ')}\n');
        }

        context.write('Description: ${medicine['description']}\n');
      }

      return context.toString();
    } catch (e) {
      print('Error generating pharmacy context: $e');
      return 'Unable to load pharmacy data.';
    }
  }

  /// Chat with pharmacy chatbot using Firebase data and Gemini
  Future<String> sendMessage(String userMessage) async {
    try {
      // Get pharmacy context from Firebase
      final pharmacyContext = await generatePharmacyContext();

      // Get glucose level guidance
      final glucoseGuidance = _getGlucoseGuidance();

      // Create comprehensive prompt with both pharmacy and glucose guidance
      final prompt =
          '''You are a comprehensive diabetes management assistant chatbot. You help patients with:
1. Pharmacy product information and medicine queries
2. Glucose level guidance and management advice
3. Diabetes-related health information

You have access to:
- Our pharmacy database with medicines, prices, and side effects
- Glucose level management guidelines
- Diabetes care recommendations

IMPORTANT INSTRUCTIONS:
1. Always respond based on the pharmacy data and glucose guidelines provided
2. For medicine inquiries, provide accurate information from our database
3. For glucose-related questions, use the glucose management guidelines below
4. If a medicine is not in database, clearly state it's not available but suggest alternatives
5. Be helpful, professional, and health-conscious
6. Always mention prices and availability for medicines
7. For diabetic patients, provide relevant safety information
8. For glucose levels, provide proper guidance and when to seek medical help
9. If question involves both medicine and glucose, address both comprehensively
10. Keep responses clear and actionable

$glucoseGuidance

$pharmacyContext

USER QUESTION: $userMessage

Please provide a helpful response based on the pharmacy database and glucose guidelines above.''';

      // Use GeminiService instead of direct HTTP call
      return await GeminiService.generateText(prompt);
    } catch (e) {
      print('Error in chatbot service: $e');
      return 'Error: ${e.toString()}';
    }
  }

  /// Search medicines by name or category
  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    try {
      final medicines = await getPharmacyData();

      return medicines
          .where((medicine) =>
              medicine['name']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              medicine['category']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching medicines: $e');
      return [];
    }
  }

  /// Get medicines by category
  Future<List<Map<String, dynamic>>> getMedicinesByCategory(
      String category) async {
    try {
      final medicines = await getPharmacyData();

      return medicines
          .where((medicine) => medicine['category']
              .toString()
              .toLowerCase()
              .contains(category.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error getting medicines by category: $e');
      return [];
    }
  }

  /// Save chat message to Firestore
  Future<void> saveChatMessage({
    required String message,
    required String response,
    required bool isUser,
  }) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('pharmacy_chats')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'userMessage': message,
        'botResponse': response,
        'isUser': isUser,
      });
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  /// Get chat history
  Future<List<Map<String, dynamic>>> getChatHistory() async {
    try {
      if (_auth.currentUser == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('pharmacy_chats')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userMessage': data['userMessage'] ?? '',
          'botResponse': data['botResponse'] ?? '',
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching chat history: $e');
      return [];
    }
  }

  /// Clear chat history
  Future<void> clearChatHistory() async {
    try {
      if (_auth.currentUser == null) return;

      final chatDocs = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('pharmacy_chats')
          .get();

      for (var doc in chatDocs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  /// Get medicine recommendations for diabetic patients
  Future<String> getDiabeticMedicineRecommendations() async {
    try {
      final pharmacyContext = await generatePharmacyContext();

      final prompt =
          '''Based on our pharmacy database, please provide recommendations for diabetes management medicines available in our pharmacy.

$pharmacyContext

Please provide:
1. Essential medicines for diabetes management
2. Pricing information
3. Availability status
4. Any special considerations for these medicines

Format the response in a clear, easy-to-read way.''';

      return await GeminiService.generateText(prompt);
    } catch (e) {
      print('Error getting recommendations: $e');
      return 'Error: ${e.toString()}';
    }
  }

  /// Get price comparison for a medicine category
  Future<String> getPriceComparison(String category) async {
    try {
      final medicines = await getMedicinesByCategory(category);

      if (medicines.isEmpty) {
        return 'No medicines found in category: $category';
      }

      StringBuffer comparison = StringBuffer();
      comparison.write('PRICE COMPARISON FOR $category:\n');
      comparison.write('================================\n\n');

      // Sort by price
      medicines
          .sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));

      for (var medicine in medicines) {
        comparison.write('${medicine['name']}\n');
        comparison.write('Price: Rs. ${medicine['price']}\n');
        comparison.write('Stock: ${medicine['stock']} units\n');
        comparison
            .write('Available: ${medicine['availability'] ? 'Yes' : 'No'}\n\n');
      }

      return comparison.toString();
    } catch (e) {
      print('Error getting price comparison: $e');
      return 'Error: ${e.toString()}';
    }
  }

  /// Get glucose level management guidelines
  String _getGlucoseGuidance() {
    return '''GLUCOSE LEVEL MANAGEMENT GUIDELINES:
=====================================

1. NORMAL GLUCOSE LEVELS:
   - Fasting (Before meals): 80-130 mg/dL
   - 2 hours after meals: Less than 180 mg/dL
   - Bedtime: 100-140 mg/dL

2. LOW GLUCOSE (HYPOGLYCEMIA) - UNDER 70 mg/dL:
   Symptoms: Shakiness, sweating, anxiety, rapid heartbeat
   Action: 
   - Immediately consume 15g fast-acting carbs (juice, glucose tablets)
   - Recheck after 15 minutes
   - If still low, repeat
   - Seek medical help if not improving

3. HIGH GLUCOSE (HYPERGLYCEMIA) - OVER 240 mg/dL:
   Symptoms: Thirst, frequent urination, fatigue, blurred vision
   Action:
   - Drink water
   - Check for ketones if persistently high
   - Take prescribed insulin/medication
   - Contact doctor if over 300 mg/dL

4. CRITICAL LEVELS:
   - Below 54 mg/dL: Severe low - Requires immediate medical attention
   - Above 350 mg/dL: Severe high - Requires immediate medical attention

5. PREVENTION TIPS:
   - Regular blood sugar monitoring
   - Consistent meal timing
   - Regular physical activity
   - Stress management
   - Adequate sleep (7-9 hours)
   - Take medicines as prescribed
   - Keep emergency contacts ready

6. WHEN TO SEEK MEDICAL HELP:
   - Glucose not responding to treatment
   - Unusual patterns emerging
   - Feeling unwell despite normal readings
   - Severe hypoglycemia symptoms
   - Suspected diabetic ketoacidosis (DKA)

7. MEDICATION IMPACT ON GLUCOSE:
   - Insulin: Lowers glucose quickly
   - Metformin: Helps prevent glucose spikes
   - Sulfonylureas: Stimulate insulin release
   - GLP-1 agonists: Slow digestion, reduce appetite
   - SGLT2 inhibitors: Increase glucose excretion

8. LIFESTYLE FACTORS:
   - Diet: Low glycemic index foods recommended
   - Exercise: 150 minutes moderate activity per week
   - Sleep: Poor sleep increases glucose variability
   - Stress: Can raise glucose levels significantly
   - Alcohol: Can cause unpredictable glucose changes
''';
  }

  /// Get glucose health analysis based on recent readings
  Future<String> getGlucoseHealthAnalysis() async {
    try {
      final readings = await _getRecentGlucoseReadings();

      if (readings.isEmpty) {
        return 'No glucose readings available. Please start tracking your glucose levels to get personalized analysis.';
      }

      StringBuffer analysis = StringBuffer();
      analysis.write('📊 GLUCOSE HEALTH ANALYSIS\n');
      analysis.write('===========================\n\n');

      // Get recent readings summary
      if (readings.isNotEmpty) {
        analysis.write('📈 Recent Readings:\n');
        for (int i = 0; i < readings.length && i < 5; i++) {
          final reading = readings[i];
          final value = reading['value'] as num;
          final status = _getGlucoseStatus(value.toDouble());
          analysis.write(
              '• ${reading['timestamp']}: ${reading['value']} mg/dL $status\n');
        }
        analysis.write('\n');

        // Calculate average
        final avgValue =
            readings.map((r) => r['value'] as num).reduce((a, b) => a + b) /
                readings.length;
        analysis.write('Average: ${avgValue.toStringAsFixed(1)} mg/dL\n');

        // Get min and max
        final values = readings.map((r) => r['value'] as num).toList();
        final minValue = values.reduce((a, b) => a < b ? a : b);
        final maxValue = values.reduce((a, b) => a > b ? a : b);

        analysis.write(
            'Range: ${minValue.toInt()} - ${maxValue.toInt()} mg/dL\n\n');

        // Provide recommendations
        analysis.write('💊 Recommendations:\n');
        if (avgValue > 180) {
          analysis.write(
              '• Your average glucose is HIGH - Consult your doctor about medication adjustment\n');
        } else if (avgValue < 100) {
          analysis.write(
              '• Your average glucose is LOW - Review meal timing and medication dosage\n');
        } else {
          analysis.write(
              '• Your glucose levels are well-controlled - Keep up the good work!\n');
        }
      }

      return analysis.toString();
    } catch (e) {
      print('Error analyzing glucose health: $e');
      return 'Unable to analyze glucose data at this time.';
    }
  }

  /// Get status emoji and text for glucose level
  String _getGlucoseStatus(double value) {
    if (value < 70) return '⚠️ LOW';
    if (value > 240) return '⚠️ HIGH';
    if (value > 180) return '⚠️ SLIGHTLY HIGH';
    if (value < 100) return 'ℹ️ SLIGHTLY LOW';
    return '✅ NORMAL';
  }

  /// Get recent glucose readings from Firebase
  Future<List<Map<String, dynamic>>> _getRecentGlucoseReadings() async {
    try {
      if (_auth.currentUser == null) return [];

      final snapshot = await _firestore
          .collection('glucose_readings')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'value': data['value'] ?? 0,
          'type': data['type'] ?? 'Random',
          'timestamp':
              data['timestamp']?.toDate().toString().split('.')[0] ?? '',
          'notes': data['notes'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching glucose readings: $e');
      return [];
    }
  }

  /// Get comprehensive glucose and medicine recommendations
  Future<String> getComprehensiveDiabetesAdvice() async {
    try {
      final glucoseAnalysis = await getGlucoseHealthAnalysis();
      final pharmacyContext = await generatePharmacyContext();

      final prompt =
          '''Based on the patient's glucose readings and our pharmacy database, provide comprehensive diabetes management advice.

GLUCOSE ANALYSIS:
$glucoseAnalysis

AVAILABLE MEDICINES:
$pharmacyContext

Please provide:
1. Assessment of current glucose control
2. Recommended medicines from our pharmacy
3. Lifestyle and dietary recommendations
4. When to seek medical attention
5. Preventive measures

Format clearly with sections and actionable advice.''';

      return await GeminiService.generateText(prompt);
    } catch (e) {
      print('Error getting comprehensive advice: $e');
      return 'Error: ${e.toString()}';
    }
  }


}
