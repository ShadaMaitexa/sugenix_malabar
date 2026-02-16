import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // Default Gemini API key. For production, keep this empty and store key in
  // Firestore at: app_config/gemini (field: apiKey) 
  // IMPORTANT: Get your API key from https://makersuite.google.com/app/apikey
  static const String _apiKey = 'AIzaSyD5HS7D41Njnf2i5fZbtmDJWjlbXQM-qbI';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  static const String _textUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // Helper: fetch API key from Firestore (app_config/gemini -> apiKey)
  static Future<String?> _getApiKeyFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('gemini')
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final key =
            (data['apiKey'] ?? data['api_key'] ?? data['key']) as String?;
        if (key != null && key.trim().isNotEmpty) return key.trim();
      }
    } catch (e) {
      // ignore and fallback
    }
    return null;
  }

  // Get the effective API key (Firestore -> .env -> default constant)
  static Future<String> _getEffectiveApiKey() async {
    // 1. Check Firestore
    final fromFs = await _getApiKeyFromFirestore();
    if (fromFs != null && fromFs.isNotEmpty) return fromFs;

    // 2. Check .env
    String? fromEnv;
    try {
      fromEnv = dotenv.env['GEMINI_API_KEY'];
    } catch (_) {}
    
    if (fromEnv != null && fromEnv.isNotEmpty && !fromEnv.contains('AIzaSyAPQr6I9Q1dIC6_Q-L3I3xlULH5sE3fYfs')) {
       return fromEnv;
    }

    // 3. Fallback to constant
    if (_apiKey.isNotEmpty) return _apiKey;
    
    throw Exception(
        'Gemini API key not configured. Please check your .env file or hardcoded key.');
  }

  static const List<Map<String, dynamic>> _safetySettings = [
    {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
    {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
    {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"},
    {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"},
  ];

  // Generate text response using Gemini
  static Future<String> generateText(String prompt) async {
    try {
      final key = await _getEffectiveApiKey();
      final url = Uri.parse('$_textUrl?key=$key');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'safetySettings': _safetySettings,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'No response';
        } else {
          print('Gemini API Error Response: ${response.body}');
          throw Exception('Invalid response format from Gemini API: ${response.body}');
        }
      } else {
        final errorBody = response.body;
        print('Gemini API Error: ${response.statusCode} - $errorBody');
        throw Exception(
            'Failed to generate text: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception(
            'Request timeout. Please check your internet connection.');
      }
      throw Exception('Error calling Gemini API: ${e.toString()}');
    }
  }

  // Extract text from image using Gemini Vision
  static Future<String> extractTextFromImage(XFile imageFile, {String? prompt}) async {
    final key = await _getEffectiveApiKey();
    const int maxRetries = 3;
    int attempt = 0;

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final url = Uri.parse('$_baseUrl?key=$key');
    final effectivePrompt = prompt ?? 'Extract all text from this medicine label image.';

    while (attempt < maxRetries) {
      attempt++;
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': effectivePrompt},
                      {
                        'inlineData': {
                          'mimeType': 'image/jpeg',
                          'data': base64Image
                        }
                      }
                    ]
                  }
                ],
                'safetySettings': _safetySettings,
              }),
            )
            .timeout(const Duration(seconds: 45)); // Increased timeout for images

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['candidates'] != null &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['content'] != null &&
              data['candidates'][0]['content']['parts'] != null &&
              data['candidates'][0]['content']['parts'].isNotEmpty) {
            return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
          }
          // Check for safety finish reason
          if (data['candidates'] != null &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['finishReason'] == 'SAFETY') {
            print('Gemini Safety Block: ${response.body}');
            throw Exception('Content blocked by safety filters. Please try a different image.');
          }
           print('Gemini Empty Response: ${response.body}');
          return '';
        }

        if (response.statusCode == 429 || (response.statusCode >= 500)) {
          final errorBody = response.body;
          print('Gemini Retryable Error ($attempt): ${response.statusCode} - $errorBody');
          final waitMs = 500 * (1 << (attempt - 1));
          await Future.delayed(Duration(milliseconds: waitMs));
          continue;
        }

        throw Exception('API error: ${response.statusCode} - ${response.body}');
      } catch (e) {
        print('Gemini Exception ($attempt): $e');
        if (attempt < maxRetries && (e.toString().contains('timeout') || e.toString().contains('SocketException'))) {
          final waitMs = 500 * (1 << (attempt - 1));
          await Future.delayed(Duration(milliseconds: waitMs));
          continue;
        }
        throw Exception('Error extracting text: $e');
      }
    }
    throw Exception('Failed to extract text after $maxRetries attempts');
  }

  // Get medicine information from Gemini
  static Future<Map<String, dynamic>> getMedicineInfo(
      String medicineName) async {
    try {
      final prompt = '''
Analyze this medicine: $medicineName

Provide detailed information in JSON format with the following structure:
{
  "name": "medicine name",
  "activeIngredient": "main active ingredients",
  "uses": ["use1", "use2"],
  "sideEffects": ["effect1", "effect2"],
  "dosage": "recommended dosage",
  "precautions": ["precaution1", "precaution2"],
  "priceRange": "estimated price range in INR",
  "manufacturer": "common manufacturers",
  "form": "tablet/capsule/syrup etc",
  "strength": "strength information"
}

Return only valid JSON, no additional text.
''';

      final response = await generateText(prompt);

      // Try to parse JSON from response
      try {
        // Extract JSON from response if it contains markdown
        String jsonStr = response;
        if (jsonStr.contains('```json')) {
          jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
        } else if (jsonStr.contains('```')) {
          jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
        }

        final data = jsonDecode(jsonStr);
        return Map<String, dynamic>.from(data);
      } catch (e) {
        // If JSON parsing fails, return structured text response
        return {
          'name': medicineName,
          'uses': _extractList(response, 'uses'),
          'sideEffects': _extractList(response, 'side effects'),
          'dosage': _extractField(response, 'dosage'),
          'precautions': _extractList(response, 'precautions'),
          'priceRange': _extractField(response, 'price'),
          'manufacturer': _extractField(response, 'manufacturer'),
          'form': _extractField(response, 'form'),
          'strength': _extractField(response, 'strength'),
          'rawResponse': response,
        };
      }
    } catch (e) {
      throw Exception('Error getting medicine info: ${e.toString()}');
    }
  }

  // Analyze prescription and suggest medicines
  static Future<List<Map<String, dynamic>>> analyzePrescription(
      String prescriptionText) async {
    try {
      final prompt = '''
Analyze this prescription text and extract ALL medicine names and their corresponding dosages, frequencies, and durations.

PRESCRIPTION TEXT:
$prescriptionText

IMPORTANT: 
1. Extract medicine names accurately.
2. For each medicine, find the dosage (e.g., 500mg, 10ml). If not found, look for strength or quantity.
3. Extract frequency (e.g., "twice daily", "1-0-1", "before food").
4. Extract duration (e.g., "5 days", "1 month").
5. Return a JSON array of medicines in this exact format:
[
  {
    "name": "Medicine Name",
    "dosage": "500mg",
    "frequency": "1-0-1",
    "duration": "5 days"
  }
]

If a field is missing, use "Not specified".
Return ONLY the raw JSON array. No markdown, no "```json", no additional text.
''';

      final response = await generateText(prompt);

      try {
        String jsonStr = response.trim();
        // Remove markdown formatting if present
        if (jsonStr.contains('```')) {
          final regex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
          final match = regex.firstMatch(jsonStr);
          if (match != null) {
            jsonStr = match.group(1)!;
          } else {
             jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
          }
        }
        
        final data = jsonDecode(jsonStr);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('medicines') && data['medicines'] is List) {
           return List<Map<String, dynamic>>.from(data['medicines']);
        }
        return [];
      } catch (e) {
        print('Gemini JSON Parse Error: $e\nResponse: $response');
        return _extractMedicinesFromText(response);
      }
    } catch (e) {
      throw Exception('Error analyzing prescription: ${e.toString()}');
    }
  }

  // Get glucose-based recommendations (diet, exercise, tips)
  static Future<Map<String, dynamic>> getGlucoseRecommendations({
    required double glucoseLevel,
    required String readingType,
    List<Map<String, dynamic>>? recentReadings,
  }) async {
    try {
      String readingsContext = '';
      if (recentReadings != null && recentReadings.isNotEmpty) {
        readingsContext =
            'Recent readings: ${recentReadings.map((r) => '${r['value']} mg/dL (${r['type']})').join(', ')}';
      }

      final prompt = '''
Based on this glucose reading: $glucoseLevel mg/dL (Type: $readingType)
$readingsContext

Provide personalized recommendations in JSON format:
{
  "dietPlan": {
    "breakfast": "suggested breakfast",
    "lunch": "suggested lunch",
    "dinner": "suggested dinner",
    "snacks": ["snack1", "snack2"]
  },
  "exercise": {
    "type": "recommended exercise type",
    "duration": "recommended duration",
    "frequency": "how often",
    "tips": ["tip1", "tip2"]
  },
  "tips": ["tip1", "tip2", "tip3"],
  "status": "normal/prediabetes/diabetes",
  "actionRequired": "any immediate action needed"
}

Return only valid JSON, no additional text.
''';

      final response = await generateText(prompt);

      try {
        String jsonStr = response;
        if (jsonStr.contains('```json')) {
          jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
        } else if (jsonStr.contains('```')) {
          jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
        }

        final data = jsonDecode(jsonStr);
        return Map<String, dynamic>.from(data);
      } catch (e) {
        // Fallback response
        return {
          'dietPlan': {
            'breakfast': 'Whole grain cereal with low-fat milk',
            'lunch': 'Grilled chicken with vegetables',
            'dinner': 'Fish with brown rice',
            'snacks': ['Nuts', 'Fruits']
          },
          'exercise': {
            'type': 'Brisk walking',
            'duration': '30 minutes',
            'frequency': 'Daily',
            'tips': ['Stay hydrated', 'Monitor glucose before and after']
          },
          'tips': [
            'Monitor regularly',
            'Take medications as prescribed',
            'Stay active'
          ],
          'status': glucoseLevel < 100
              ? 'normal'
              : (glucoseLevel < 126 ? 'prediabetes' : 'diabetes'),
          'actionRequired': glucoseLevel > 200
              ? 'Consult doctor immediately'
              : 'Continue monitoring',
        };
      }
    } catch (e) {
      throw Exception('Error getting recommendations: ${e.toString()}');
    }
  }

  // Chat with AI assistant with personalized context
  static Future<String> chat(String userMessage, {String? context}) async {
    try {
      String systemPrompt =
          '''You are a specialized AI health assistant for diabetes management. You provide personalized, evidence-based advice on diet, exercise, medication, and lifestyle management.

IMPORTANT GUIDELINES:
- Always provide personalized recommendations based on the user's specific health data
- For diet recommendations, consider the user's diabetes type, age, gender, allergies, and current glucose levels
- For exercise recommendations, consider the user's glucose trends, age, and any medical conditions
- Always mention safety precautions and when to consult a doctor
- Be encouraging and supportive
- Provide specific, actionable advice
- If glucose levels are high (>180 mg/dL), recommend immediate actions
- If glucose levels are low (<70 mg/dL), recommend emergency measures
- Consider the user's diabetes type (Type 1 vs Type 2) in all recommendations''';

      String prompt;
      if (context != null && context.isNotEmpty) {
        prompt = '''$systemPrompt

USER HEALTH DATA:
$context

USER QUESTION: $userMessage

Please provide a comprehensive, personalized response that:
1. Addresses the user's specific question
2. Uses their health data to personalize diet and exercise recommendations
3. Provides specific meal suggestions based on their glucose levels and diabetes type
4. Suggests appropriate exercise routines considering their current health status
5. Includes safety tips and when to consult healthcare providers

Format your response in a clear, easy-to-read manner with specific recommendations.''';
      } else {
        prompt = '''$systemPrompt

USER QUESTION: $userMessage

Please provide helpful, accurate medical advice for diabetes management. If the question is about diet or exercise, provide general recommendations and mention that personalized advice would be better with access to their health data.''';
      }

      return await generateText(prompt);
    } catch (e) {
      throw Exception('Error in chat: ${e.toString()}');
    }
  }

  // Helper methods
  static List<String> _extractList(String text, String keyword) {
    final lines = text.split('\n');
    final list = <String>[];
    bool inList = false;

    for (var line in lines) {
      if (line.toLowerCase().contains(keyword.toLowerCase())) {
        inList = true;
        continue;
      }
      if (inList) {
        if (line.trim().isEmpty) break;
        final cleaned = line.replaceAll(RegExp(r'[-•*]'), '').trim();
        if (cleaned.isNotEmpty) list.add(cleaned);
      }
    }

    return list.isEmpty ? ['Information not available'] : list;
  }

  static String _extractField(String text, String keyword) {
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains(keyword.toLowerCase())) {
        return line.split(':').length > 1
            ? line.split(':')[1].trim()
            : 'Not specified';
      }
    }
    return 'Not specified';
  }

  static List<Map<String, dynamic>> _extractMedicinesFromText(String text) {
    final medicines = <Map<String, dynamic>>[];
    final lines = text.split('\n');

    for (var line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.length < 3) continue;
      
      // Skip common non-medicine lines
      final lower = cleanLine.toLowerCase();
      if (lower.contains('date:') || lower.contains('name:') || lower.contains('age:') || lower.contains('sex:')) continue;
      if (lower.contains('dr.') || lower.contains('doctor') || lower.contains('hospital')) continue;

      // Extract looking for common signs of a medicine or dosage
      bool looksLikeMedicine = (lower.contains('mg') || lower.contains('ml') || lower.contains('mcg') || 
                                lower.contains('tab') || lower.contains('cap') || lower.contains('daily') ||
                                lower.contains('times') || lower.contains('dose'));
      
      // Additional heuristic: if it's a short line with 2-3 words, high chance it's a medicine name
      final words = cleanLine.split(' ');
      if (!looksLikeMedicine && words.length >= 1 && words.length <= 4) {
         looksLikeMedicine = true;
      }

      if (looksLikeMedicine) {
        // Try to separate name and dosage roughly
        final dosageRegex = RegExp(r'(\d+(?:\.\d+)?\s*(?:mg|ml|gm|g|mcg|iu|unit|tablet|capsule|cap|tab))', caseSensitive: false);
        final match = dosageRegex.firstMatch(cleanLine);
        
        String name = cleanLine;
        String dosage = 'As prescribed';
        
        if (match != null) {
           dosage = match.group(0)!;
           name = cleanLine.replaceFirst(dosage, '').trim();
        }

        medicines.add({
          'name': name.isEmpty ? cleanLine : name,
          'dosage': dosage,
          'frequency': 'As prescribed',
          'duration': 'As prescribed'
        });
      }
    }

    return medicines;
  }

  // Scan medicine image and extract text using Gemini Vision
  static Future<Map<String, dynamic>> scanMedicineImage(
      String imagePath) async {
    final key = await _getEffectiveApiKey();

    try {
      final file = XFile(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse('$_baseUrl?key=$key');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          '''Analyze this medicine/pharmaceutical product image and extract ALL visible text and information. Then provide:

1. **Medicine Name**: The exact name of the medicine
2. **Active Ingredients**: List all active ingredients if visible
3. **Strength/Dosage**: The strength or dosage mentioned
4. **Manufacturer**: Company name
5. **Batch/Lot Number**: If visible
6. **Expiry Date**: Expiration date if shown
7. **Storage Instructions**: How to store
8. **Uses/Indications**: What this medicine is used for (extract from packaging if available)
9. **Side Effects**: List the side effects (extract from packaging if available)
10. **Warnings/Precautions**: Any warnings or precautions
11. **Dosage Instructions**: How to take the medicine

Please be thorough and extract everything visible on the medicine packaging.'''
                    },
                    {
                      'inlineData': {
                        'mimeType': 'image/jpeg',
                        'data': base64Image,
                      }
                    }
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final extractedText =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        return {
          'success': true,
          'rawText': extractedText,
          'parsed': _parseMedicineInfo(extractedText),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to scan image: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error scanning medicine: ${e.toString()}',
      };
    }
  }

  // Extract and analyze text from user input
  static Future<Map<String, dynamic>> analyzeMedicineText(
      String extractedText) async {
    final key = await _getEffectiveApiKey();

    try {
      final url = Uri.parse('$_textUrl?key=$key');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          '''Based on this medicine information, provide detailed analysis:

TEXT FROM MEDICINE PACKAGING:
$extractedText

Please extract and provide in a clear format:

1. **Medicine Name**: 
2. **Active Ingredients**: 
3. **Strength/Dosage**: 
4. **Manufacturer**: 
5. **Batch Number**: 
6. **Expiry Date**: 
7. **Storage Instructions**: 
8. **USES/INDICATIONS** (What is this medicine used for?): 
9. **SIDE EFFECTS** (List potential side effects): 
10. **Warnings/Precautions**: 
11. **Dosage Instructions**: 

Make sure to provide detailed information about USES and SIDE EFFECTS.'''
                    }
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysisText =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        return {
          'success': true,
          'analysis': analysisText,
          'parsed': _parseMedicineInfo(analysisText),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to analyze text: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error analyzing medicine text: ${e.toString()}',
      };
    }
  }

  // Parse medicine information from Gemini response
  static Map<String, dynamic> _parseMedicineInfo(String text) {
    try {
      final usesMatch = RegExp(
        r'(?:USES?|INDICATIONS?)\s*(?:\*\*)?:?\s*\n?\s*((?:[^\n]*\n?)*?)(?=\n\n|SIDE EFFECTS|WARNINGS|STORAGE|PRECAUTIONS|$)',
        caseSensitive: false,
      ).firstMatch(text);

      final sideEffectsMatch = RegExp(
        r'(?:SIDE\s*EFFECTS?)\s*(?:\*\*)?:?\s*\n?\s*((?:[^\n]*\n?)*?)(?=\n\n|WARNINGS|STORAGE|PRECAUTIONS|DOSAGE|$)',
        caseSensitive: false,
      ).firstMatch(text);

      final medicineNameMatch = RegExp(
        r'(?:MEDICINE\s*NAME|NAME)\s*(?:\*\*)?:?\s*\n?\s*([^\n]+)',
        caseSensitive: false,
      ).firstMatch(text);

      final ingredientsMatch = RegExp(
        r'(?:ACTIVE\s*INGREDIENTS?|INGREDIENTS?)\s*(?:\*\*)?:?\s*\n?\s*((?:[^\n]*\n?)*?)(?=\n\n|STRENGTH|MANUFACTURER|$)',
        caseSensitive: false,
      ).firstMatch(text);

      final expiryMatch = RegExp(
        r'(?:EXPIRY\s*DATE|EXPIRATION)\s*(?:\*\*)?:?\s*\n?\s*([^\n]+)',
        caseSensitive: false,
      ).firstMatch(text);

      return {
        'medicineName':
            _cleanText(medicineNameMatch?.group(1) ?? 'Not available'),
        'uses': _cleanText(usesMatch?.group(1) ?? 'Not available'),
        'sideEffects':
            _cleanText(sideEffectsMatch?.group(1) ?? 'Not available'),
        'ingredients':
            _cleanText(ingredientsMatch?.group(1) ?? 'Not available'),
        'expiryDate': _cleanText(expiryMatch?.group(1) ?? 'Not available'),
        'fullText': text,
      };
    } catch (e) {
      return {
        'medicineName': 'Parse error',
        'uses': 'Could not parse',
        'sideEffects': 'Could not parse',
        'ingredients': 'Could not parse',
        'expiryDate': 'Could not parse',
        'fullText': text,
      };
    }
  }

  // Clean extracted text
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'###\s*'), '')
        .replaceAll(RegExp(r'^[-•*]\s*'), '')
        .trim()
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
}
