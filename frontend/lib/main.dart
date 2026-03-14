import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MedApp());
}

class MedApp extends StatelessWidget {
  const MedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedApp Assistant',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const KampungHealthHome(),
      routes: {
        '/homepage': (context) => const KampungHealthHome(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}
