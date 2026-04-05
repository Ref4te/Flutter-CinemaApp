import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Импорт Firebase Auth
import '../../widgets/common/form_widgets.dart';
import '../navigation/main_navigation_screen.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Устанавливаем заголовок в AppBar
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
  // Контроллеры для захвата текста из полей
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false; // Переменная для управления индикатором загрузки

  // --- ЛОГИКА РЕГИСТРАЦИИ В FIREBASE ---
  Future<void> _handleSignUp() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // 1. ПЕРВИЧНАЯ ВАЛИДАЦИЯ
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      showAppMessage(context, "All fields are required");
      return;
    }

    // Проверка формата почты (твое условие: gmail или mail.ru)
    final emailRegex = RegExp(r'^[\w-\.]+@(gmail\.com|mail\.ru)$');
    if (!emailRegex.hasMatch(email)) {
      showAppMessage(context, "Invalid email format (use gmail.com or mail.ru)");
      return;
    }

    if (password.length < 6) {
      showAppMessage(context, "Password must be at least 6 characters");
      return;
    }

    if (password != confirmPassword) {
      showAppMessage(context, "Passwords do not match");
      return;
    }

    // 2. ОТПРАВКА ДАННЫХ В FIREBASE
    setState(() => _isLoading = true); // Включаем "крутилку"

    try {
      // Создаем пользователя в системе аутентификации
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --- СОХРАНЕНИЕ ИМЕНИ И ФАМИЛИИ (ЗАГЛУШКА) ---
      // Мы записываем имя и фамилию в стандартное поле displayName
      await userCredential.user?.updateDisplayName("$firstName $lastName");

      // Принудительно обновляем данные пользователя, чтобы изменения применились сразу
      await userCredential.user?.reload();

      if (!mounted) return;

      showAppMessage(context, "Welcome, $firstName! ✅", isError: false);

      // 3. ПЕРЕХОД НА ГЛАВНЫЙ ЭКРАН
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false, // Очищаем историю навигации
      );
    } on FirebaseAuthException catch (e) {
      // Обработка ошибок от самого Firebase
      String message = "Registration failed";
      if (e.code == 'email-already-in-use') {
        message = "This email is already in use";
      } else if (e.code == 'weak-password') {
        message = "The password is too weak";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address";
      }
      showAppMessage(context, message);
    } catch (e) {
      showAppMessage(context, "An error occurred: ${e.toString()}");
    } finally {
      // Выключаем загрузку в любом случае (успех или ошибка)
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToSignIn() {
    Navigator.pop(context); // Возвращаемся на экран LoginPage
  }

  @override
  void dispose() {
    // Очищаем контроллеры, чтобы не было утечек памяти
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
          AppTextField(controller: _firstNameController, label: 'First Name'),
          AppTextField(controller: _lastNameController, label: 'Last Name'),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))], // Запрет пробелов
          ),
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            isPassword: true,
            formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
          AppTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            isPassword: true,
            formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
          const SizedBox(height: 20),

          // Условный рендеринг кнопки или загрузки
          _isLoading
              ? const CircularProgressIndicator(color: Color(0xFFE50B14))
              : AppPrimaryButton(
            text: "Sign Up",
            color: const Color(0xFFE50B14),
            onPressed: _handleSignUp,
          ),

          const SizedBox(height: 10),
          TextButton(
            onPressed: _navigateToSignIn,
            child: const Text(
              "Already have an account? Sign In",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}