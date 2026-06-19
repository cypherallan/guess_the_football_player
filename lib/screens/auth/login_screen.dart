import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final UserService _userService = UserService();

  bool loading = false;

  Future<void> signInGoogle() async {
    try {
      print("🚀 LOGIN STARTED");

      setState(() {
        loading = true;
      });

      print("🔐 Calling Google Sign-In...");

      final credential = await _authService.signInWithGoogle();

      print("📦 Credential received: $credential");

      if (credential != null) {
        final user = credential.user;

        print("👤 USER: ${user?.uid}");
        print("📧 EMAIL: ${user?.email}");

        await _userService.createUserIfNotExists(user!);

        print("🔥 USER SAVED TO FIRESTORE");

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        print("❌ Credential is NULL (login cancelled or failed)");
      }
    } catch (e) {
      print("❌ LOGIN ERROR: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }

    print("🏁 LOGIN END");

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_soccer, size: 100),

              const SizedBox(height: 20),

              const Text(
                'Guess The Footballer',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : signInGoogle,
                  icon: const Icon(Icons.login),
                  label: Text(
                    loading ? 'Signing In...' : 'Continue with Google',
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.facebook),
                  label: const Text('Facebook (Coming Soon)'),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.music_note),
                  label: const Text('TikTok (Coming Soon)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
