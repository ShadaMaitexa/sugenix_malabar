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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pharmacy Dashboard',
          style:
              TextStyle(color: Color(0xFF0C4556), fontWeight: FontWeight.bold),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Inventory',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C4556),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PharmacyAddMedicineForm()),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C4556),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _medicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No medicines in inventory',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const PharmacyAddMedicineForm()),
                          );
                        },
                        child: const Text('Add First Medicine'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = _medicines[index];
                    final name = (medicine['name'] as String?) ?? 'Unknown';
                    final manufacturer =
                        (medicine['manufacturer'] as String?) ?? '';
                    final price =
                        (medicine['price'] as num?)?.toDouble() ?? 0.0;
                    final stock = (medicine['stock'] as int?) ?? 0;
                    final id = medicine['id'] as String;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C4556).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.medication,
                              color: Color(0xFF0C4556)),
                        ),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              manufacturer.isNotEmpty
                                  ? '$manufacturer • ₹${price.toStringAsFixed(2)}'
                                  : '₹${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: stock > 10
                                        ? Colors.green
                                        : (stock > 0
                                            ? Colors.orange
                                            : Colors.red),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  stock > 0
                                      ? '$stock in stock'
                                      : 'Out of stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: stock > 10
                                        ? Colors.green
                                        : (stock > 0
                                            ? Colors.orange
                                            : Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _deleteMedicine(id),
                          tooltip: 'Delete',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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
}
