import 'package:flutter/material.dart';
import '../homepage/home_page.dart';
// import 'movies_page.dart';
// import 'cinemas_page.dart';
// import 'tickets_page.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;

  // Список страниц для навигации
  late final List<Widget> _pages = <Widget>[
    const HomePage(),
    const Center(child: Text('Movies Page', style: _textStyle)),
    const Center(child: Text('Cinemas Page', style: _textStyle)),
    const Center(child: Text('My Tickets Page', style: _textStyle)),
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
      // Текущая страница отображается здесь
      body: _pages[_currentTabIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_movies_rounded),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.place_rounded),
            label: 'Cinemas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_rounded),
            label: 'Tickets',
          ),
        ],
      ),
    );
  }
}