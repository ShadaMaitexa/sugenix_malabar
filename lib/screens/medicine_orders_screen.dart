import 'package:flutter/material.dart';
import 'package:sugenix/screens/medicine_scanner_screen.dart';
import 'package:sugenix/screens/cart_screen.dart';
import 'package:sugenix/services/medicine_database_service.dart';
import 'package:sugenix/services/medicine_cart_service.dart';
import 'package:sugenix/widgets/translated_text.dart';
import 'package:sugenix/screens/prescription_upload_screen.dart';
import 'package:sugenix/screens/orders_list_screen.dart';
import 'package:sugenix/screens/medicine_catalog_screen.dart';
import 'package:sugenix/screens/patient_order_history_screen.dart';

class MedicineOrdersScreen extends StatefulWidget {
  const MedicineOrdersScreen({super.key});

  @override
  State<MedicineOrdersScreen> createState() => _MedicineOrdersScreenState();
}

class _MedicineOrdersScreenState extends State<MedicineOrdersScreen> {
  final MedicineDatabaseService _db = MedicineDatabaseService();
  final MedicineCartService _cart = MedicineCartService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchResults() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final m = _results[index];
        final name = (m['name'] as String?) ?? '';
        final desc = (m['description'] as String?) ?? '';
        final price = (m['price'] as num?)?.toDouble() ?? 0.0;
        final manufacturer = (m['manufacturer'] as String?) ?? '';
        return Container(
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
            child: ListTile(
              leading: const Icon(Icons.medication, color: Color(0xFF0C4556)),
              title: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF0C4556))),
              subtitle: Text(
                desc.isNotEmpty ? desc : manufacturer,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 56),
                child: FittedBox(
                  alignment: Alignment.center,
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0C4556))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C4556),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            try {
                              await _cart.addToCart(
                                medicineId: (m['id'] as String?) ?? name,
                                name: name,
                                price: price,
                                manufacturer: manufacturer,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Added to cart')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to add: ${e.toString()}')),
                              );
                            }
                          },
                          child: const Text('Add',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    try {
      final list = await _db.searchMedicines(q);
      setState(() => _results = list);
    } catch (_) {
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TranslatedAppBarTitle('medicine', fallback: 'Medicine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFF0C4556)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              
              if (_searching)
                const Center(child: CircularProgressIndicator())
              else if (_results.isNotEmpty)
                _buildSearchResults()
              else
                _buildMedicineServices(),
              // Add bottom padding for Android navigation buttons
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: _runSearch,
        decoration: InputDecoration(
          hintText: "Search medicines...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0C4556)),
            onPressed: () => _runSearch(_searchController.text),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }


  Widget _buildMedicineServices() {
    final services = [
      {
        "title": "Scan Medicine",
        "icon": Icons.qr_code_scanner,
        "color": Colors.purple,
        "subtitle": "Use camera to identify medicines",
      },
      {
        "title": "Buy Medicines",
        "icon": Icons.shopping_cart,
        "color": Colors.blue,
        "subtitle": "Browse and order medicines online",
      },
      {
        "title": "Prescription Upload",
        "icon": Icons.description,
        "color": Colors.green,
        "subtitle": "Upload prescriptions for pharmacist review",
      },
      {
        "title": "Order History",
        "icon": Icons.history,
        "color": Colors.orange,
        "subtitle": "Track your past and current orders",
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final service = services[index];
        final color = service["color"] as Color;
        return GestureDetector(
          onTap: () {
            _navigateToService(context, service["title"] as String);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    service["icon"] as IconData,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service["title"] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C4556),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service["subtitle"] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToService(BuildContext context, String service) {
    switch (service) {
      case "Scan Medicine":
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MedicineScannerScreen()),
        );
        break;
      case "Buy Medicines":
      case "Order medicine online":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MedicineCatalogScreen()));
        break;
      case "Prescription Upload":
      case "Prescription medical records":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PrescriptionUploadScreen()));
        break;
      case "Order Status":
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => OrdersListScreen()));
        break;
      case "Order History":
      case "Order history":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PatientOrderHistoryScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$service feature coming soon!")),
        );
    }
  }
}

class EmptyCartScreen extends StatelessWidget {
  const EmptyCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Patient Details",
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0C4556).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart,
                size: 60,
                color: Color(0xFF0C4556),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Your cart is empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C4556),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to medicine catalog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C4556),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Add Items",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyOrdersScreen extends StatelessWidget {
  const EmptyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Medicine orders",
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0C4556).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment,
                size: 60,
                color: Color(0xFF0C4556),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "No orders placed yet. Place your first order now.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to medicine ordering
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C4556),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Order medicines",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
