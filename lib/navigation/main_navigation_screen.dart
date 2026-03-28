import 'package:flutter/material.dart';

import '../homepage/home_page.dart';
import '../settings/settings_page.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;

  late final List<Widget> _pages = <Widget>[
    const HomePage(),
    const Center(child: Text('Избранное', style: _textStyle)),
    const Center(child: Text('Билеты', style: _textStyle)),
    const SettingsPage(),
  ];

  static const TextStyle _textStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  void _onTabTapped(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF181818),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Домой'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Избранные'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Билеты'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }
}
