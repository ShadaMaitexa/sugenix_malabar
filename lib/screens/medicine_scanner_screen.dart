import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:sugenix/services/platform_image_service.dart';
import 'package:sugenix/services/medicine_database_service.dart';
import 'package:sugenix/services/gemini_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:sugenix/widgets/translated_text.dart';
import 'package:sugenix/services/medicine_cart_service.dart';
import 'package:sugenix/screens/medicine_catalog_screen.dart';
import 'package:sugenix/services/ocr_service.dart';

class MedicineScannerScreen extends StatefulWidget {
  const MedicineScannerScreen({super.key});

  @override
  State<MedicineScannerScreen> createState() => _MedicineScannerScreenState();
}

class _MedicineScannerScreenState extends State<MedicineScannerScreen> {
  final MedicineDatabaseService _medicineService = MedicineDatabaseService();
  final MedicineCartService _cartService = MedicineCartService();
  XFile? _scannedImage;
  bool _isProcessing = false;
  Map<String, dynamic>? _medicineInfo;
  bool _medicineFoundInPharmacy = false;
  Map<String, dynamic>? _pharmacyMedicine;

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0C4556)),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF0C4556)),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      try {
        final image = await PlatformImageService.pickImage(source: source);
        if (image != null) {
          setState(() {
            _scannedImage = image;
            _medicineInfo = null;
          });
          _processImage(image);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Camera/Gallery access denied or unavailable. Please grant permissions in settings.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processImage(XFile image) async {
    setState(() {
      _isProcessing = true;
      _medicineInfo = null;
      _medicineFoundInPharmacy = false;
      _pharmacyMedicine = null;
    });

    try {
      // 1. Extract Text using On-Device OCR (No API required)
      final extractedText = await OCRService.extractText(image);
      
      if (extractedText.isEmpty) {
        throw Exception('Could not extract text. Please ensure the label is clear.');
      }

      // 2. Try to find medicine in local database using extracted lines
      final lines = extractedText.split('\n');
      Map<String, dynamic>? dbMatch;
      String bestNameCandidate = '';

      for (var line in lines) {
        final cleanLine = line.trim();
        if (cleanLine.length < 3) continue;
        if (_isNoise(cleanLine)) continue;
        
        // Potential name candidate if no match found yet
        if (bestNameCandidate.isEmpty) {
             bestNameCandidate = _extractName(cleanLine);
        }

        // Try full line search
        var matches = await _searchBestMatch(cleanLine);
        
        // Try first word search if full line failed
        final words = cleanLine.split(' ');
        if (matches.isEmpty && words.isNotEmpty && words[0].length >= 3) {
            matches = await _searchBestMatch(words[0]);
        }

        if (matches.isNotEmpty) {
           dbMatch = matches.first;
           break; 
        }
      }

      // 3. Construct Medicine Data
      Map<String, dynamic> medicineData;

      if (dbMatch != null) {
        // Found in DB
        _medicineFoundInPharmacy = true;
        _pharmacyMedicine = dbMatch;
        double price = 0.0;
        try {
          price = double.tryParse(dbMatch['price']?.toString() ?? '') ?? 0.0;
        } catch (_) {
          price = 0.0;
        }

        medicineData = {
          'name': dbMatch['name'],
          'manufacturer': dbMatch['manufacturer'] ?? '',
          'type': dbMatch['type'] ?? 'Medicine',
          'activeIngredient': dbMatch['activeIngredient'] ?? '',
          'strength': dbMatch['strength'] ?? '',
          'form': dbMatch['form'] ?? '',
          'uses': dbMatch['uses'] is List
              ? (dbMatch['uses'] as List).map((e) => e.toString()).toList()
              : [dbMatch['uses']?.toString() ?? ''],
          'dosage': dbMatch['dosage'] ?? '',
          'precautions': dbMatch['precautions'] is List
              ? (dbMatch['precautions'] as List).map((e) => e.toString()).toList()
              : [],
          'sideEffects': dbMatch['sideEffects'] is List
              ? (dbMatch['sideEffects'] as List).map((e) => e.toString()).toList()
              : [],
          'price': price,
          'priceRange': dbMatch['priceRange'] ?? '',
          'available': true,
        };
      } else {
        // Not found in DB - Use Gemini AI to analyze the whole text context
        _medicineFoundInPharmacy = false;
        
        // 1. Try to analyze the full extracted text which usually contains the name AND context
        Map<String, dynamic> parsedInfo = {};
        bool analysisSuccess = false;
        
        try {
           final analysisResult = await GeminiService.analyzeMedicineText(extractedText);
           if (analysisResult['success'] == true && analysisResult['parsed'] != null) {
             parsedInfo = analysisResult['parsed'];
             analysisSuccess = true;
           }
        } catch (e) {
           print("Gemini full text analysis failed: $e");
        }

        // 2. If full analysis failed or didn't give a name, try specific name lookup
        String finalName = parsedInfo['medicineName'] ?? 'Unknown';
        if (finalName == 'Unknown' || finalName == 'Not available' || finalName == 'Parse error') {
             // Fallback to heuristic name
             finalName = bestNameCandidate.isNotEmpty ? bestNameCandidate : 'Unknown Medicine';
             // If we have a name now, maybe try getting info just for that name?
             if (finalName != 'Unknown Medicine' && !analysisSuccess) {
                 try {
                    final specificInfo = await GeminiService.getMedicineInfo(finalName);
                    parsedInfo = {
                        'medicineName': finalName,
                        'uses': (specificInfo['uses'] as List?)?.join('\n') ?? 'Details not available',
                        'sideEffects': (specificInfo['sideEffects'] as List?)?.join('\n') ?? 'Consult a doctor',
                        'ingredients': specificInfo['activeIngredient']?.toString() ?? 'Not identified',
                         // dosage/strength might differ, but let's keep it simple
                    };
                 } catch (_) {}
             }
        }
        
        // 3. Construct Data
        // Helper to convert string block to list
        List<String> toList(dynamic val) {
           if (val is List) return val.map((e) => e.toString()).toList();
           if (val is String) {
              if (val.toLowerCase().contains('not available') || val.toLowerCase().contains('parse error')) return [];
              return val.split('\n').where((s) => s.trim().isNotEmpty).map((s) => s.trim().replaceAll(RegExp(r'^[-•*]'), '').trim()).toList();
           }
           return [];
        }

        medicineData = {
          'name': finalName,
          'manufacturer': parsedInfo['manufacturer'] ?? 'Not identified', // map might not have manufacturer in 'parsed', check service
          'type': 'Medicine',
          'activeIngredient': parsedInfo['ingredients'] ?? 'Not identified',
          'strength': _extractDosage(extractedText), // Keep keeping regex dosage as backup
          'form': 'Tablet/Syrup',
          'uses': toList(parsedInfo['uses']).isEmpty ? ['Information not available for this specific text'] : toList(parsedInfo['uses']),
          'dosage': parsedInfo['dosageInstructions'] ?? _extractDosage(extractedText),
          'precautions': <String>[], // Parsed info doesn't strictly return precautions in the helper, maybe leave empty
          'sideEffects': toList(parsedInfo['sideEffects']).isEmpty ? ['Consult a doctor for side effects'] : toList(parsedInfo['sideEffects']),
          'price': 0.0,
          'priceRange': '',
          'available': false,
        };
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _medicineInfo = medicineData;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_medicineFoundInPharmacy
                ? 'Medicine found in pharmacy!'
                : 'Text extracted. Medicine not found in database.'),
            backgroundColor:
                _medicineFoundInPharmacy ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
       if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _extractDosage(String text) {
     final regex = RegExp(r'(\d+(?:\.\d+)?\s*(?:mg|ml|gm|g|mcg|iu|unit|tablet|capsule|cap|tab))', caseSensitive: false);
     final match = regex.firstMatch(text);
     return match?.group(0) ?? '';
  }
  
  String _extractName(String text) {
     final regex = RegExp(r'(\d+(?:\.\d+)?\s*(?:mg|ml|gm|g|mcg|iu|unit|tablet|capsule|cap|tab))', caseSensitive: false);
     String name = text.replaceAll(regex, '').trim();
     name = name.replaceAll(RegExp(r'\s+\d+$'), '').trim();
     name = name.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '').trim();
     if (name.length < 2) return text.split(RegExp(r'\s+')).first;
     return name;
  }

  Future<List<Map<String, dynamic>>> _searchBestMatch(String query) async {
    try {
      final matches = await _medicineService.searchMedicines(query);
      return matches.where((m) {
        final name = (m['name'] ?? '').toString().toLowerCase();
        final q = query.toLowerCase();
        return name.contains(q);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  bool _isNoise(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'^[\d\W]+$').hasMatch(lower)) return true;
    final keywords = ['tablet', 'tablets', 'cap', 'capsule', 'capsules', 'mg', 'ml', 'gm', 'g', 'mcg', 'daily', 'times', 'day', 'night', 'morning', 'after', 'before', 'food', 'dose', 'take', 'qty', 'quantity', 'total', 'price', 'mrp', 'exp', 'date', 'batch', 'no', 'code', 'reg'];
    final words = lower.split(RegExp(r'\s+'));
    int noiseCount = 0;
    for(var w in words) {
       if (keywords.any((k) => w.contains(k)) || double.tryParse(w.replaceAll(RegExp(r'[^\d.]'), '')) != null || w.length < 3) {
         noiseCount++;
       }
    }
    if (words.isNotEmpty && (noiseCount / words.length > 0.7)) return true;
    return false;
  }

  List<String> _normalizeList(String? value) {
    if (value == null) return [];
    final cleaned = value
        .split('\n')
        .map((e) => e.trim())
        .where((e) =>
            e.isNotEmpty &&
            !_isValueUnavailable(e) &&
            e.toLowerCase() != 'not specified')
        .toList();
    return cleaned;
  }

  bool _isValueUnavailable(String? value) {
    if (value == null) return true;
    final v = value.trim().toLowerCase();
    return v.isEmpty || v.contains('not available') || v.contains('could not parse');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TranslatedAppBarTitle('medicine', fallback: 'Medicine Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScannerSection(),
              const SizedBox(height: 30),
              if (_medicineInfo != null) _buildMedicineInfo(),
              // Add bottom padding for Android navigation buttons
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Scan Medicine Label",
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C4556),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Take a clear photo of your medicine label to get detailed information",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          if (_scannedImage != null)
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(
                        _scannedImage!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child:
                                Icon(Icons.image, size: 60, color: Colors.grey),
                          );
                        },
                      )
                    : Image.file(
                        File(_scannedImage!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child:
                                Icon(Icons.image, size: 60, color: Colors.grey),
                          );
                        },
                      ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "No image selected",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (_isProcessing)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text(
                    "Processing image...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  _scannedImage == null ? "Scan Medicine" : "Scan Again",
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C4556),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicineInfo() {
    final info = _medicineInfo!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4556).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medication,
                  color: Color(0xFF0C4556),
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info['name'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0C4556),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      info['manufacturer'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoSection('Type', info['type'] as String),
          _buildInfoSection(
              'Active Ingredient', info['activeIngredient'] as String),
          _buildInfoSection('Strength', info['strength'] as String),
          _buildInfoSection('Form', info['form'] as String),
          const Divider(height: 30),
          _buildListSection('Uses', info['uses'] as List<String>, Icons.info),
          const SizedBox(height: 20),
          _buildListSection(
            'Precautions',
            info['precautions'] as List<String>,
            Icons.warning,
            Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildListSection(
            'Possible Side Effects',
            info['sideEffects'] as List<String>,
            Icons.error_outline,
            Colors.red,
          ),
          const SizedBox(height: 20),
          _buildInfoSection('Dosage', info['dosage'] as String),
          if (info['priceRange'] != null &&
              (info['priceRange'] as String).isNotEmpty)
            _buildInfoSection('Estimated Price', info['priceRange'] as String),
          if (_medicineFoundInPharmacy && _pharmacyMedicine != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Available in Pharmacy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Price: ₹${(_pharmacyMedicine!['price'] ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C4556),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _cartService.addToCart(
                            medicineId: _pharmacyMedicine!['id'] ?? '',
                            name: _pharmacyMedicine!['name'] ??
                                info['name'] ??
                                'Medicine',
                            price:
                                (_pharmacyMedicine!['price'] ?? 0.0).toDouble(),
                            quantity: 1,
                            manufacturer: _pharmacyMedicine!['manufacturer'],
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to cart!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MedicineCatalogScreen(),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Failed to add to cart: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C4556),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Currently not available',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This medicine is not currently available in our pharmacy. Name and dosage extracted from scan.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 12,
                tablet: 13,
                desktop: 14,
              ),
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              color: const Color(0xFF0C4556),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    String title,
    List<String> items,
    IconData icon, [
    Color? iconColor,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? const Color(0xFF0C4556),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 17,
                  desktop: 18,
                ),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0C4556),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: iconColor ?? const Color(0xFF0C4556),
                  // color: iconColor ?? const Color(0xFF0C4556), // Duplicate key?
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 13,
                        tablet: 14,
                        desktop: 15,
                      ),
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
