import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/chat_response.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost
  // OR use your actual local IP address (e.g., 192.168.x.x) if testing on a physical device.
  // For simplicity, we assume we are running the backend on the same machine on port 8000
  static const String baseUrl = "http://127.0.0.1:8000/api";
  
  static Future<ChatResponse> sendMessage(String text, {List<Map<String, String>> history = const []}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'message': text,
        'history': history,
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

  static Future<ChatResponse> sendImageBytes(List<int> bytes, String filename, String description) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/scan'));
    
    request.fields['description'] = description;
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
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

  static Future<List<dynamic>> getNearbyClinics(double lat, double lon) async {
    final response = await http.get(Uri.parse('$baseUrl/clinics?lat=$lat&lon=$lon'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['elements'] as List<dynamic>;
    } else {
      throw Exception('Failed to fetch clinics: ${response.statusCode}');
    }
  }

  static Future<Map<String, double>?> getIpLocation() async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          // Sometimes it returns strings or ints, parsing safely
          'latitude': double.tryParse(data['latitude'].toString()) ?? 3.1390,
          'longitude': double.tryParse(data['longitude'].toString()) ?? 101.6869,
        };
      }
    } catch (e) {
      print('IP Location fallback failed: $e');
    }
    return null;
  }
}
