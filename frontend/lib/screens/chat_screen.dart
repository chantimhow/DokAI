import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  void _handleSubmitted(String text) async {
    _textController.clear();
    
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    try {
      final response = await ApiService.sendMessage(text);
      setState(() {
        _messages.add(ChatMessage(text: response.response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'Error communicating with server: $e', isUser: false));
        _isLoading = false;
      });
    }
  }

  Future<void> _getImage() async {
    // Note: ImageSource.camera is not supported on Linux/Windows desktops.
    // We use gallery so the user can select an image file from their computer instead.
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _messages.add(ChatMessage(text: 'Assessing skin condition...', isUser: true, imagePath: image.path));
        _isLoading = true;
      });

      try {
        final response = await ApiService.sendImage(File(image.path), "Please analyze this skin condition.");
        setState(() {
          _messages.add(ChatMessage(text: response.response, isUser: false));
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _messages.add(ChatMessage(text: 'Error analyzing image: $e', isUser: false));
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!message.isUser)
            CircleAvatar(
              child: Icon(Icons.medical_services),
              backgroundColor: Colors.blue.shade100,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(12),
                  margin: message.isUser 
                      ? EdgeInsets.only(left: 40) 
                      : EdgeInsets.only(right: 40, left: 10),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(message.imagePath!), height: 150, fit: BoxFit.cover),
                          ),
                        ),
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser)
            Container(
              margin: EdgeInsets.only(left: 10),
              child: CircleAvatar(
                child: Icon(Icons.person),
                backgroundColor: Colors.grey.shade300,
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
              icon: Icon(Icons.camera_alt),
              onPressed: _getImage,
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(
                    hintText: "Describe a symptom..."),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send),
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
      appBar: AppBar(
        title: Text('MedApp Assistant'),
        elevation: 1,
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: false,
              itemBuilder: (_, int index) => _buildMessage(_messages[index]),
              itemCount: _messages.length,
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }
}
