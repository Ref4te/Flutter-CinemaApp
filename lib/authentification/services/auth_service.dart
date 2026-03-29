import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Вход по Email и паролю
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print("Ошибка входа: ${e.toString()}");
      return null;
    }
  }

  // Регистрация нового пользователя
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print("Ошибка регистрации: ${e.toString()}");
      return null;
    }
  }

  // Выход из системы
  Future<void> signOut() async {
    await _auth.signOut();
  }
}