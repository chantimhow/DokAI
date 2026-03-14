class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;
  List<Map<String, dynamic>>? clinics;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.clinics,
  });
}
