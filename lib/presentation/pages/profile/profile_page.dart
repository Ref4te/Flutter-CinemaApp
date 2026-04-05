import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Импорт Firebase

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // МЕТОД ДЛЯ ВЫХОДА ИЗ СИСТЕМЫ
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      // Возвращаем пользователя на экран логина и очищаем стек навигации
      // Убедись, что в main.dart LoginPage привязан к начальному маршруту
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      print("User signed out successfully");
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. ПОЛУЧАЕМ ДАННЫЕ ТЕКУЩЕГО ПОЛЬЗОВАТЕЛЯ
    final User? user = FirebaseAuth.instance.currentUser;

    // Используем данные из Firebase (displayName мы сохраняли при регистрации)
    final String fullName = user?.displayName ?? 'Guest User';
    final String email = user?.email ?? 'No email provided';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // КАРТОЧКА ПРОФИЛЯ С ДАННЫМИ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1D1D),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFE53935),
                  child: Icon(
                    Icons.person,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // РЕАЛЬНОЕ ИМЯ И ФАМИЛИЯ
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                // РЕАЛЬНАЯ ПОЧТА
                Text(
                  email,
                  style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // СПИСОК ДЕЙСТВИЙ
          const _ProfileActionTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Настройка профиля',
            subtitle: 'Изменить имя, аватар и контактные данные',
          ),
          const _ProfileActionTile(
            icon: Icons.security_outlined,
            title: 'Безопасность',
            subtitle: 'Смена пароля и управление сессиями',
          ),
          const _ProfileActionTile(
            icon: Icons.payment_outlined,
            title: 'Способы оплаты',
            subtitle: 'Банковские карты и кошельки',
          ),
          const _ProfileActionTile(
            icon: Icons.support_agent_outlined,
            title: 'Поддержка',
            subtitle: 'Чат и FAQ',
          ),

          const SizedBox(height: 10),

          // КНОПКА ВЫХОДА
          _ProfileActionTile(
            icon: Icons.logout,
            title: 'Выйти из аккаунта',
            subtitle: 'Завершить текущую сессию',
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: () => _handleLogout(context), // Вызываем метод выхода
          ),
        ],
      ),
    );
  }
}

// УНИВЕРСАЛЬНЫЙ ВИДЖЕТ ДЛЯ ПУНКТОВ МЕНЮ
class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1D1D1D),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: iconColor ?? const Color(0xFFE53935)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: titleColor ?? Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap ?? () {
          // Заглушка для остальных кнопок
          print('Нажато: $title');
        },
      ),
    );
  }
}