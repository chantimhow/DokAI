import 'package:flutter/material.dart';
import 'calling_screen.dart'; 

// --- NEW: The Wrapper Widget ---
// This sits inside your tab and handles smoothly cross-fading
// between the idle state and the active calling state.
class EmergencyFlow extends StatefulWidget {
  const EmergencyFlow({super.key});

  @override
  State<EmergencyFlow> createState() => _EmergencyFlowState();
}

class _EmergencyFlowState extends State<EmergencyFlow> {
  bool _isCalling = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300), // Smooth fade animation
      child: _isCalling
          ? CallProgressScreen(
              // If the user clicks back, change state to false
              onBack: () => setState(() => _isCalling = false),
            )
          : EmergencyScreen(
              // If the user clicks the red button, change state to true
              onCall: () => setState(() => _isCalling = true),
            ),
    );
  }
}

// --- ORIGINAL SCREEN ---
class EmergencyScreen extends StatefulWidget {
  final VoidCallback onCall; // Required callback to talk to the wrapper

  const EmergencyScreen({super.key, required this.onCall});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Removed back button because we are now firmly inside a tab!
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      width: 320 * _animation.value,
                      height: 320 * _animation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.red.withOpacity(0.8),
                            Colors.red.withOpacity(0.0),
                          ],
                          stops: const [0.1, 0.7],
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    // --- NEW: Triggers the callback to swap to the call screen ---
                    onTap: widget.onCall, 
                    child: const Center(
                      child: Text(
                        "CALL NEAREST\nHOSPITAL NOW",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: const Color(0xFFE6F2F2), 
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 100,
                              color: const Color(0xFF007980).withOpacity(0.15),
                            ),
                            const Positioned(
                              top: 50,
                              child: Icon(
                                Icons.location_on,
                                size: 50,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "NEAREST HOSPITAL LOCATION",
                      style: TextStyle(
                        color: Color(0xFF005B60),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00838F), 
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.location_on_outlined, size: 20),
                        label: const Text(
                          "OPEN MAPS",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Tap to navigate to City General Hospital (0.8 km)",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10), 
          ],
        ),
      ),
    );
  }
}