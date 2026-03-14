import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9F9), // Light background matching your design
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          physics: const BouncingScrollPhysics(),
          children: [
            // --- TOP ROW: Back Arrow & Avatar ---
            
            const SizedBox(height: 20),

            // --- TITLE ROW: Glowing AI Heart + Text ---
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF009688).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 55,
                        color: Color(0xFF009688), // Teal heart
                      ),
                    ),
                    const Text(
                      "AI",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                const Text(
                  "Medical ID",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00695C), // Darker teal
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- EDITABLE DATA FIELDS ---
            _buildEditCard("Name"),
            _buildEditCard("Age"),
            _buildEditCard("Blood Type"),
            _buildEditCard("Allergies"),
            _buildEditCard("Emergency Contact"),
            _buildEditCard("Medical Conditions"),

            const SizedBox(height: 10),

            // --- UPDATE BUTTON ---
            ElevatedButton(
              onPressed: () {
                // TODO: Save logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00838F), // Solid Teal
                foregroundColor: Colors.white,
                elevation: 5,
                shadowColor: const Color(0xFF00838F).withOpacity(0.5),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Update Info",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the white rounded rows
  Widget _buildEditCard(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Row(
            children: const [
              Icon(Icons.edit_outlined, color: Color(0xFF009688), size: 18),
              SizedBox(width: 6),
              Text(
                "Edit",
                style: TextStyle(
                  color: Color(0xFF009688),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}