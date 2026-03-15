import 'dart:typed_data';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;
  final Uint8List? imageBytes;
  List<Map<String, dynamic>>? clinics;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.imageBytes,
    this.clinics,
  });
}
