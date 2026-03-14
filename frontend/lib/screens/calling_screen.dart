import 'package:flutter/material.dart';
import 'dart:async';

class CallProgressScreen extends StatefulWidget {
  final VoidCallback onBack; 

  const CallProgressScreen({super.key, required this.onBack});

  @override
  State<CallProgressScreen> createState() => _CallProgressScreenState();
}

class _CallProgressScreenState extends State<CallProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Setup Radar Animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Setup Call Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Helper to format the timer text
  String get _formattedTime {
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          // Triggers the callback to return to the initial emergency screen
          onPressed: widget.onBack, 
        ),
        title: const Text(
          'Emergency Call in Progress',
          style: TextStyle(
            color: Color(0xFFD32F2F), // Urgent Red
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        // --- FIX: Wrapped in Center and added mainAxisAlignment ---
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
            children: [
              // --- Header Text ---
              const Text(
                "Connecting to\nCity General Hospital - 0.8 km",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 50),

              // --- Animated Red Radar ---
              SizedBox(
                height: 220,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer expanding ring
                        Container(
                          width: 220 * _animationController.value,
                          height: 220 * _animationController.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withOpacity(1.0 - _animationController.value),
                              width: 8,
                            ),
                          ),
                        ),
                        // Middle ring
                        Container(
                          width: 150 + (30 * _animationController.value),
                          height: 150 + (30 * _animationController.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.5),
                              width: 15,
                            ),
                          ),
                        ),
                        // Core glowing circle
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade700,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 50),

              // --- Timer ---
              Text(
                _formattedTime,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 15),

              // --- Supportive Text ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  "Stay calm, help is on the way!\nOur AI has shared your medical info.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // --- FIX: Removed the Spacer() that was here! ---
            ],
          ),
        ),
      ),
    );
  }
}