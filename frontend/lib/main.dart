import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MedApp());
}

class MedApp extends StatelessWidget {
  const MedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedApp Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
