import 'package:flutter/material.dart';

class Recordpage extends StatelessWidget {
  const Recordpage ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          "Add Records",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Image Section
            Row(
              children: [
                Container(
                  height: 100,
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  height: 100,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Color(0xFF0C4556)),
                        SizedBox(height: 5),
                        Text(
                          "Add more\nimages",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Record for
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Record for",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 18, color: Colors.black54),
                ),
              ],
            ),
            const Text(
              "Name",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF0C4556),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 25),

            // Type of record
            const Text(
              "Type of record",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildTypeCard(Icons.insert_chart_outlined, "Report"),
                const SizedBox(width: 12),
                _buildTypeCard(Icons.receipt_long, "Prescription"),
                const SizedBox(width: 12),
                _buildTypeCard(Icons.description_outlined, "Invoice"),
              ],
            ),

            const SizedBox(height: 25),

            // Record created on
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Record created on",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 18, color: Colors.black54),
                ),
              ],
            ),
            const Text(
              "Date",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF0C4556),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 40),

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C4556),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                child: const Text(
                  "Upload record",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Color(0xFF0C4556)),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            )
          ],
        ),
      ),
    );
  }
}