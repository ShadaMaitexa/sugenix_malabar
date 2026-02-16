import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF0C4556);

class MedicineOrderspage extends StatelessWidget {
  const MedicineOrderspage ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {},
        ),
        title: const Text(
          "Medicines orders",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "search",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Grid of options
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 1.1,
                children: const [
                  MedicineCard(
                    icon: Icons.assignment_turned_in,
                    text: "Guide to medicine order",
                  ),
                  MedicineCard(
                    icon: Icons.receipt_long,
                    text: "Prescription related issues",
                  ),
                  MedicineCard(
                    icon: Icons.shopping_cart,
                    text: "Order status",
                  ),
                  MedicineCard(
                    icon: Icons.local_shipping,
                    text: "Order delivery",
                  ),
                  MedicineCard(
                    icon: Icons.account_balance_wallet,
                    text: "Payments & Refunds",
                  ),
                  MedicineCard(
                    icon: Icons.undo,
                    text: "Order returns",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicineCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const MedicineCard({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            radius: 30,
            child: Icon(icon, size: 30, color: primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}