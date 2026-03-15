import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use the first available camera
        _controller = CameraController(_cameras![0], ResolutionPreset.high, enableAudio: false);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "No cameras detected on this device.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Camera Error: $e";
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera Error')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
        )),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context, null),
              ),
            ),
            Positioned(
              bottom: 30,
              child: GestureDetector(
                onTap: () async {
                  if (_controller != null && _controller!.value.isInitialized) {
                    try {
                      final XFile file = await _controller!.takePicture();
                      if (context.mounted) {
                        try {
                           final Uint8List rawBytes = await file.readAsBytes();
                           final img.Image? decodedImage = img.decodeImage(rawBytes);

                           if (decodedImage != null) {
                              // Resize image to max 300px to forcefully avoid MedGemma Token Limits 
                              // (Base64 is passed natively as text, which eats massive tokens)
                              final img.Image resizedImage = img.copyResize(
                                decodedImage,
                                width: decodedImage.width > decodedImage.height ? 300 : null,
                                height: decodedImage.height >= decodedImage.width ? 300 : null,
                              );

                              // Encode back to compact JPEG bytes
                              final Uint8List compressedBytes = img.encodeJpg(resizedImage, quality: 60);
                              Navigator.pop(context, {'bytes': compressedBytes, 'name': file.name});
                           } else {
                              Navigator.pop(context, {'bytes': rawBytes, 'name': file.name}); 
                           }
                        } catch (compressError) {
                            print("Compression failed, returning raw Xfile bytes: $compressError");
                            final Uint8List rawBytes = await file.readAsBytes();
                            Navigator.pop(context, {'bytes': rawBytes, 'name': file.name});
                        }
                      }
                    } catch (e) {
                      print("Error taking photo: $e");
                    }
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
