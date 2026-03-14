import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_response.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost
  // OR use your actual local IP address (e.g., 192.168.x.x) if testing on a physical device.
  // For simplicity, we assume we are running the backend on the same machine on port 8000
  static const String baseUrl = 'http://127.0.0.1:8000/api'; 

  static Future<ChatResponse> sendMessage(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'message': text,
      }),
    );

    if (response.statusCode == 200) {
      return ChatResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  static Future<ChatResponse> sendImage(File imageFile, String description) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/scan'));
    
    request.fields['description'] = description;
    
    // Add the image
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return ChatResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send image: ${response.statusCode}');
    }
  }
}
