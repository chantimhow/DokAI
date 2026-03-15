import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'emergency_screen.dart'; // Imported your new emergency screen
import 'profile_screen.dart'; 

class KampungHealthHome extends StatefulWidget {
  const KampungHealthHome({super.key});

  @override
  State<KampungHealthHome> createState() => _KampungHealthHomeState();
}

class _KampungHealthHomeState extends State<KampungHealthHome> {
  int _selectedIndex = 0;

  final List<Map<String, String>> _careHistory = [
    {"date": "Jan 15", "issue": "Wrist Rash", "status": "Analyzed - View Report"},
    {"date": "Jan 12", "issue": "Leg Bruise", "status": "Analyzed - View Report"},
    {"date": "Jan 08", "issue": "Mild Fever", "status": "Prescription Ready"},
    {"date": "Jan 02", "issue": "Persistent Headache", "status": "Doctor Consulted"},
    {"date": "Dec 28", "issue": "Cough & Cold", "status": "Recovered"},
    {"date": "Dec 14", "issue": "Ankle Sprain", "status": "Analyzed - View Report"},
  ];

  late final List<Widget> _pages = [
    _buildMediScanContent(), 
    const EmergencyFlow(), // --- UPDATED: Using the wrapper instead of the screen directly!
    const ProfileScreen(), 
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _navigateToChat({bool openCamera = false}) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ChatScreen(autoOpenImagePicker: openCamera)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0 ? _buildAppBar() : null, 
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
          Text(
            'KampungCare ',
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
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          _buildScannerHero(),
          const SizedBox(height: 30),
          _buildDescriptionBar(),
          const SizedBox(height: 20),
          
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "My Care History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          _buildCareHistoryList(),
          const SizedBox(height: 40), 
        ],
      ),
    );
  }

  Widget _buildScannerHero() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.transparent, 
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _navigateToChat(openCamera: true),
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
        onTap: () => _navigateToChat(openCamera: false),
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
              Expanded(
                child: Text("DESCRIBE SYMPTOMS")
              ),
              Icon(Icons.mic, color: Color(0xFF009688)),
              SizedBox(width: 10),
              Icon(Icons.edit, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: _careHistory.length, 
      itemBuilder: (context, index) {
        final item = _careHistory[index]; 
        
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.history, 
              color: Colors.black38,
            ),
          ),
          title: Text(
            "${item['date']}: ${item['issue']}", 
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            item['status']!, 
            style: const TextStyle(color: Color(0xFF009688)),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
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