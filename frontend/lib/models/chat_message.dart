import 'dart:typed_data';
import 'dart:convert';

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

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'imagePath': imagePath,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
      'clinics': clinics,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      imagePath: json['imagePath'] as String?,
      imageBytes: json['imageBytes'] != null ? base64Decode(json['imageBytes'] as String) : null,
      clinics: json['clinics'] != null ? List<Map<String, dynamic>>.from(json['clinics']) : null,
    );
  }
}
