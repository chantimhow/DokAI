import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: KampungHealthHome()));

class KampungHealthHome extends StatelessWidget {
  const KampungHealthHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section ---
              const Text(
                'KampungHealth.',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                '- Your Personal Health Assistant -',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 25),

              //
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Tell us about your symptoms',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInputOption(Icons.mic, 'Voice Input'),
                        _buildInputOption(Icons.camera_alt, 'Take Picture'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              //
              const Text(
                'Choose your symptoms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 2.2,
                  children: [
                    _buildSymptomCard(
                      'Cough',
                      Icons.face,
                    ), // Replace with custom icons
                    _buildSymptomCard('Fever', Icons.thermostat),
                    _buildSymptomCard('Skin\nIssues', Icons.back_hand),
                    _buildSymptomCard(
                      'Stomach\nPain',
                      Icons.monitor_weight_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // --- Bottom Navigation ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              label: 'Emergency Call',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'Information\nClinic',
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Top Input Options (Cakap/Ambil Gambar)
  Widget _buildInputOption(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.black),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Helper for Symptom Grid Cards
  Widget _buildSymptomCard(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
