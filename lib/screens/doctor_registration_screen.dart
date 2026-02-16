import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sugenix/services/cloudinary_service.dart';
import 'dart:io';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() => _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _specializationController = TextEditingController(text: 'Diabetologist');
  final _hospitalController = TextEditingController();
  final _languagesController = TextEditingController(text: 'English, Malayalam');
  final _feeController = TextEditingController(text: '300');
  final _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _proofImage;
  bool _saving = false;
  bool _uploadingProof = false;

  @override
  void dispose() {
    _nameController.dispose();
    _licenseNumberController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _languagesController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _proofImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureProofImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _proofImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Proof Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0C4556)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickProofImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0C4556)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _captureProofImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate proof document
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a proof document (License/Certificate)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _uploadingProof = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');
      
      // Upload proof document to Cloudinary
      String? proofUrl;
      try {
        proofUrl = await CloudinaryService.uploadImage(_proofImage!);
        if (mounted) {
          setState(() {
            _uploadingProof = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _uploadingProof = false;
            _saving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload proof document: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final db = FirebaseFirestore.instance;
      final languages = _languagesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final fee = double.tryParse(_feeController.text.trim()) ?? 0.0;

      await db.collection('doctors').doc(uid).set({
        'id': uid,
        'name': _nameController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'hospital': _hospitalController.text.trim(),
        'languages': languages,
        'availability': {},
        'consultationFee': fee,
        'bio': _bioController.text.trim(),
        'rating': 0.0,
        'totalBookings': 0,
        'totalPatients': 0,
        'likes': 0,
        'isOnline': false,
        'profileImage': null,
        'approvalStatus': 'pending', // Pending admin approval
        'proofDocumentUrl': proofUrl, // Store proof document URL
        'createdAt': FieldValue.serverTimestamp(),
      });
      await db.collection('users').doc(uid).set({
        'role': 'doctor',
        'approvalStatus': 'pending', // Also store in users collection for easy checking
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor profile submitted! Waiting for admin approval.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      // Sign out and redirect to login
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadingProof = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Doctor Registration',
          style: TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5F6F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(_nameController, 'Full Name', Icons.person, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _buildField(_licenseNumberController, 'License Number', Icons.verified, validator: (v) => v!.isEmpty ? 'License number is required' : null),
              const SizedBox(height: 12),
              _buildField(_specializationController, 'Specialization', Icons.medical_services, validator: (v) => v!.isEmpty ? 'Specialization is required' : null),
              const SizedBox(height: 12),
              _buildField(_hospitalController, 'Hospital/Clinic', Icons.local_hospital),
              const SizedBox(height: 12),
              _buildField(_languagesController, 'Languages (comma separated)', Icons.language),
              const SizedBox(height: 12),
              _buildField(_feeController, 'Consultation Fee', Icons.currency_rupee, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _buildField(_bioController, 'Short Bio', Icons.description, maxLines: 3),
              const SizedBox(height: 20),
              _buildProofUploadSection(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C4556),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_uploadingProof)
                              const Text('Uploading proof... ', style: TextStyle(color: Colors.white))
                            else
                              const Text('Saving... ', style: TextStyle(color: Colors.white)),
                            const SizedBox(width: 10, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          ],
                        )
                      : const Text('Create Profile', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String hint, IconData icon,
      {FormFieldValidator<String>? validator, TextInputType? keyboard, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0C4556)),
      ),
    );
  }

  Widget _buildProofUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proof Document (Required)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0C4556),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload your medical license, certificate, or any proof of qualification',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _proofImage != null ? Colors.green : const Color(0xFF0C4556).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _proofImage != null
                ? Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_proofImage!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Proof document selected',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Change Document'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0C4556),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.upload_file, size: 48, color: Color(0xFF0C4556)),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to upload proof document',
                        style: TextStyle(
                          color: Color(0xFF0C4556),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'License, Certificate, or ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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


