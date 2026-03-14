import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      // The new API requires initialization
      await GoogleSignIn.instance.initialize(
        clientId:
            '363057669883-eahq4tkqcveoqvgou3elonjobgtf11jl.apps.googleusercontent.com',
      );

      // Attempt to silently sign in if already authenticated
      final attemptFuture = GoogleSignIn.instance
          .attemptLightweightAuthentication();
      if (attemptFuture != null) {
        final account = await attemptFuture;
        if (account != null && mounted) {
          _navigateToChat();
        }
      }
    } catch (e) {
      debugPrint("Error checking sign-in status: $e");
    }
  }

  void _navigateToChat() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => ChatScreen()));
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await GoogleSignIn.instance.authenticate(scopeHint: ['email', 'profile']);
      if (mounted) {
        _navigateToChat();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign in failed: $error\nEnsure OAuth Client ID is configured.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_services,
                  size: 80,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'MedApp Assistant',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your AI Medical Companion',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 64),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: (GoogleSignInPlatform.instance as web.GoogleSignInPlugin).renderButton(),
                )
              else
                ElevatedButton.icon(
                  onPressed: _handleSignIn,
                  icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                    height: 24,
                  ),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey.shade200,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: _navigateToChat,
                child: const Text('Skip for now (Testing)'),
              ),

              const SizedBox(height: 24),
              const Text(
                'Requires an Internet connection.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
