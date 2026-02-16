import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:sugenix/screens/pharmacy_add_medicine_form.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() =>
      _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dashboard no longer hosts the add-medicine form directly.
  // The form has been moved to a reusable screen/widget and will be opened
  // from Inventory FAB or via the button below.
  List<Map<String, dynamic>> _medicines = [];
  int _totalOrders = 0;
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('pharmacyId', isEqualTo: userId)
          .get();

      int totalOrders = 0;
      double revenue = 0.0;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data['status'] != 'cancelled') {
          totalOrders++;
          // Use pharmacyAmount (after platform fee deduction) for revenue
          revenue += (data['pharmacyAmount'] as num?)?.toDouble() ??
              ((data['total'] as num?)?.toDouble() ?? 0.0);
        }
      }

      if (mounted) {
        setState(() {
          _totalOrders = totalOrders;
          _totalRevenue = revenue;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadMedicines() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      _firestore
          .collection('medicines')
          .where('pharmacyId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _medicines = snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();
          });
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _addMedicine() async {
    // Form handling moved to `PharmacyAddMedicineForm`.
    // Keep placeholder to maintain API surface if other code calls this method.
  }

  void _clearForm() {
    // Form moved; nothing to clear in dashboard now.
  }

  Future<void> _deleteMedicine(String medicineId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('medicines').doc(medicineId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medicine deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // No form controllers to dispose here anymore.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pharmacy Dashboard',
          style: TextStyle(
              color: Color(0xFF0C4556), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C4556),
      ),
      body: Column(
        children: [
          _buildStatsCards(),
          Expanded(
            child: _buildInteractiveAddPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveAddPanel() {
    // Dummy interactive cards that match the current app style. Each card
    // shows sample product info and a CTA to open the real Add Medicine form.
    final sample = {
      'name': 'Metformin XR',
      'manufacturer': 'HealthCorp',
      'price': 199.0,
      'stock': 42,
      'uses': ['Diabetes management'],
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Add (Preview)',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C4556))),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C4556).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.medication, color: Color(0xFF0C4556)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sample['name']! as String,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${sample['manufacturer']} • ₹${sample['price']}',
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text('Stock: ${sample['stock']}',
                            style: TextStyle(
                                color: ((sample['stock'] as int?) ?? 0) > 10
                                    ? Colors.green
                                    : Colors.red)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Open the reusable Add Medicine form
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PharmacyAddMedicineForm()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C4556)),
                    child: const Text('Open Form'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Tips',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text(
              '• Use the form to add medicines with accurate stock and pricing.'),
          Text('• Manage your inventory from the Inventory screen.'),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF5F6F8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Orders',
              '$_totalOrders',
              Icons.receipt_long,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Revenue',
              '₹${_totalRevenue.toStringAsFixed(0)}',
              Icons.account_balance_wallet,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Medicines',
              '${_medicines.length}',
              Icons.medication,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // The original add-medicine form was moved to a reusable screen
  // (`PharmacyAddMedicineForm`) and is opened from this dashboard's
  // interactive panel or from the Inventory FAB. The large inline form
  // has been removed to avoid duplicated controllers and compilation errors.

  Widget _buildMedicinesList() {
    if (_medicines.isEmpty) {
      return const Center(
        child: Text('No medicines added yet',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      itemCount: _medicines.length,
      itemBuilder: (context, index) {
        final medicine = _medicines[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.medication, color: Color(0xFF0C4556)),
            title: Text(
              medicine['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${(medicine['price'] ?? 0.0).toStringAsFixed(2)}'),
                if (medicine['requiresPrescription'] == true)
                  const Text('Prescription Required',
                      style: TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteMedicine(medicine['id']),
            ),
          ),
        );
      },
    );
  }

  // Dashboard does not need the inline text field helper anymore.
}
