import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Hugging Face AI Service for image-to-text and text analysis
/// Uses free Hugging Face Inference API (no billing required)
class HuggingFaceService {
  // Hugging Face API base URL
  static const String _baseUrl = 'https://api-inference.huggingface.co/models';

  // Models for different tasks - Using working models on Hugging Face Inference API
  static const String _ocrModel =
      'microsoft/trocr-large-printed'; // Using large model for better accuracy
  static const String _fallbackOcrModel =
      'naver-clova-ix/donut-base'; // Modern OCR model
  static const String _visionModel =
      'nlpconnect/vit-gpt2-image-captioning'; 
  static const String _textModel =
      'mistralai/Mistral-7B-Instruct-v0.3'; // Updated to v0.3

  // Optional: API token for higher rate limits (free tier works without it)
  // Get from: https://huggingface.co/settings/tokens
  // Priority: Firestore -> .env file (HF_TOKEN) -> empty (free tier)

  // Helper: fetch API token from Firestore (optional)
  static Future<String?> _getApiTokenFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('huggingface')
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final token =
            (data['apiToken'] ?? data['api_token'] ?? data['token']) as String?;
        if (token != null && token.trim().isNotEmpty) return token.trim();
      }
    } catch (e) {
      // ignore and fallback
    }
    return null;
  }

  // Helper: get API token from .env file
  static String? _getApiTokenFromEnv() {
    try {
      final token = dotenv.env['HF_TOKEN'];
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
    } catch (e) {
      // dotenv not loaded or not available - ignore
    }
    return null;
  }

  // Get the effective API token (Firestore -> .env -> empty)
  static Future<String> _getEffectiveApiToken() async {
    // Priority 1: Firestore
    final fromFs = await _getApiTokenFromFirestore();
    if (fromFs != null && fromFs.isNotEmpty) return fromFs;

    // Priority 2: .env file (HF_TOKEN)
    final fromEnv = _getApiTokenFromEnv();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    // Priority 3: Empty (free tier works without token)
    return '';
  }

  // Extract text from image using OCR
  static Future<String> extractTextFromImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final token = await _getEffectiveApiToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Try primary OCR model first
      String extractedText = '';
      bool success = false;

      // Attempt 1: Primary OCR model with raw bytes
      try {
        final url = Uri.parse('$_baseUrl/$_ocrModel');
        final response = await http.post(
          url,
          headers: {
            ...headers,
            'Content-Type': 'image/jpeg',
          },
          body: bytes,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty) {
            final first = data[0];
            if (first is Map && first['generated_text'] != null) {
              extractedText = first['generated_text'] as String;
              success = true;
            }
          }
        } else if (response.statusCode == 503) {
          // Model loading
          await Future.delayed(const Duration(seconds: 3));
        } else {
          // Log other status codes but don't throw yet, try next model
          print('HF Primary OCR failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        // Primary model failed, try fallback
      }

      // Attempt 2: Fallback OCR model if primary failed
      if (!success) {
        try {
          final url = Uri.parse('$_baseUrl/$_fallbackOcrModel');
          final response = await http.post(
            url,
            headers: {
              ...headers,
              'Content-Type': 'image/jpeg',
            },
            body: bytes,
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is List && data.isNotEmpty) {
              final first = data[0];
              if (first is Map && first['generated_text'] != null) {
                extractedText = first['generated_text'] as String;
                success = true;
              }
            }
          }
        } catch (e) {
          // Fallback model also failed
        }
      }

      // Attempt 3: Vision model as last resort
      if (!success) {
        try {
          extractedText = await _analyzeImageWithVision(imageFile);
          success = true;
        } catch (e) {
          // All methods failed
        }
      }

      if (success && extractedText.isNotEmpty) {
        return extractedText;
      } else {
        throw Exception('All OCR methods failed to extract text from image');
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception(
            'Request timeout. Please check your internet connection.');
      }
      throw Exception('Error extracting text: ${e.toString()}');
    }
  }

  // Analyze prescription text and extract medicines
  static Future<List<Map<String, dynamic>>> analyzePrescription(
      String prescriptionText) async {
    try {
      final prompt =
          '''Analyze this prescription and extract all medicine names in JSON format:

$prescriptionText

Return a JSON array of medicines with this structure:
[
  {
    "name": "medicine name",
    "dosage": "dosage information (e.g., 500mg, 1 tablet)",
    "frequency": "how often to take (e.g., twice daily, after meals)",
    "duration": "duration of treatment (e.g., 7 days, 2 weeks)",
    "amount": "quantity/package size if mentioned"
  }
]

Extract all medicines mentioned in the prescription. Return only valid JSON array, no additional text.''';

      final response = await _generateText(prompt);

      try {
        String jsonStr = response;
        // Extract JSON from markdown if present
        if (jsonStr.contains('```json')) {
          jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
        } else if (jsonStr.contains('```')) {
          jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
        }

        final data = jsonDecode(jsonStr);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } catch (e) {
        // Fallback: extract medicine names from text
        return _extractMedicinesFromText(response);
      }
    } catch (e) {
      throw Exception('Error analyzing prescription: ${e.toString()}');
    }
  }

  // Get medicine information
  static Future<Map<String, dynamic>> getMedicineInfo(
      String medicineName) async {
    try {
      final prompt = '''Analyze this medicine: $medicineName

Provide detailed information in JSON format with the following structure:
{
  "name": "medicine name",
  "uses": ["use1", "use2", "use3"],
  "sideEffects": ["effect1", "effect2", "effect3"],
  "dosage": "recommended dosage with frequency (e.g., 1 tablet twice daily)",
  "precautions": ["precaution1", "precaution2"],
  "priceRange": "estimated price range in INR (e.g., ₹50-100)",
  "amount": "typical package size (e.g., 10 tablets, 100ml)",
  "manufacturer": "common manufacturers",
  "form": "tablet/capsule/syrup/injection etc",
  "strength": "strength information (e.g., 500mg, 10mg/ml)"
}

IMPORTANT: 
- Provide detailed uses (at least 3-5 common uses)
- List common side effects (at least 3-5)
- Include price range in INR
- Include package amount/size
- Return only valid JSON, no additional text.''';

      final response = await _generateText(prompt);

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
        // Fallback response - try to extract from text
        return {
          'name': medicineName,
          'uses': _extractList(response, 'uses'),
          'sideEffects': _extractList(response, 'side effects'),
          'dosage': _extractField(response, 'dosage'),
          'precautions': _extractList(response, 'precautions'),
          'priceRange': _extractField(response, 'price') != 'Not specified'
              ? _extractField(response, 'price')
              : _extractField(response, 'priceRange'),
          'amount': _extractField(response, 'amount') != 'Not specified'
              ? _extractField(response, 'amount')
              : _extractField(response, 'package'),
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

  // Scan medicine image and extract information
  static Future<Map<String, dynamic>> scanMedicineImage(
      String imagePath) async {
    try {
      final file = XFile(imagePath);

      // Step 1: Extract text using OCR
      String extractedText = '';
      try {
        extractedText = await extractTextFromImage(file);
      } catch (e) {
        // If OCR fails, try vision model
        try {
          extractedText = await _analyzeImageWithVision(file);
        } catch (e2) {
          throw Exception('Failed to extract text from image: ${e.toString()}');
        }
      }

      if (extractedText.isEmpty) {
        return {
          'success': false,
          'error': 'Could not extract text from image',
        };
      }

      // Step 2: Parse medicine information
      final parsed = _parseMedicineInfo(extractedText);

      return {
        'success': true,
        'rawText': extractedText,
        'parsed': parsed,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error scanning medicine: ${e.toString()}',
      };
    }
  }

  // Analyze medicine text for detailed information
  static Future<Map<String, dynamic>> analyzeMedicineText(
      String extractedText) async {
    try {
      final prompt =
          '''Based on this medicine information from packaging, provide detailed analysis:

TEXT FROM MEDICINE PACKAGING:
$extractedText

Please extract and provide in a clear format with detailed information:

1. **Medicine Name**: [exact name from package]
2. **Active Ingredients**: [list all active ingredients]
3. **Strength/Dosage**: [e.g., 500mg per tablet, 10mg/ml]
4. **Manufacturer**: [company name]
5. **Batch Number**: [if visible]
6. **Expiry Date**: [if visible]
7. **Storage Instructions**: [how to store]
8. **USES/INDICATIONS** (What is this medicine used for? List at least 3-5 uses): 
   - Use 1
   - Use 2
   - Use 3
9. **SIDE EFFECTS** (List at least 3-5 potential side effects):
   - Side effect 1
   - Side effect 2
   - Side effect 3
10. **Warnings/Precautions**: [important warnings]
11. **Dosage Instructions**: [how to take, when to take, frequency]

IMPORTANT: Provide detailed, comprehensive information about USES and SIDE EFFECTS. Include all relevant medical information from the packaging.''';

      final analysisText = await _generateText(prompt);

      return {
        'success': true,
        'analysis': analysisText,
        'parsed': _parseMedicineInfo(analysisText),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error analyzing medicine text: ${e.toString()}',
      };
    }
  }

  // Private helper: Generate text using Hugging Face
  static Future<String> _generateText(String prompt) async {
    try {
      final token = await _getEffectiveApiToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final url = Uri.parse('$_baseUrl/$_textModel');

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'inputs': prompt,
              'parameters': {
                'max_new_tokens': 500,
                'temperature': 0.7,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final first = data[0];
          if (first is Map && first['generated_text'] != null) {
            return first['generated_text'] as String;
          }
        } else if (data is Map && data['generated_text'] != null) {
          return data['generated_text'] as String;
        }
        return data.toString();
      } else if (response.statusCode == 503) {
        // Model is loading, wait and retry
        await Future.delayed(const Duration(seconds: 5));
        return await _generateText(prompt);
      } else {
        throw Exception(
            'Failed to generate text: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception(
            'Request timeout. Please check your internet connection.');
      }
      throw Exception('Error generating text: ${e.toString()}');
    }
  }

  // Private helper: Analyze image with vision model
  static Future<String> _analyzeImageWithVision(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final token = await _getEffectiveApiToken();
      final headers = <String, String>{};
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final url = Uri.parse('$_baseUrl/$_visionModel');

      final response = await http.post(
        url,
        headers: {
          ...headers,
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final first = data[0];
          if (first is Map && first['generated_text'] != null) {
            return first['generated_text'] as String;
          }
        } else if (data is Map && data['generated_text'] != null) {
          return data['generated_text'] as String;
        }
        return data.toString();
      } else if (response.statusCode == 503) {
        await Future.delayed(const Duration(seconds: 5));
        return await _analyzeImageWithVision(imageFile);
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image: ${e.toString()}');
    }
  }

  // Parse medicine information from text
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

  // Extract list from text
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

  // Extract field from text
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

  // Extract medicines from text (fallback)
  static List<Map<String, dynamic>> _extractMedicinesFromText(String text) {
    final medicines = <Map<String, dynamic>>[];
    final lines = text.split('\n');

    for (var line in lines) {
      if (line.trim().isNotEmpty &&
          (line.contains('mg') ||
              line.contains('tablet') ||
              line.contains('capsule'))) {
        medicines.add({
          'name': line.trim(),
          'dosage': 'As prescribed',
          'frequency': 'As prescribed',
          'duration': 'As prescribed'
        });
      }
    }

    return medicines;
  }
}
