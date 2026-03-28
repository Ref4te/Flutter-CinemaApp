import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationPage()),
    );
  }

  // --- ВОТ ЗДЕСЬ ТЕПЕРЬ ПРОВЕРКА ПОЧТЫ ---
  void _handleSignIn() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

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

    showMessage(context, "Sign In Success ✅", isError: false);
    print("Sign In Success ✅");
    print("Email: $email");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false, // Это удалит экран логина из памяти, чтобы нельзя было вернуться назад
    );
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
          buildButton(
            text: "Sign In",
            color: const Color(0xFFE50B14),
            onPressed: _handleSignIn, // Теперь вызывает проверку
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