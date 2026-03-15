import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'camera_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final bool autoOpenImagePicker;
  final String? sessionId;
  final List<ChatMessage>? initialMessages;

  const ChatScreen({
    super.key, 
    this.autoOpenImagePicker = false,
    this.sessionId,
    this.initialMessages,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  // This is the variable that was showing as undefined!
  final List<ChatMessage> _messages = [];
  
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final FlutterTts _flutterTts = FlutterTts();
  String? _currentlySpeakingText;

  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _speechEnabled = false;

  late String _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';

    if (widget.initialMessages != null) {
      _messages.addAll(widget.initialMessages!);
    }

    _speechToText = stt.SpeechToText();
    _initSpeech();
    _initTts();

    if (widget.autoOpenImagePicker && _messages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getImage();
      });
    }
  }

  Future<void> _autoSaveSession() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> keys = prefs.getStringList('chat_session_keys')?.toList() ?? [];
    
    // Add to index if brand new
    if (!keys.contains(_sessionId)) {
      keys.add(_sessionId);
      await prefs.setStringList('chat_session_keys', keys);
    }

    // Save current messages JSON format
    List<Map<String, dynamic>> serializedMessages = _messages.map((m) => m.toJson()).toList();
    await prefs.setString(_sessionId, jsonEncode(serializedMessages));
  }

  void _initSpeech() async {
    // Moved initialization to _listen() to ensure user interaction on Web
  }

  void _listen() async {
    if (!_speechEnabled) {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          print('Speech Error: $val');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Mic Error: $val. Your browser might not support Web Speech API.')),
            );
            setState(() => _isListening = false);
          }
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    }

    if (_speechEnabled) {
      if (!_isListening) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                _textController.text = val.recognizedWords;
              });
            }
          },
          pauseFor: const Duration(seconds: 5),
          listenFor: const Duration(seconds: 60),
        );
      } else {
        setState(() => _isListening = false);
        _speechToText.stop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available or disabled in this browser.')),
        );
      }
    }
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _currentlySpeakingText = null;
        });
      }
    });
    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      if (mounted) {
        setState(() {
          _currentlySpeakingText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TTS Error: $msg. Your browser may lack audio drivers.')),
        );
      }
    });
    _flutterTts.getVoices.then((voices) {
      print("Available web voices: $voices");
      if (voices == null || (voices as List).isEmpty) {
        print("WARNING: Browser returned 0 TTS voices.");
      }
    });
  }

  Future<void> _speak(String text) async {
    if (_currentlySpeakingText != null) {
      await _stop();
    }
    
    // Heuristically determine language (Malay vs English)
    final malayKeywords = [
      'saya', 'anda', 'ini', 'itu', 'yang', 'dan', 'untuk', 
      'dengan', 'dalam', 'tidak', 'ada', 'boleh', 'akan', 
      'atau', 'dari', 'ke', 'pada', 'pesakit', 'doktor'
    ];
    
    int malayCount = 0;
    final lowerText = text.toLowerCase();
    for (var word in malayKeywords) {
      if (lowerText.contains(RegExp(r'\b' + word + r'\b'))) {
        malayCount++;
      }
    }
    
    // If we detect Malay words, switch to Bahasa Malaysia accent. Otherwise, default to English.
    if (malayCount >= 2) {
      await _flutterTts.setLanguage("ms-MY");
      // Fallback to Indonesian if Malay is not installed on the browser
      // await _flutterTts.setLanguage("id-ID"); 
    } else {
      await _flutterTts.setLanguage("en-US");
    }

    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.setPitch(1.0);

    if (text.isNotEmpty && mounted) {
      setState(() {
        _currentlySpeakingText = text;
      });
      var cleanText = text.replaceAll(RegExp(r'\*\*|\*|#|-|`'), '');
      var result = await _flutterTts.speak(cleanText);
      if (result != 1) {
        print("TTS failed to speak.");
      }
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _currentlySpeakingText = null;
      });
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<Map<String, String>> _getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('profile_name') ?? 'Unknown',
      'age': prefs.getString('profile_age') ?? 'Unknown',
      'blood_type': prefs.getString('profile_bloodType') ?? 'Unknown',
      'allergies': prefs.getString('profile_allergies') ?? 'None',
      'medical_conditions': prefs.getString('profile_medicalConditions') ?? 'None',
      'emergency_contact': prefs.getString('profile_emergencyContact') ?? 'Unknown',
    };
  }

  void _handleSubmitted(String text) async {
    _textController.clear();

    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    // Immediately save user query
    _autoSaveSession();

    try {
      // Compile previous conversation history (excluding the current newly added message)
      final List<Map<String, String>> history = _messages
          .take(_messages.length - 1)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();
          
      final userProfile = await _getUserProfile();

      final response = await ApiService.sendMessage(text, history: history, userProfile: userProfile);
      String rawText = response.response;
      bool triggerSearch = rawText.contains("[URGENT_CLINIC_SEARCH]");
      String cleanText = rawText.replaceAll("[URGENT_CLINIC_SEARCH]", "").trim();

      ChatMessage aiMessage = ChatMessage(text: cleanText, isUser: false);
      if (mounted) {
        setState(() {
          _messages.add(aiMessage);
          _isLoading = false;
        });
        _autoSaveSession();
      
        if (triggerSearch) {
          _findNearbyClinics(aiMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Error communicating with server: $e',
              isUser: false,
            ),
          );
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'analyzing image',
              isUser: true,
              imagePath: image.name,
            ),
          );
          _isLoading = true;
        });
      }

      try {
        final Uint8List rawBytes = await image.readAsBytes();
        
        // Compress the image down to 300px to avoid MedGemma Token Limits 
        // (Just like we did for the camera)
        final img.Image? decodedImage = img.decodeImage(rawBytes);
        Uint8List compressedBytes = rawBytes;

        if (decodedImage != null) {
           final img.Image resizedImage = img.copyResize(
             decodedImage,
             width: decodedImage.width > decodedImage.height ? 300 : null,
             height: decodedImage.height >= decodedImage.width ? 300 : null,
           );
           compressedBytes = img.encodeJpg(resizedImage, quality: 60);
        }

        // We update the message safely in state to hold the real bytes for rendering 
        if (mounted) {
           setState(() {
             _messages.last = ChatMessage(
                text: 'analyzing image',
                isUser: true,
                imagePath: image.name,
                imageBytes: compressedBytes, 
             );
           });
        }

        final userProfile = await _getUserProfile();
        final response = await ApiService.sendImageBytes(compressedBytes, image.name, "Please analyze this skin condition.", userProfile: userProfile);
        String rawText = response.response;
        bool triggerSearch = rawText.contains("[URGENT_CLINIC_SEARCH]");
        String cleanText = rawText.replaceAll("[URGENT_CLINIC_SEARCH]", "").trim();

        ChatMessage aiMessage = ChatMessage(text: cleanText, isUser: false);
        if (mounted) {
          setState(() {
             _messages.add(aiMessage);
             _isLoading = false;
          });
          _autoSaveSession();
          
          if (triggerSearch) {
             _findNearbyClinics(aiMessage);
          }
        }

      } catch (e) {
        print("Error uploading or compressing gallery image: $e");
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: 'Error analyzing uploaded image: $e',
                isUser: false,
              ),
            );
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _getImage() async {
    // We now receive a map of {'bytes': Uint8List, 'name': String} from CameraScreen
    final dynamic imageResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (imageResult != null && imageResult is Map<String, dynamic>) {
      final Uint8List imageBytes = imageResult['bytes'] as Uint8List;
      final String imageName = imageResult['name'] as String;

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'analyzing image',
              isUser: true,
              imagePath: imageName,
              imageBytes: imageBytes, 
            ),
          );
          _isLoading = true;
        });
        _autoSaveSession();
      }

      try {
        final userProfile = await _getUserProfile();
        final response = await ApiService.sendImageBytes(imageBytes, imageName, "Please analyze this skin condition.", userProfile: userProfile);
        String rawText = response.response;
        bool triggerSearch = rawText.contains("[URGENT_CLINIC_SEARCH]");
        String cleanText = rawText.replaceAll("[URGENT_CLINIC_SEARCH]", "").trim();

        ChatMessage aiMessage = ChatMessage(text: cleanText, isUser: false);
        if (mounted) {
          setState(() {
            _messages.add(aiMessage);
            _isLoading = false;
          });
          _autoSaveSession();
        }

        if (triggerSearch) {
          _findNearbyClinics(aiMessage);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(text: 'Error analyzing image: $e', isUser: false),
            );
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _findNearbyClinics(ChatMessage message) async {
    print("UI: Triggering Clinic Search...");
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("UI: Location Service Disabled!");
        if (mounted) {
          setState(() {
            message.clinics = [{'name': 'Location service disabled on your device/browser.', 'distance': ''}];
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print("UI: Initial Permission state: $permission");
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print("UI: Requested Permission state: $permission");
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              message.clinics = [{'name': 'Location permission denied by user.', 'distance': ''}];
            });
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print("UI: Permission Denied Forever!");
        if (mounted) {
          setState(() {
            message.clinics = [{'name': 'Location permission permanently denied.', 'distance': ''}];
          });
        }
        return;
      }

      print("UI: Fetching GPS coordinates...");
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5),
        );
        print("UI: Location obtained: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        print("UI: Geolocator failed: $e. Falling back to IP location...");
        final ipLoc = await ApiService.getIpLocation();
        
        double lat = 3.1390; // Default KL
        double lon = 101.6869;
        
        if (ipLoc != null) {
          lat = ipLoc['latitude']!;
          lon = ipLoc['longitude']!;
          print("UI: IP Location obtained: $lat, $lon");
        } else {
          print("UI: IP fallback failed. Using default KL coordinates.");
        }
        
        position = Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }
      
      print("UI: Querying OpenStreetMap via Backend Proxy...");
      final elements = await ApiService.getNearbyClinics(position.latitude, position.longitude);
      
      List<Map<String, dynamic>> foundClinics = [];
      for (var el in elements) {
          if (el.containsKey('tags') && el['tags'].containsKey('name')) {
            double clLat = el['lat'];
            double clLon = el['lon'];
            double distanceInMeters = Geolocator.distanceBetween(
              position.latitude, position.longitude, clLat, clLon);
            
            foundClinics.add({
              'name': el['tags']['name'],
              'distance': (distanceInMeters / 1000).toStringAsFixed(1) + " km",
              'lat': clLat,
              'lon': clLon,
              'phone': el['tags']['phone'] ?? el['tags']['contact:phone'],
            });
          }
        }
        
        setState(() {
          message.clinics = foundClinics.isNotEmpty 
            ? foundClinics 
            : [{'name': 'No clinics found within 5km', 'distance': ''}];
        });
    } catch (e) {
      print("Error fetching clinics: $e");
      if (mounted) {
        setState(() {
           message.clinics = [{'name': 'Location Error: $e', 'distance': ''}];
        });
      }
    }
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.medical_services),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: message.isUser
                      ? const EdgeInsets.only(left: 40)
                      : const EdgeInsets.only(right: 40, left: 10),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              message.imageBytes!,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else if (message.imagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb 
                                ? Image.network(message.imagePath!, height: 150, fit: BoxFit.cover)
                                : Image.file(File(message.imagePath!), height: 150, fit: BoxFit.cover),
                          ),
                        ),
                      if (message.isUser)
                        Text(
                          message.text,
                          style: const TextStyle(color: Colors.white),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarkdownBody(
                              data: message.text,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(color: Colors.black87),
                                listBullet: const TextStyle(color: Colors.black87),
                                strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                if (_currentlySpeakingText == message.text) {
                                  _stop();
                                } else {
                                  _speak(message.text);
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _currentlySpeakingText == message.text
                                        ? Icons.stop_circle_outlined
                                        : Icons.volume_up_outlined,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _currentlySpeakingText == message.text ? "Stop" : "Listen",
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (message.clinics != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.local_hospital, color: Colors.red, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Nearby Urgent Care:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...message.clinics!.map((clinic) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  clinic['name'] ?? 'Unknown Clinic',
                                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                clinic['distance'] ?? '',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (clinic['lat'] != null && clinic['lon'] != null)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () async {
                                                    final url = Uri.parse('http://maps.google.com/?q=${clinic['lat']},${clinic['lon']}');
                                                    if (await canLaunchUrl(url)) {
                                                      await launchUrl(url);
                                                    }
                                                  },
                                                  icon: const Icon(Icons.directions, size: 16),
                                                  label: const Text('Directions'),
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(50, 30),
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    alignment: Alignment.centerLeft,
                                                  ),
                                                ),
                                                if (clinic['phone'] != null) ...[
                                                  const SizedBox(width: 16),
                                                  TextButton.icon(
                                                    onPressed: () async {
                                                      final url = Uri.parse('tel:${clinic['phone']}');
                                                      if (await canLaunchUrl(url)) {
                                                        await launchUrl(url);
                                                      }
                                                    },
                                                    icon: const Icon(Icons.phone, size: 16),
                                                    label: const Text('Call'),
                                                    style: TextButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: const Size(50, 30),
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          Divider(color: Colors.red.shade100),
                                        ],
                                      ),
                                    )).toList(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 10),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).primaryColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _pickImageFromGallery,
              tooltip: 'Upload from Gallery',
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _getImage,
              tooltip: 'Take a Picture',
            ),
            IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              color: _isListening ? Colors.red : Theme.of(context).primaryColor,
              onPressed: _listen,
              tooltip: 'Listen',
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: "Describe a symptom...",
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MedApp Assistant'), elevation: 1),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: false,
              itemBuilder: (_, int index) => _buildMessage(_messages[index]),
              itemCount: _messages.length,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          const Divider(height: 1.0),
          
          // --- UPDATED: Added SafeArea and bottom padding ---
          SafeArea(
            child: Container(
              padding: const EdgeInsets.only(bottom: 12.0, top: 8.0), // Adds breathing room
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer(),
            ),
          ),
        ],
      ),
    );
  }
}