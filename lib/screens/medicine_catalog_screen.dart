import 'package:flutter/material.dart';
import 'package:sugenix/services/medicine_database_service.dart';
import 'package:sugenix/services/medicine_cart_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:sugenix/screens/medicine_detail_screen.dart';

class MedicineCatalogScreen extends StatefulWidget {
  const MedicineCatalogScreen({super.key});

  @override
  State<MedicineCatalogScreen> createState() => _MedicineCatalogScreenState();
}

class _MedicineCatalogScreenState extends State<MedicineCatalogScreen> {
  final MedicineDatabaseService _db = MedicineDatabaseService();
  final MedicineCartService _cart = MedicineCartService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allMedicines = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    try {
      // Get all medicines using the stream method
      final stream = _db.getAllMedicines(limit: 100);
      final list = await stream.first;
      setState(() {
        _allMedicines = list;
        _results = list; // Show all medicines initially
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allMedicines = [];
        _results = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _results = _allMedicines;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final searchResults = await _db.searchMedicines(query.trim());
      if (mounted) {
        setState(() {
          _results = searchResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final crossAxisCount = isDesktop ? 5 : (isTablet ? 3 : 2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Medicine Catalog',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSearchBar(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Text('No medicines found',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio:
                              isDesktop ? 0.72 : (isTablet ? 0.74 : 0.70),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final m = _results[index];
                          return _MedicineCard(
                            medicine: m,
                            onAddToCart: () async {
                              try {
                                await _cart.addToCart(
                                  medicineId: (m['id'] as String?) ??
                                      (m['name'] as String? ?? 'item'),
                                  name: (m['name'] as String?) ?? 'Medicine',
                                  price:
                                      (m['price'] as num?)?.toDouble() ?? 0.0,
                                  manufacturer: m['manufacturer'] as String?,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Added to cart')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Add failed: ${e.toString()}')),
                                );
                              }
                            },
                            onOpen: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MedicineDetailScreen(medicine: m),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
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
        onChanged: _runSearch, // Search as user types
        onSubmitted: _runSearch,
        decoration: InputDecoration(
          hintText: "Search medicines, brands...",
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
}

class _MedicineCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final VoidCallback onAddToCart;
  final VoidCallback onOpen;

  const _MedicineCard({
    required this.medicine,
    required this.onAddToCart,
    required this.onOpen,
  });

  bool _isAvailable(Map<String, dynamic> medicine) {
    final stock = medicine['stock'] as int?;
    final available = medicine['available'] as bool?;
    if (stock != null) {
      return stock > 0;
    }
    return available ?? true;
  }

  Widget _buildStockInfo(Map<String, dynamic> medicine) {
    final stock = medicine['stock'] as int?;
    if (stock != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: stock > 10
              ? Colors.green.withOpacity(0.1)
              : stock > 0
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          stock > 0 ? 'In Stock ($stock)' : 'Out of Stock',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: stock > 10
                ? Colors.green
                : stock > 0
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final name = (medicine['name'] as String?) ?? 'Medicine';
    final desc = (medicine['description'] as String?) ?? '';
    final price = (medicine['price'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4556).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.medication,
                      color: Color(0xFF0C4556), size: 32),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0C4556),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Flexible(
                child: Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
              const SizedBox(height: 6),
              _buildStockInfo(medicine),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF0C4556),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (medicine['requiresPrescription'] == true)
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Text(
                              'Rx Required',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAvailable(medicine)
                            ? const Color(0xFF0C4556)
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        minimumSize: const Size(55, 32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isAvailable(medicine) ? onAddToCart : null,
                      child: Text(
                        _isAvailable(medicine) ? 'Add' : 'Out',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
