import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sugenix/services/platform_image_service.dart';
import 'package:sugenix/services/cloudinary_service.dart';
import 'dart:io';

class PharmacyProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  
  const PharmacyProductFormScreen({super.key, this.product});

  @override
  State<PharmacyProductFormScreen> createState() => _PharmacyProductFormScreenState();
}

class _PharmacyProductFormScreenState extends State<PharmacyProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dosageController = TextEditingController();
  
  XFile? _imageFile;
  String? _imageUrl;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    _nameController.text = product['name'] ?? '';
    _priceController.text = (product['price'] as num?)?.toString() ?? '';
    _stockController.text = (product['stock'] as num?)?.toString() ?? '';
    _minQuantityController.text = (product['minQuantity'] as num?)?.toString() ?? '1';
    _manufacturerController.text = product['manufacturer'] ?? '';
    _descriptionController.text = product['description'] ?? '';
    _dosageController.text = product['dosage'] ?? '';
    _isAvailable = product['isAvailable'] ?? true;
    _imageUrl = product['imageUrl'];
  }

  Future<void> _pickImage() async {
    try {
      final image = await PlatformImageService.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = image;
          _imageUrl = null; // Clear old URL when new image is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;
    
    try {
      setState(() => _isUploading = true);
      final url = await CloudinaryService.uploadImage(_imageFile!);
      setState(() => _isUploading = false);
      return url;
    } catch (e) {
      setState(() => _isUploading = false);
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isLoading = true);
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');
      
      // Upload image if new one is selected
      String? imageUrl = _imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }
      
      final price = double.parse(_priceController.text);
      final stock = int.parse(_stockController.text);
      final minQuantity = int.parse(_minQuantityController.text.isEmpty ? '1' : _minQuantityController.text);
      
      final productData = {
        'name': _nameController.text.trim(),
        'price': price,
        'stock': stock,
        'minQuantity': minQuantity,
        'manufacturer': _manufacturerController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'isAvailable': _isAvailable && stock > 0,
        'pharmacyId': userId,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (widget.product == null) {
        // Add new product
        productData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('medicines').add(productData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      } else {
        // Update existing product
        await _firestore.collection('medicines').doc(widget.product!['id']).update(productData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minQuantityController.dispose();
    _manufacturerController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C4556),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_imageFile!.path),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 50),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      Text('Add Image', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  prefixIcon: Icon(Icons.medication),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),
              
              // Manufacturer
              TextFormField(
                controller: _manufacturerController,
                decoration: const InputDecoration(
                  labelText: 'Manufacturer',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              
              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₹) *',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              // Stock
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity *',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Invalid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              // Min Quantity
              TextFormField(
                controller: _minQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Quantity',
                  prefixIcon: Icon(Icons.shopping_cart),
                  border: OutlineInputBorder(),
                  helperText: 'Minimum quantity for purchase',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isNotEmpty && int.tryParse(v) == null) return 'Invalid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              // Dosage
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  prefixIcon: Icon(Icons.medication_liquid),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              
              // Availability Toggle
              SwitchListTile(
                title: const Text('Available'),
                subtitle: const Text('Product is available for purchase'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
                activeColor: const Color(0xFF0C4556),
              ),
              const SizedBox(height: 30),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C4556),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.product == null ? 'Add Product' : 'Update Product',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

