class ChatResponse {
  final String response;
  final String disclaimer;

  ChatResponse({required this.response, required this.disclaimer});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'],
      disclaimer: json['disclaimer'],
    );
  }
}
