import 'package:flutter/material.dart';
import 'chat_screen.dart';

class KampungHealthHome extends StatefulWidget {
  const KampungHealthHome({super.key});

  @override
  State<KampungHealthHome> createState() => _KampungHealthHomeState();
}

class _KampungHealthHomeState extends State<KampungHealthHome> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    _buildMediScanContent(), // Your new modern homepage
    const Center(child: Text('Emergency Services')),
    const Center(child: Text('Personal Profile')),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Common navigation function to keep your existing functionality
  void _navigateToChat() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: const [
          // The camera icon and spacing have been removed from here
          Text(
            'KampungScan ',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold),
          ),
          Text(
            'AI',
            style: TextStyle(
              color: Color(0xFF009688),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
     
  
    );
  }

  Widget _buildMediScanContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Main Scanner Section (Replaces your "Take Picture" button) ---
          _buildScannerHero(),

          // --- Description Bar (Replaces your "Voice Input" button) ---
          _buildDescriptionBar(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              "Your Health Assistant",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          _buildAssistantGrid(),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "My Care History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          _buildCareHistoryList(),
        ],
      ),
    );
  }

  Widget _buildScannerHero() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F9F8), // Soft background tint
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The Glowing Camera Button (Functional)
          GestureDetector(
            onTap: _navigateToChat, // Triggers your existing camera/chat logic
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "TAP TO SCAN SYMPTOM",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            "Take a photo of a rash or injury for AI analysis.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: _navigateToChat, // Triggers your existing voice/text chat logic
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: const [
              Icon(Icons.face_unlock_outlined, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text("DESCRIBE SYMPTOMS")),
              Icon(Icons.mic, color: Color(0xFF009688)),
              SizedBox(width: 10),
              Icon(Icons.edit, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Centers the remaining buttons
      children: [
        _buildAssistantCard(
          "Book \nAppointment",
          Icons.calendar_today,
          false,
        ),
        const SizedBox(width: 20), // Adds a nice gap between the two buttons
        _buildAssistantCard(
          "Medication\nCentre",
          Icons.medication_outlined,
          false,
        ),
      ],
    );
  }

  Widget _buildAssistantCard(String title, IconData icon, bool highlighted) {
    return Container(
      width: 100,
      height: 110,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE0F2F1) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF009688)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCareHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Text(
            index == 0 ? "Jan 15: Wrist Rash" : "Jan 12: Leg Bruise",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            "Analyzed - View Report",
            style: TextStyle(color: Color(0xFF009688)),
          ),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: const Color(0xFF009688),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.emergency),
          label: 'Emergency',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Profile',
        ),
      ],
    );
  }
}