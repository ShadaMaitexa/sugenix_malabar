import 'package:flutter/material.dart';
import 'package:sugenix/services/medicine_cart_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  final MedicineCartService _cart = MedicineCartService();
  int _qty = 1;
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.medicine;
    final name = (m['name'] as String?) ?? 'Medicine';
    final manufacturer = (m['manufacturer'] as String?) ?? '';
    final description = (m['description'] as String?) ?? '';
    final price = (m['price'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
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
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: ResponsiveHelper.isMobile(context) ? 180 : 220,
              decoration: BoxDecoration(
                color: const Color(0xFF0C4556).withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.medication, color: Color(0xFF0C4556), size: 64),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: TextStyle(
                color: const Color(0xFF0C4556),
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
              ),
            ),
            const SizedBox(height: 6),
            if (manufacturer.isNotEmpty)
              Text(
                manufacturer,
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: const Color(0xFF0C4556),
                    fontWeight: FontWeight.w800,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                  ),
                ),
                const Spacer(),
                _buildQtySelector(),
              ],
            ),
            _buildStockInfo(m),
            const SizedBox(height: 16),
            if (description.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  color: Color(0xFF0C4556),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
            _buildDetailSection('Uses', m['uses'], Icons.info, Colors.blue),
            _buildDetailSection('Side Effects', m['sideEffects'], Icons.warning, Colors.red),
            _buildDetailSection('Precautions', m['precautions'], Icons.health_and_safety, Colors.orange),
            if (m['dosage'] != null && (m['dosage'] as String).isNotEmpty)
              _buildInfoRow('Dosage', m['dosage'] as String),
            if (m['form'] != null && (m['form'] as String).isNotEmpty)
              _buildInfoRow('Form', m['form'] as String),
            if (m['strength'] != null && (m['strength'] as String).isNotEmpty)
              _buildInfoRow('Strength', m['strength'] as String),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_adding || !_isAvailable(m)) ? null : () => _addToCart(m, price),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAvailable(m) ? const Color(0xFF0C4556) : Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _adding
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _isAvailable(m) ? 'Add to Cart' : 'Out of Stock',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {
              setState(() {
                if (_qty > 1) _qty--;
              });
            },
          ),
          Text('$_qty', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0C4556))),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              setState(() {
                _qty++;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> m, double price) async {
    setState(() => _adding = true);
    try {
      await _cart.addToCart(
        medicineId: (m['id'] as String?) ?? (m['name'] as String? ?? 'item'),
        name: (m['name'] as String?) ?? 'Medicine',
        price: price,
        quantity: _qty,
        manufacturer: m['manufacturer'] as String?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  bool _isAvailable(Map<String, dynamic> m) {
    final stock = m['stock'] as int?;
    final available = m['available'] as bool?;
    if (stock != null) {
      return stock > 0;
    }
    return available ?? true;
  }

  Widget _buildStockInfo(Map<String, dynamic> m) {
    final stock = m['stock'] as int?;
    if (stock != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: stock > 10
              ? Colors.green.withOpacity(0.1)
              : stock > 0
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: stock > 10
                ? Colors.green
                : stock > 0
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
        child: Row(
          children: [
            Icon(
              stock > 0 ? Icons.check_circle : Icons.cancel,
              color: stock > 10
                  ? Colors.green
                  : stock > 0
                      ? Colors.orange
                      : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              stock > 0 ? 'In Stock ($stock available)' : 'Out of Stock',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: stock > 10
                    ? Colors.green
                    : stock > 0
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetailSection(String title, dynamic data, IconData icon, Color color) {
    if (data == null) return const SizedBox.shrink();
    
    List<String> items = [];
    if (data is List) {
      items = data.map((e) => e.toString()).toList();
    } else if (data is String && data.isNotEmpty) {
      items = [data];
    }
    
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0C4556),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0C4556),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


