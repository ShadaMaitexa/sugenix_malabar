import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sugenix/services/medicine_orders_service.dart';
import 'package:sugenix/services/gemini_service.dart';
import 'package:sugenix/services/medicine_database_service.dart';
import 'package:sugenix/screens/medicine_catalog_screen.dart';
import 'package:sugenix/services/ocr_service.dart';

class PrescriptionUploadScreen extends StatefulWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  State<PrescriptionUploadScreen> createState() => _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen> {
  final MedicineOrdersService _ordersService = MedicineOrdersService();
  final MedicineDatabaseService _medicineService = MedicineDatabaseService();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _uploading = false;
  bool _analyzing = false;
  String? _uploadedPrescriptionId;
  String? _rawExtractedText; // Added to store exact text
  List<Map<String, dynamic>> _suggestedMedicines = [];
  List<Map<String, dynamic>> _availableMedicines = [];
  List<Map<String, dynamic>> _unavailableMedicines = [];

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1024);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages
          ..clear()
          ..addAll(images);
      });
      // Auto-analyze after selection
      _analyze();
    }
  }

  Future<void> _captureImage() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1024);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
      // Auto-analyze after capture
      _analyze();
    }
  }

  Future<void> _analyze() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    setState(() {
      _analyzing = true;
      _suggestedMedicines.clear();
      _availableMedicines.clear();
      _unavailableMedicines.clear();
      _rawExtractedText = null;
      _uploadedPrescriptionId = null;
    });
    
    try {
      // Step 1: Extract Text (Try Gemini Vision first, then Local OCR)
      String extractedText = '';
      if (_selectedImages.isNotEmpty) {
        // Option A: Gemini Vision (Better for handwriting)
        try {
           extractedText = await GeminiService.extractTextFromImage(
              _selectedImages.first, 
              prompt: "Read this prescription and extract all text exactly as written. List every medicine name and dosage you see. Also find frequency and duration if available."
           );
        } catch (e) {
           print('Gemini Vision Failed: $e');
        }

        // Option B: Fallback to Local OCR
        if (extractedText.isEmpty || extractedText.length < 10) {
           try {
             final ocrText = await OCRService.extractText(_selectedImages.first);
             if (ocrText.length > (extractedText.length)) {
                extractedText = ocrText;
             }
           } catch (e) {
             print('OCR Failed: $e');
           }
        }
      }

      // Step 2: Analyze Text
      if (extractedText.isNotEmpty) {
        setState(() {
          _rawExtractedText = extractedText;
        });
        print("DEBUG: Extracted Text for Analysis: \n$extractedText");
        List<Map<String, dynamic>> aiMedicines = [];
        bool usedAi = false;

        // Try Gemini Analysis to structure the text
        try {
          aiMedicines = await GeminiService.analyzePrescription(extractedText);
          if (aiMedicines.isNotEmpty) {
             usedAi = true;
          }
        } catch (e) {
          print("Gemini Analysis Failed: $e");
        }

        if (usedAi) {
           // Process AI Results
           for (var med in aiMedicines) {
              final name = med['name'] ?? '';
              String dosage = med['dosage']?.toString() ?? '';
              
              if (name.isEmpty) continue;

              // If AI gave generic dosage, try to find a more specific one in the extracted text for this medicine
              if (dosage.isEmpty || dosage.toLowerCase() == 'as prescribed' || dosage.toLowerCase() == 'not specified') {
                 // Try to find dosage patterns in the raw text lines that contain the medicine name
                 final lines = extractedText.split('\n');
                 for(var line in lines) {
                   if (line.toLowerCase().contains(name.toLowerCase())) {
                      final localDosage = _extractDosage(line);
                      if (localDosage != 'As prescribed') {
                        dosage = localDosage;
                        break;
                      }
                   }
                 }
              }
              
              if (dosage.isEmpty) dosage = 'As prescribed';

              final matches = await _searchBestMatch(name);
              
              if (matches.isNotEmpty) {
                 final match = matches.first;
                 _availableMedicines.add({
                   'name': match['name'],
                   'originalName': name,
                   'dosage': dosage, 
                   'frequency': med['frequency'] ?? 'As prescribed',
                   'duration': med['duration'] ?? 'As prescribed',
                   'pharmacyData': match,
                   'geminiInfo': med, 
                   'isAvailable': true,
                 });
              } else {
                 _unavailableMedicines.add({
                   'name': name,
                   'dosage': dosage,
                   'frequency': med['frequency'] ?? 'As prescribed',
                   'duration': med['duration'] ?? 'As prescribed',
                   'geminiInfo': med,
                   'isAvailable': false,
                 });
              }
           }
           _suggestedMedicines.addAll(aiMedicines);
        } else {
           // Fallback to Local Regex Parsing
           print("Using Local Regex Parsing on text: $extractedText");
           final localMeds = await _parseMedicinesFromOCR(extractedText);
           _suggestedMedicines.addAll(localMeds);
        }

        // Ultimate Fallback: If nothing was found but we have text, show raw text lines
        if (_suggestedMedicines.isEmpty && extractedText.trim().isNotEmpty) {
            final lines = extractedText.split('\n').where((l) => l.trim().length > 4).toList();
            for(var line in lines) {
                final dosage = _extractDosage(line);
                final name = _extractName(line);
                
                final matches = await _searchBestMatch(name);
                if (matches.isNotEmpty) {
                  final match = matches.first;
                  _availableMedicines.add({
                    'name': match['name'],
                    'originalName': name,
                    'dosage': dosage,
                    'pharmacyData': match,
                    'isAvailable': true,
                  });
                } else {
                  _unavailableMedicines.add({
                    'name': name,
                    'dosage': dosage,
                    'isAvailable': false,
                  });
                }
                _suggestedMedicines.add({'name': name, 'dosage': dosage});
            }
        }
      }
      
      if (!mounted) return;
      setState(() {
        _analyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_suggestedMedicines.isNotEmpty 
              ? 'Analysis complete! ${_suggestedMedicines.length} items identified.'
              : 'Prescription analyzed. Only raw text extracted.'),
          backgroundColor: _suggestedMedicines.isNotEmpty ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _upload() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    setState(() {
      _uploading = true;
    });
    
    try {
      // Step 3: Upload prescription
      final id = await _ordersService.uploadPrescription(_selectedImages);
      
      if (!mounted) return;
      setState(() {
        _uploadedPrescriptionId = id;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // Helper to parse medicines using Database matching
  Future<List<Map<String, dynamic>>> _parseMedicinesFromOCR(String text) async {
    final lines = text.split('\n');
    List<Map<String, dynamic>> results = [];
    final Set<String> addedIds = {};
    final Set<String> addedNames = {};
    
    for (var line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.length < 3) continue;
      if (_isNoise(cleanLine)) continue;

      final words = cleanLine.split(' ');

      // 1. Try search with full line
      var matches = await _searchBestMatch(cleanLine);
      
      // 2. If no match, try first word if it looks like a name
      if (matches.isEmpty && words.isNotEmpty && words[0].length >= 3) {
         matches = await _searchBestMatch(words[0]);
      }

      if (matches.isNotEmpty) {
         final match = matches.first;
         final id = match['id'] ?? '';
         final name = (match['name'] ?? '').toString().toLowerCase();

         // Strict deduplication
         if ((id.isNotEmpty && addedIds.contains(id)) || 
             (name.isNotEmpty && addedNames.contains(name))) {
           continue;
         }
         
          if (id.isNotEmpty) addedIds.add(id);
          if (name.isNotEmpty) addedNames.add(name);

          // It's a valid medicine in our DB
          final medData = {
            'name': match['name'],
            'dosage': match['strength'] ?? 'As prescribed',
            'pharmacyData': match,
            'isAvailable': true,
          };
          _availableMedicines.add(medData);
          results.add(medData);
       } else {
          // Not found in DB -> Add to unavailable list
          // Improved extraction logic
          final dosage = _extractDosage(cleanLine);
          // Clean the name by removing dosage info
          final nameCandidate = _extractName(cleanLine); 

          if (nameCandidate.length > 2 && !addedNames.contains(nameCandidate.toLowerCase())) {
              addedNames.add(nameCandidate.toLowerCase());
              
              final medData = {
                'name': nameCandidate, 
                'dosage': dosage,
                'isAvailable': false,
              };
              _unavailableMedicines.add(medData);
              results.add(medData);
          }
       }
     }
     return results;
   }
  
  String _extractDosage(String text) {
     // Look for patterns like 500mg, 500 mg, 5ml, 5 ml, etc.
     final regex = RegExp(r'(\d+(?:\.\d+)?\s*(?:mg|ml|gm|g|mcg|iu|unit|tablet|capsule|cap|tab|tsp|tbsp))', caseSensitive: false);
     final matches = regex.allMatches(text);
     if (matches.isNotEmpty) {
       // Return the most likely dosage (usually the first one for a specific line/medicine)
       return matches.first.group(0) ?? 'As prescribed';
     }
     return 'As prescribed';
  }
  
  String _extractName(String text) {
     // Remove dosage info to get name
     final regex = RegExp(r'(\d+(?:\.\d+)?\s*(?:mg|ml|gm|g|mcg|iu|unit|tablet|capsule|cap|tab))', caseSensitive: false);
     String name = text.replaceAll(regex, '').trim();
     // Remove any remaining trailing numbers that might be detached strength
     name = name.replaceAll(RegExp(r'\s+\d+$'), '').trim();
     // Remove special chars
     name = name.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '').trim();
     
     // Heuristic: if name is still empty or too short, revert to first part of original text
     if (name.length < 2) {
       return text.split(RegExp(r'\s+')).first;
     }
     return name;
  }

  Future<List<Map<String, dynamic>>> _searchBestMatch(String query) async {
    try {
      final matches = await _medicineService.searchMedicines(query);
      // Filter out Matches that matched only description, we want Name matching for OCR
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
    // Skip purely numeric/special
    if (RegExp(r'^[\d\W]+$').hasMatch(lower)) return true;
    
    // Skip common dosage/form keywords if the line implies it's just meta-info
    final keywords = ['tablet', 'tablets', 'cap', 'capsule', 'capsules', 'mg', 'ml', 'gm', 'g', 'mcg', 'daily', 'times', 'day', 'night', 'morning', 'after', 'before', 'food', 'dose', 'take', 'qty', 'quantity', 'total', 'price', 'mrp', 'exp', 'date', 'batch', 'no', 'code', 'reg', 'dr', 'doctor', 'patient', 'name', 'date', 'age', 'sex'];
    
    // Check if line consists mostly of keywords + numbers
    final words = lower.split(RegExp(r'\s+'));
    int noiseCount = 0;
    for(var w in words) {
       if (keywords.any((k) => w == k || w.contains(k)) || double.tryParse(w.replaceAll(RegExp(r'[^\d.]'), '')) != null || w.length < 2) {
         noiseCount++;
       }
    }
    
    // If > 60% of words are noise, skip (relaxed from 70%)
    if (words.isNotEmpty && (noiseCount / words.length > 0.6)) return true;
    
    return false;
  }

  Future<void> _testApiConnection() async {
     // Deprecated / Not needed for OCR mode
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Using On-Device Scanning (Offline)')),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Upload Prescription',
          style: TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.scanner, color: Color(0xFF0C4556)),
            onPressed: null, // Just an indicator
            tooltip: "On-Device Scan Active",
          ),
          if (_selectedImages.isNotEmpty && !_uploading)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImages.clear();
                  _uploadedPrescriptionId = null;
                });
              },
              child: const Text('Clear', style: TextStyle(color: Color(0xFF0C4556))),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F6F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add prescription images',
                      style: TextStyle(
                        color: Color(0xFF0C4556),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (_uploading || _analyzing) ? null : _pickImages,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C4556),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.photo_library, color: Colors.white),
                            label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: (_uploading || _analyzing) ? null : _captureImage,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0C4556)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.photo_camera, color: Color(0xFF0C4556)),
                            label: const Text('Camera', style: TextStyle(color: Color(0xFF0C4556))),
                          ),
                          const SizedBox(width: 12),
                          if (_selectedImages.isNotEmpty && _uploadedPrescriptionId == null)
                            ElevatedButton(
                              onPressed: (_analyzing || _uploading) ? null : _analyze,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C4556),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _analyzing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Re-Analyze', style: TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final file = _selectedImages[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(File(file.path), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: InkWell(
                            onTap: (_uploading || _analyzing)
                                ? null
                                : () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                      if (_selectedImages.isEmpty) {
                                        _suggestedMedicines.clear();
                                        _availableMedicines.clear();
                                        _unavailableMedicines.clear();
                                      }
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (_selectedImages.isEmpty)
              SizedBox(
                height: 300,
                child: _buildEmptyState(),
              ),
            if (_analyzing)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI Analyzing Prescription...', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Identifying medicines & dosages', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            if ((_availableMedicines.isNotEmpty || _unavailableMedicines.isNotEmpty) && !_analyzing)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Medicines',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C4556),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_availableMedicines.isNotEmpty) ...[
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Available in Pharmacy',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._availableMedicines.map((medicine) => _buildMedicineCard(medicine, true)),
                      const SizedBox(height: 20),
                    ],
                    if (_unavailableMedicines.isNotEmpty) ...[
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Currently Not Available',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._unavailableMedicines.map((medicine) => _buildMedicineCard(medicine, false)),
                    ],
                    
                    if (_rawExtractedText != null && _rawExtractedText!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Extracted Text from Prescription',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0C4556)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _rawExtractedText!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                    if (_uploadedPrescriptionId != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 12),
                                Text(
                                  'Uploaded Successfully!',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Prescription ID: $_uploadedPrescriptionId',
                              style: const TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    if (_uploadedPrescriptionId == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _uploading ? null : _upload,
                          icon: _uploading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_upload, color: Colors.white),
                          label: Text(_uploading ? 'Uploading...' : 'Confirm & Upload Prescription', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C4556),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MedicineCatalogScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0C4556)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Search in Pharmacy', style: TextStyle(color: Color(0xFF0C4556))),
                      ),
                    ),
                  ],
                ),
              ),
            // START DEBUGGING: Commented out potentially problematic block
            /*
            if (_uploadedPrescriptionId != null && _suggestedMedicines.isEmpty)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Uploaded. ID: $_uploadedPrescriptionId',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              */
            // END DEBUGGING
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0C4556).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description, size: 56, color: Color(0xFF0C4556)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No images selected',
            style: TextStyle(
              color: Color(0xFF0C4556),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your prescription to proceed',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine, bool available) {
    final pharmacyData = medicine['pharmacyData'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: available ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: available ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    available ? Icons.check_circle : Icons.medication,
                    color: available ? Colors.green : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine['name'] ?? 'Unknown Medicine',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 17,
                          color: available ? const Color(0xFF0C4556) : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                       // Show Dosage
                       if (medicine['dosage'] != null && medicine['dosage'].toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C4556).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.medication_liquid, size: 14, color: Color(0xFF0C4556)),
                              const SizedBox(width: 8),
                              Text(
                                'Dosage: ${medicine['dosage']}',
                                 style: const TextStyle(color: Color(0xFF0C4556), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      if (medicine['frequency'] != null && medicine['frequency'] != 'As prescribed')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Frequency: ${medicine['frequency']}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      if (medicine['duration'] != null && medicine['duration'] != 'As prescribed')
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Duration: ${medicine['duration']}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      if (!available)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NOT AVAILABLE IN PHARMACY',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (available && pharmacyData != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('Price', style: TextStyle(fontSize: 10, color: Colors.grey)),
                       Text(
                        '₹${(pharmacyData['price'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
                      ),
                     ],
                   ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicineCatalogScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C4556),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
