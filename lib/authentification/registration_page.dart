import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../local_library/components.dart';
import '../navigation/main_navigation_screen.dart';
//import 'login_page.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: const Center(
        child: SingleChildScrollView(
          child: SignUpForm(),
        ),
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // --- ЛОГИКА ВАЛИДАЦИИ ДЛЯ РЕГИСТРАЦИИ ---
  void _handleSignUp() {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // 1. Проверка на пустые поля
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage(context, "All fields are required");
      return;
    }

    // 2. Твоё условие для почты (gmail.com или mail.ru)
    final emailRegex = RegExp(r'^[\w-\.]+@(gmail\.com|mail\.ru)$');
    if (!emailRegex.hasMatch(email)) {
      showMessage(context, "Invalid email format (use gmail.com or mail.ru)");
      return;
    }

    // 3. Минимальная длина пароля
    if (password.length < 6) {
      showMessage(context, "Password must be at least 6 characters");
      return;
    }

    // 4. Совпадение паролей
    if (password != confirmPassword) {
      showMessage(context, "Passwords do not match");
      return;
    }

    showMessage(context,"Sign Up Success! ✅", isError: false);
    print("User: $firstName $lastName, Email: $email");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false, // Это удалит экран логина из памяти, чтобы нельзя было вернуться назад
    );
  }

  void _navigateToSignIn() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTextField(controller: _firstNameController, label: 'First Name'),
          buildTextField(controller: _lastNameController, label: 'Last Name'),
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
          buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            isPassword: true,
            formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
          const SizedBox(height: 10),
          buildButton(
            text: "Sign Up",
            color: const Color(0xFFE50B14),
            onPressed: _handleSignUp, // Теперь вызывает функцию с проверками
          ),
          TextButton(
            onPressed: _navigateToSignIn,
            child: const Text("Already have an account? Sign In",
                style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}