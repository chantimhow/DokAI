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
        toolbarHeight: 90, 
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 20.0), 
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: widget.onBack, 
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 30.0), 
          child: Text(
            'EMERGENCY CALL\nIN PROGRESS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD32F2F), 
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              // --- Header Text ---
              const Text(
                "Connecting to\nCity General Hospital - 0.8 km",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
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
                  fontSize: 45,
                  fontWeight: FontWeight.w300,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 15),

              // --- Supportive Text ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  "Stay calm, help is on the way!\nOur AI assistant has shared your medical info.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 50), // Spacing before the button

              // --- NEW: Cancel Call Button ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: OutlinedButton(
                  // This triggers the AnimatedSwitcher in your wrapper to fade back to the main screen!
                  onPressed: widget.onBack, 
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "CANCEL CALL",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}