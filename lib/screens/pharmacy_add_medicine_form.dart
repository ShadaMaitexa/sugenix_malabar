import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PharmacyAddMedicineForm extends StatefulWidget {
  const PharmacyAddMedicineForm({super.key});

  @override
  State<PharmacyAddMedicineForm> createState() =>
      _PharmacyAddMedicineFormState();
}

class _PharmacyAddMedicineFormState extends State<PharmacyAddMedicineForm> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _dosageController = TextEditingController();
  final _formController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usesController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _precautionsController = TextEditingController();
  final _stockController = TextEditingController();

  bool _requiresPrescription = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _manufacturerController.dispose();
    _dosageController.dispose();
    _formController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _usesController.dispose();
    _sideEffectsController.dispose();
    _precautionsController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _addMedicine() async {
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      final uses = _usesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final sideEffects = _sideEffectsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final precautions = _precautionsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await _firestore.collection('medicines').add({
        'name': _nameController.text.trim(),
        'genericName': _genericNameController.text.trim(),
        'manufacturer': _manufacturerController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'form': _formController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'description': _descriptionController.text.trim(),
        'uses': uses,
        'sideEffects': sideEffects,
        'precautions': precautions,
        'requiresPrescription': _requiresPrescription,
        'pharmacyId': userId,
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Medicine added successfully'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add medicine: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0C4556)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C4556),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
                _nameController, 'Medicine Name *', Icons.medication),
            const SizedBox(height: 12),
            _buildTextField(
                _genericNameController, 'Generic Name', Icons.science),
            const SizedBox(height: 12),
            _buildTextField(
                _manufacturerController, 'Manufacturer', Icons.business),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        _dosageController, 'Dosage', Icons.straighten)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(_formController,
                        'Form (Tablet/Capsule)', Icons.medication_liquid)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _priceController,
                    'Price (₹) *',
                    Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _stockController,
                    'Stock Quantity *',
                    Icons.inventory,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
                _descriptionController, 'Description', Icons.description,
                maxLines: 3),
            const SizedBox(height: 12),
            _buildTextField(
                _usesController, 'Uses (comma separated)', Icons.info,
                maxLines: 2),
            const SizedBox(height: 12),
            _buildTextField(_sideEffectsController,
                'Side Effects (comma separated)', Icons.warning,
                maxLines: 2),
            const SizedBox(height: 12),
            _buildTextField(_precautionsController,
                'Precautions (comma separated)', Icons.health_and_safety,
                maxLines: 2),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Requires Prescription'),
              value: _requiresPrescription,
              onChanged: (value) =>
                  setState(() => _requiresPrescription = value),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C4556),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Medicine',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
