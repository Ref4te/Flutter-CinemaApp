import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Импорт Firebase Auth
import '../local_library/components.dart';
import '../navigation/main_navigation_screen.dart';
import 'registration_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: const Center(child: LoginForm()),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // Состояние загрузки

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationPage()),
    );
  }

  // --- ЛОГИКА ВХОДА ЧЕРЕЗ FIREBASE ---
  Future<void> _handleSignIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // 1. Локальные проверки
    if (email.isEmpty || password.isEmpty) {
      showMessage(context, "Please fill in all fields");
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@(gmail\.com|mail\.ru)$');
    if (!emailRegex.hasMatch(email)) {
      showMessage(context, "Only gmail.com or mail.ru allowed");
      return;
    }

    if (password.length < 6) {
      showMessage(context, "Password is too short");
      return;
    }

    // 2. Попытка входа в Firebase
    setState(() => _isLoading = true); // Включаем индикатор загрузки

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Успех
      showMessage(context, "Welcome back! ✅", isError: false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // Обработка специфических ошибок Firebase
      String message = "Authentication failed";
      if (e.code == 'user-not-found') {
        message = "No account found with this email";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      } else if (e.code == 'invalid-email') {
        message = "The email address is badly formatted";
      } else if (e.code == 'user-disabled') {
        message = "This user has been disabled";
      }
      showMessage(context, message);
    } catch (e) {
      showMessage(context, "An unexpected error occurred");
    } finally {
      if (mounted) setState(() => _isLoading = false); // Выключаем загрузку
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTextField(
            controller: _emailController,
            label: 'Email',
            formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
          buildTextField(
            controller: _passwordController,
            label: 'Password',
            isPassword: true,
            formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
          const SizedBox(height: 25),

          // Если идет загрузка — показываем индикатор, иначе — кнопку
          _isLoading
              ? const CircularProgressIndicator(color: Color(0xFFE50B14))
              : buildButton(
            text: "Sign In",
            color: const Color(0xFFE50B14),
            onPressed: _handleSignIn,
          ),

          const SizedBox(height: 12),
          buildButton(
            text: "Sign Up",
            color: Colors.black87,
            onPressed: _navigateToSignUp,
          ),
        ],
      ),
    );
  }
}